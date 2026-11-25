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

单独安装 Mac 环境迁移或 Tailscale 远程访问 Skill（用户级 Codex）：

```sh
npx skills@latest add original4422/skills --skill mac-environment-migration -g -a codex
npx skills@latest add original4422/skills --skill tailscale-remote-access -g -a codex
```

一次安装这两个 Skill：

```sh
npx skills@latest add original4422/skills \
  --skill mac-environment-migration tailscale-remote-access -g -a codex
```

将 `-a codex` 换成 `-a claude-code` 可安装到 Claude Code；省略 `-g` 则安装到当前项目。
安装后可使用 `$mac-environment-migration` 或 `$tailscale-remote-access` 调用。
Skill 的安装不会自动执行设备迁移、安装 Tailscale 或修改远端设置。

## Available Skills

### Development

#### [`git-commit-message`](skills/git-commit-message/SKILL.md)

Drafts an English Conventional Commit message from staged changes only. It
groups the body by meaningful repository areas and does not create a commit
unless explicitly requested.

### System & Environment

#### [`mac-environment-migration`](skills/mac-environment-migration/SKILL.md)

导出轻量的 Mac 迁移包，也可直接读取随 Skill 安装的内置参考。
根据目标 Mac 的实际情况，为系统设置、软件安装和开发环境制定差异计划。
用户批准后执行，支持分阶段验收，结束时评估备份清理。应用状态按用户点名的应用另行恢复。

使用 `$mac-environment-migration`，或明确指定使用 `mac-environment-migration`。

#### [`tailscale-remote-access`](skills/tailscale-remote-access/SKILL.md)

配置 macOS 被连接机的 Tailscale、远程登录和供电场景下的睡眠设置，
在连接机部署 SSH 公钥并设置快捷别名，验证免密登录与连接稳定性。
附带只读连通性诊断脚本，并提供按需使用的系统级 `tailscaled`、
Tailscale SSH 和屏幕共享配置说明。正文为中文。

默认采用官方独立应用版 Tailscale + macOS 远程登录 + SSH 公钥认证。
文档区分系统睡眠与息屏、状态显示与实际连通性，以及远端账户密码与私钥口令。

### Image Editing

#### [`image-text-edit`](skills/image-text-edit/SKILL.md)

在纯色或容易复现的背景上局部替换图中文字和数字。先复现旧文字以校准字体与排版，
复用原有字形，再渲染新内容并贴回原图，验证修改区域外的像素完全一致。
附带字体渲染、参数搜索和局部合成校验工具，正文为中文。

使用 `$image-text-edit`。图像处理工具依赖 Python 3 和 Pillow；
Apple 原生字体渲染工具另需 macOS 和 Swift。

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

Keep skill directories flat. Group the catalog above by purpose rather than
adding category directories under `skills/`. Add a category when it has a
skill to list; changing a catalog category does not change installation paths.

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
