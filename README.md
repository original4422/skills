# PZG Skills

Focused, reusable skills for coding agents.

The skills in this repository are designed to have clear activation conditions,
bounded workflows, and predictable outputs. Each skill can be installed and
adapted independently.

## Skill Standard

Skills in this repository follow the
[Agent Skills Specification](https://agentskills.io/specification), the open
format originally developed by Anthropic for portable agent capabilities.

Each skill is a directory containing a required `SKILL.md` with YAML
frontmatter and Markdown instructions. The required `name` and `description`
fields identify the skill and tell an agent when to activate it. A skill may
also include `scripts/`, `references/`, and `assets/` for resources loaded or
executed on demand.

The specification defines the contents of an individual skill. This repository
uses `skills/<skill-name>/` as its collection layout and skills.sh as its
installation mechanism.

## Installation

Install skills with [skills.sh](https://skills.sh/):

```sh
npx skills@latest add original4422/skills
```

Select the skills and supported agents you want to install when prompted.

## Available Skills

### `git-commit-message`

Drafts an English Conventional Commit message from staged changes only. It
groups the body by meaningful repository areas and does not create a commit
unless explicitly requested.

## Repository Structure

```text
.
├── skills/      # Installable agent skills
└── research/    # Design research and supporting evidence
```

Every installable skill lives in `skills/<skill-name>/` and has a `SKILL.md`
entry point. Runtime references, scripts, or assets should stay inside that
skill's directory. Repository-level research stays outside the installable
skill so it does not add unnecessary agent context.

## Design Principles

- Keep each skill focused on one reusable capability.
- State when the skill should and should not activate.
- Define observable inputs, workflow boundaries, and outputs.
- Prefer deterministic checks and repository evidence over assumptions.
- Require explicit user approval for destructive or external side effects.
- Keep background research separate from runtime instructions.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the repository conventions and
review checklist.

## License

Licensed under the [MIT License](LICENSE).
