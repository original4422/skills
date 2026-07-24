# Contributing

Contributions should keep each skill focused, auditable, and easy to adapt.

## Standard

The skill authoring rules in this repository derive from the
[Agent Skills Specification](https://agentskills.io/specification). Every
installable skill must conform to that specification. The repository
conventions below extend it for maintaining a collection of skills; they do
not replace or override it.

## Adding a Skill

1. Create `skills/<skill-name>/SKILL.md`.
2. Name the directory with 1–64 lowercase ASCII letters, numbers, or hyphens.
   The name must not start or end with a hyphen or contain consecutive hyphens.
3. Add YAML frontmatter followed by Markdown instructions:
   - `name`: required; exactly matches the directory name and follows the same
     naming constraints.
   - `description`: required; 1–1024 characters describing both the capability
     and when an agent should use it.
   - `license`: optional; a license name or reference to a bundled license.
   - `compatibility`: optional; 1–500 characters describing environment
     requirements.
   - `metadata`: optional; a mapping of string keys to string values.
   - `allowed-tools`: optional and experimental; a space-separated list of
     pre-approved tools whose support depends on the agent implementation.
4. Write direct, executable instructions with explicit inputs and outputs.
5. Add the skill to the catalog in `README.md`.

A skill may also contain:

```text
skills/<skill-name>/
├── SKILL.md
├── references/  # Runtime documentation loaded on demand
├── scripts/     # Deterministic helpers
└── assets/      # Templates or other output resources
```

Only add these directories when the skill uses them.

Reference supporting files with paths relative to the skill root. Keep
references focused and avoid deep chains between reference files. Keep the
main `SKILL.md` below the specification's recommended 500-line limit by moving
optional detail into `references/`.

Scripts must be self-contained or clearly document their dependencies. They
must report actionable errors and handle expected edge cases. Supported script
languages and tools depend on the target agent environment.

## Research

Place design investigations and source analysis under `research/`. Prefer a
`research/<skill-name>/` subdirectory when a skill has multiple research
artifacts. Research explains why a skill was designed a certain way; it must
not be required merely to understand the runtime workflow.

Use primary sources where possible. Clearly distinguish sourced facts from
repository-specific design decisions.

## Quality Checklist

Before submitting a change, verify that:

- `skills-ref validate ./skills/<skill-name>` succeeds.
- The frontmatter is valid YAML.
- The name and description satisfy the specification constraints.
- Instructions define important exclusions and side-effect boundaries.
- Examples agree with the written rules.
- Referenced files and links exist.
- No credentials, tokens, personal data, or generated local files are included.
- `README.md` reflects added, renamed, or removed skills.

Exercise changed skills against representative success, edge, and failure
cases. Include deterministic validation scripts when prose review alone cannot
reliably verify behavior.

## Change Scope

Keep changes small and attributable to one purpose. Do not reformat or rewrite
unrelated skills. Use Conventional Commit messages and follow the repository's
recent history for scope and wording.

Do not add package managers, release tooling, or agent-specific distribution
metadata unless a concrete workflow requires them.
