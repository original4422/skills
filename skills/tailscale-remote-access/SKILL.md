---
name: tailscale-remote-access
description: 配置 macOS 设备通过 Tailscale 稳定远程访问，启用远程登录、部署 SSH 公钥、设置 SSH 别名并排查掉线或认证失败。适用于新 Mac 接入、SSH 免密配置及闲置后断连；系统级 tailscaled 和 Tailscale SSH 仅在用户需要时配置。
metadata:
  version: "1.0.0"
---

# Tailscale 远程访问

目标：被连接 Mac 在约定的供电和登录状态下持续可达，连接机可以用 `ssh <alias>` 通过公钥登录。默认使用 Standalone Tailscale + macOS“远程登录”，沿用已有可用部署。

## 先明确两端

区分连接机与被连接机；每组命令说明在哪一端执行。确认被连接机的本地账户短名称、设备类型、供电/合盖场景，以及已有 SSH 或现场入口。从系统和配置读取可获信息，只询问无法推断且影响操作的信息。

名称、IP、用户名分别核实。Tailscale 设备名不是 macOS 用户名，SSH 别名也不一定是 DNS 名。用 `ssh -G <alias>` 检查有效 HostName/User/Port/IdentityFile，再通过系统解析和 `tailscale status` 核实目标。不写死历史设备名、账号、IP 或密钥路径。

## 工作流程

1. **安装与接网**：按 [macOS 配置](references/macos-setup.md) 识别现有 Tailscale 发行形式；新装默认官网 Standalone 或 `brew install --cask tailscale-app`。两端加入预期 tailnet，完成必要的系统扩展批准与用户登录，核对地址。
2. **开启 SSH**：在被连接机启用“远程登录”，允许目标本地账户；先验证 TCP 22 和一次实际登录。
3. **保持在线**：读取 `pmset -g custom`。常接电台式机的闲置睡眠可设为 `sudo pmset -c sleep 0`，保留息屏和锁屏。笔记本区分供电、合盖和携带场景；不把接电设置描述成合盖持续在线。记录原值与恢复命令。配置 Tailscale 登录时启动，单独说明注销/重启后是否可用。
4. **公钥认证**：在连接机选择已有公钥；缺失时生成 Ed25519 密钥，口令选择遵循用户偏好。先确认目标身份，再用 `ssh-copy-id -i <public-key> <user>@<address>` 安装，重复操作不强制追加。只传 `.pub`。没有该工具时按参考中的去重方式安装。
5. **快捷别名**：读取、合并 `~/.ssh/config`，处理已有 Host/Include/Host * 的优先级，用 `ssh -G` 核验最终结果。具体改动前保存原配置；不整文件覆盖。HostName 可按用户偏好用 IP 或 MagicDNS。
6. **验收**：使用指定密钥、仅允许公钥的 BatchMode 登录并运行 `whoami`。目标账户正确且退出码为 0 才报告免密成功；再退出测试会话并在约定的闲置/锁屏场景复测。未执行的闲置或重启验证列为未验证，不能声称已完成。

用户只要命令时提供可直接替换参数的最短步骤；用户授权配置时完成可自动执行的部分。遇到必须由用户输入的登录密码、sudo 或系统授权，让用户在其终端/系统 UI 完成，不索要密码文本。

## 诊断

先运行：

```bash
bash <skill-dir>/scripts/check-connection.sh <ssh-alias-or-user@host>
```

仅在需要验证免密登录时：

```bash
bash <skill-dir>/scripts/check-connection.sh <target> --verify-key --identity <private-key-path>
```

默认脚本检查有效 SSH 配置、系统解析、Tailscale 状态、隧道探测和 TCP 端口，不登录远端。`--verify-key` 会尝试一次公钥登录并执行 `whoami`。脚本面向 macOS 连接机，使用系统 bash、ssh、nc、dscacheutil 和已安装的 Tailscale CLI。

按 [排障表](references/troubleshooting.md) 区分 DNS、隧道、端口、认证。`Online`、`active`、`direct` 与累计 tx/rx 不能单独证明实时可达；ping 失败也不能否定已成功的 SSH。错误直接报告，不用关闭防火墙或清空 known_hosts 作为通用修复。

## 可选进阶

用户明确需要注销后/系统启动时提供连接，或 Tailscale 身份认证时，再读 [系统服务与 Tailscale SSH](references/tailscaled-and-ssh.md)。系统级 tailscaled、Tailscale SSH、禁用自动睡眠是三个独立配置。屏幕共享只有用户需要 GUI 时才配置，步骤见 macOS 参考。

## 交付

汇报实际设备名/IP、目标账户、别名、公钥指纹和实际测试结果；说明执行了哪些睡眠与启动设置及如何恢复。只有脚本/文档创建不等于已配置设备。安装本 Skill 不等于授权修改任意远端设备或创建持续监控。
