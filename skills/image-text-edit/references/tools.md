# 工具接口

`scripts/image_patch.py` 依赖 Python 3 和 Pillow。`scripts/render_text.swift` 依赖 macOS 的 Swift、AppKit、CoreText；无需下载或打包系统字体。工具路径相对 skill 目录解析；用户数据与中间产物放在任务的临时工作目录，不写入 skill。

## 裁剪旧文字与目标像素

```sh
python3 <skill-dir>/scripts/image_patch.py crop \
  --source /absolute/source.png --box 425 600 1000 670 \
  --out /absolute/work/title-reference.png \
  --rgba /absolute/work/title-reference.rgba
```

坐标仅是来源案例示例。`--rgba` 写出按行排列、8 bit、非预乘、RGBA 顺序的原始像素，供不透明背景的 CoreText 校准使用。目标文件本身不包含尺寸头，尺寸由渲染任务指定。

## 原生渲染与旧文字搜索

输入 JSON 的 `jobs` 数组支持多个任务。画布宽高、`x` 与从顶部量起的 `baseline` 均为图片像素；`size_pt` 与 `kern_pt` 为逻辑排版单位；`scale` 是像素/逻辑单位比例。颜色为 0–255 的 RGB 或 RGBA。`font_name` 不指定时使用系统字体；指定时必须是可用字体，字重由指定的字体面决定。

```json
{
  "jobs": [{
    "name": "title",
    "width": 575,
    "height": 70,
    "scale": 2,
    "background": [255, 255, 255, 255],
    "runs": [{
      "text": "ChatGPT Plus",
      "x": 9,
      "baseline": 48,
      "size_pt": 17,
      "weight": 0.3,
      "color": [0, 0, 0, 255]
    }],
    "fit": {
      "reference_rgba": "title-reference.rgba",
      "size_pt": [16.5, 17, 17.5],
      "weight": [0.23, 0.3, 0.4],
      "x": [8.5, 9, 9.5],
      "baseline": [47.5, 48, 48.5],
      "kern_pt": [null, 0]
    },
    "replacement": "ChatGPT Pro 200"
  }]
}
```

```sh
swift <skill-dir>/scripts/render_text.swift /absolute/work/jobs.json /absolute/work/rendered
```

频繁调用时可先用 `swiftc -O` 编译到任务临时目录再运行。脚本输出匹配旧字的 `title.png`、同参数的 `title-replacement.png` 和 `render-report.json`。报告包含候选参数、实际 glyph run 字体、字宽、缺字数、字形边界和旧字校准误差。

- `fit` 可省略，用于按确定参数渲染；`replacement` 也可省略。
- `fit` 仅支持一个有代表性的旧文字 run、尺寸相同且完全不透明的 RGBA 目标。多 run 可分别校准；随后通过多个带明确位置的 run 组合排版。
- 自动搜索仅遍历明确给定的候选，不保证已找到全局最优。报告中的 `exact: false` 需要继续调查，或按 skill 规则展示差异并等待用户接受近似。
- `kern_pt: null` 或省略表示保留系统自然 tracking，不等于 0。
- 常见系统字重：regular=0、medium=0.23、semibold=0.3、bold=0.4。这些是 Apple API 值，不是所有字体通用的字重编号。
- 命名字体应指定准确字体面；此时不要搜索 `weight`，因为系统字体的 weight 参数不改变命名字体面。
- 中英文混排的实际字体和自动间隔仍需检查。新字符发生回退、缺字或边界越界时不能仅凭旧字匹配就继续交付。
- `glyph_bounds_inside_canvas` 只是几何检查；还需视觉检查边缘的抗锯齿是否被裁切。
- 渲染目录属于可重建的中间产物。同名任务输出会覆盖；不要把原图放入该目录或使用原图文件名。

## 像素比较

```sh
python3 <skill-dir>/scripts/image_patch.py compare \
  --reference /absolute/work/title-reference.png \
  --candidate /absolute/work/rendered/title.png \
  --diff /absolute/work/title-difference.png
```

比较的是解码后的 RGBA 值，不要求压缩文件字节相同。可传 `--box left top right bottom` 比较同一子区域，或用 `--mask /absolute/foreground-mask.png` 选择前景。掩码必须与完整输入图同尺寸、alpha 不透明、灰度只含 0 与 255。输出不同像素数、最大通道差、平均绝对差和差异边界；退出码 0 表示比较成功，不表示像素完全匹配，以 `exact` 字段为准。

## 局部合成与保存后验证

先准备与目标矩形严格同尺寸的最终局部图，内容包含已清理的旧文字背景与新文字。必要时复用原图裁剪出的中文、时间等，并检查新字宽引起的后续位置变化。不要把原图缩放成与生成片段一致。

合成 manifest：

```json
{
  "source": "/absolute/source.png",
  "output": "/absolute/project/修改/source-edited.png",
  "patches": [
    {
      "box": [432, 617, 730, 655],
      "image": "/absolute/work/title-final-patch.png"
    }
  ]
}
```

```sh
python3 <skill-dir>/scripts/image_patch.py apply --manifest /absolute/work/patches.json
```

所有相对路径按 manifest 所在目录解析。每个 patch 可指定同尺寸二值 `mask`；仅白色位置被替换。像素替换直接复制 RGBA，patch 的 alpha 不会被用作混合权重，因此透明文字层不能直接作为白底最终 patch；先把它与目标背景合成为完整局部图。

脚本默认保持原图 alpha。仅在用户确实要求透明度变化时，manifest 才设置 `allow_alpha_change: true`。不传掩码则整个矩形均为允许修改的范围，应主动选择最小必要矩形。

输出强制为 PNG，原图不覆盖，已有同名文件自动采用 `-2` 等后缀。脚本保存后重新打开文件，检查尺寸、合成像素、允许区域外的不同像素数，写出成品同名 `.verification.json`。原图有 ICC profile 时沿用该 profile，不执行颜色转换。文件压缩方式、元数据或 RGB/RGBA 存储模式可能与原图不同；“像素一致”指解码后的 RGBA 值相同。

合成验证不证明文字拼写、字体相似度或掩码范围合理。代理仍须核对具体修改内容并查看最终图。报告侧车文件可保留供追溯，普通交付只需成品及简短验证说明。
