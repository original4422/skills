# Repository Instructions

This repository contains reusable skills for coding agents.

## Source of Truth

- Installable content lives under `skills/<skill-name>/`.
- Every skill has a `SKILL.md` entry point.
- Repository-level design evidence lives under `research/`.
- `README.md` is the public catalog.
- `CONTRIBUTING.md` defines authoring and review conventions.

Do not duplicate repository instructions in agent-specific files unless a
supported distribution format requires an adapter.

## Skill Standard

All installable skills must conform to the
[Agent Skills Specification](https://agentskills.io/specification).
Repository conventions may extend the specification but must not conflict with
it.

## Editing Skills

- Read the complete target skill and its related research before editing it.
- Keep each skill focused on one capability.
- Preserve clear activation signals in the frontmatter description.
- Express workflows as direct, ordered instructions.
- Define exclusions, failure behavior, and side-effect boundaries explicitly.
- Prefer repository evidence and deterministic checks over model assumptions.
- Keep runtime instructions concise; move optional detail to `references/`.
- Do not change unrelated skills or research.

The `name` field must exactly match the skill directory name. Skill directories
use lowercase kebab-case names.

## Documentation

Write repository documentation and skill instructions in English. Update the
README catalog whenever a skill is added, renamed, or removed. Keep factual
claims traceable to primary sources or mark them as local design decisions.

## Verification

For each changed skill:

1. Validate its YAML frontmatter.
2. Check that every referenced path and link exists.
3. Compare examples with the normative rules.
4. Exercise representative success, edge, and failure cases.
5. Confirm that no secret or local generated artifact is included.

Do not commit, publish, or perform other external side effects unless the user
explicitly requests them.
