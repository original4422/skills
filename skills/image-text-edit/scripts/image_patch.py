#!/usr/bin/env python3
"""Lossless crop, comparison, and bounded pixel replacement. Requires Pillow."""
import argparse
import json
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageStat


def read_image(path):
    with Image.open(path) as image:
        image.load()
        return image.convert('RGBA'), dict(image.info), image.mode


def box_in_image(values, size):
    if len(values) != 4 or any(type(v) is not int for v in values):
        raise ValueError('A box must contain four integers')
    left, top, right, bottom = values
    if not (0 <= left < right <= size[0] and 0 <= top < bottom <= size[1]):
        raise ValueError(f'Box {values} is outside image {size}')
    return left, top, right, bottom


def pixel_error(a, b):
    if a.size != b.size:
        raise ValueError(f'Image dimensions differ: {a.size} != {b.size}')
    diff = ImageChops.difference(a.convert('RGBA'), b.convert('RGBA'))
    channels = diff.split()
    maximum = channels[0]
    for channel in channels[1:]:
        maximum = ImageChops.lighter(maximum, channel)
    return diff, maximum


def read_mask(path, size):
    image, _, _ = read_image(path)
    mask = image.convert('L')
    if image.size != size or image.getchannel('A').getextrema() != (255, 255):
        raise ValueError('Mask must match image dimensions and have opaque alpha')
    if any(mask.histogram()[1:255]):
        raise ValueError('Mask must contain only 0 and 255')
    return mask


def metrics(a, b, mask=None):
    diff, maximum = pixel_error(a, b)
    if mask is not None:
        if mask.size != a.size:
            raise ValueError('Comparison mask dimensions differ')
        if any(mask.histogram()[1:255]):
            raise ValueError('Comparison mask must contain only 0 and 255')
    count = a.width * a.height if mask is None else mask.histogram()[255]
    if not count:
        raise ValueError('Comparison mask selects no pixels')
    selected = maximum if mask is None else ImageChops.multiply(maximum, mask)
    stats = ImageStat.Stat(diff, mask)
    different = count - selected.histogram()[0] if mask is None else sum(selected.histogram()[1:])
    return {
        'size': list(a.size), 'compared_pixels': count,
        'different_pixels': different, 'exact': different == 0,
        'maximum_channel_error': selected.getextrema()[1],
        'mean_absolute_error_rgba': sum(stats.mean) / 4,
        'difference_bbox': selected.getbbox(),
    }


def save_png(image, path, info=None, original_mode=None):
    if path.suffix.lower() != '.png':
        raise ValueError('Output must use .png')
    path.parent.mkdir(parents=True, exist_ok=True)
    if original_mode == 'RGB' and image.getchannel('A').getextrema() == (255, 255):
        image = image.convert('RGB')
    # Keep the source profile; do not transform pixel colors.
    options = {}
    if info and info.get('icc_profile'):
        options['icc_profile'] = info['icc_profile']
    image.save(path, format='PNG', **options)


def unique_destination(path):
    if not path.exists():
        return path
    index = 2
    while path.with_name(f'{path.stem}-{index}{path.suffix}').exists():
        index += 1
    return path.with_name(f'{path.stem}-{index}{path.suffix}')


def crop(args):
    source, info, mode = read_image(args.source)
    output = args.out.resolve()
    if output == args.source.resolve():
        raise ValueError('Crop output cannot overwrite the original')
    box = box_in_image(args.box, source.size)
    result = source.crop(box)
    save_png(result, output, info, mode)
    if args.rgba:
        raw = args.rgba.resolve()
        if raw == args.source.resolve() or raw == output:
            raise ValueError('RGBA output must be a separate file')
        raw.parent.mkdir(parents=True, exist_ok=True)
        raw.write_bytes(result.tobytes())
    return {'output': str(output), 'box': box, 'size': list(result.size)}


def compare(args):
    a, _, _ = read_image(args.reference)
    b, _, _ = read_image(args.candidate)
    if a.size != b.size:
        raise ValueError(f'Image dimensions differ: {a.size} != {b.size}')
    mask = None
    if args.mask:
        mask = read_mask(args.mask, a.size)
    if args.box:
        box = box_in_image(args.box, a.size)
        a, b = a.crop(box), b.crop(box)
        if mask is not None:
            mask = mask.crop(box)
    report = metrics(a, b, mask)
    if args.diff:
        if args.diff.resolve() in {args.reference.resolve(), args.candidate.resolve()}:
            raise ValueError('Difference output cannot overwrite comparison inputs')
        diff, _ = pixel_error(a, b)
        # Display RGB differences with opaque alpha, including alpha-only errors.
        if diff.getchannel('A').getextrema()[1]:
            _, maximum = pixel_error(a, b)
            diff = Image.merge('RGB', (maximum, maximum, maximum)).convert('RGBA')
        else:
            diff.putalpha(255)
        save_png(diff, args.diff.resolve())
    return report


def apply(args):
    manifest_path = args.manifest.resolve()
    spec = json.loads(manifest_path.read_text())
    base = manifest_path.parent

    def resolve(value):
        return (base / value).resolve()

    original_path = resolve(spec['source'])
    requested_output = resolve(spec['output'])
    if requested_output == original_path:
        raise ValueError('Output cannot overwrite the original')
    if requested_output.suffix.lower() != '.png':
        raise ValueError('Output must use .png')
    original, info, mode = read_image(original_path)
    edited = original.copy()
    allowed = Image.new('L', original.size, 0)
    region_log = []
    patches = spec.get('patches', [])
    if not patches:
        raise ValueError('Manifest must contain at least one patch')
    for patch in patches:
        box = box_in_image(patch['box'], original.size)
        replacement, _, _ = read_image(resolve(patch['image']))
        expected = (box[2] - box[0], box[3] - box[1])
        if replacement.size != expected:
            raise ValueError(f'Patch dimensions {replacement.size} != box dimensions {expected}; resizing is forbidden')
        if patch.get('mask'):
            mask = read_mask(resolve(patch['mask']), expected)
        else:
            mask = Image.new('L', expected, 255)
        # A binary selection replaces RGBA exactly; patch alpha is not a blending mask.
        edited.paste(replacement, box[:2], mask)
        current = allowed.crop(box)
        allowed.paste(ImageChops.lighter(current, mask), box[:2])
        region_log.append({'box': box, 'selected_pixels': mask.histogram()[255]})

    if not spec.get('allow_alpha_change', False) and ImageChops.difference(original.getchannel('A'), edited.getchannel('A')).getbbox():
        raise ValueError('Patch changes alpha; preserve original alpha unless explicitly requested and allow_alpha_change is true')
    output = unique_destination(requested_output)
    save_png(edited, output, info, mode)
    reopened, _, _ = read_image(output)
    if reopened.size != original.size:
        raise RuntimeError('Saved image dimensions changed')
    if metrics(edited, reopened)['different_pixels']:
        raise RuntimeError('Saved PNG pixels differ from composition')
    _, changed = pixel_error(original, reopened)
    outside = ImageChops.multiply(changed, ImageChops.invert(allowed))
    outside_count = sum(outside.histogram()[1:])
    if outside_count:
        raise RuntimeError(f'{outside_count} pixels changed outside the permitted mask')
    report = {
        'output': str(output), 'size': list(reopened.size), 'patches': region_log,
        'different_pixels_total': sum(changed.histogram()[1:]),
        'different_pixels_outside_allowed_regions': outside_count,
        'saved_png_matches_composition': True,
        'source_mode': mode,
        'icc_profile_preserved': bool(info.get('icc_profile')),
    }
    report_path = output.with_suffix('.verification.json')
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2))
    report['verification_report'] = str(report_path)
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest='command', required=True)
    command = commands.add_parser('crop')
    command.add_argument('--source', type=Path, required=True)
    command.add_argument('--box', type=int, nargs=4, required=True)
    command.add_argument('--out', type=Path, required=True)
    command.add_argument('--rgba', type=Path)
    command.set_defaults(handler=crop)
    command = commands.add_parser('compare')
    command.add_argument('--reference', type=Path, required=True)
    command.add_argument('--candidate', type=Path, required=True)
    command.add_argument('--box', type=int, nargs=4)
    command.add_argument('--mask', type=Path)
    command.add_argument('--diff', type=Path)
    command.set_defaults(handler=compare)
    command = commands.add_parser('apply')
    command.add_argument('--manifest', type=Path, required=True)
    command.set_defaults(handler=apply)
    args = parser.parse_args()
    try:
        print(json.dumps(args.handler(args), ensure_ascii=False, indent=2))
    except (ValueError, OSError, KeyError, TypeError) as error:
        parser.exit(2, f'error: {error}\n')


if __name__ == '__main__':
    main()
