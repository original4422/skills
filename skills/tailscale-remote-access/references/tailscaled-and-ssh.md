# 系统服务与 Tailscale SSH（按需）

读取时重新核对官方支持矩阵和目标 macOS 版本；本参考核对日期 2026-11-16。

三个独立选择：

- `sleep 0` 解决接电闲置时系统自动睡眠。
- 系统级 `tailscaled` 解决操作系统启动后的后台进程生命周期。
- Tailscale SSH 用 tailnet 身份/策略替代普通 SSH 公钥认证。

前两者不会因开启 Tailscale SSH 自动实现；系统服务也可继续使用 macOS 普通 SSH。FileVault 启动解锁独立处理，不能承诺服务配置后每次断电重启都无人干预恢复，也不要自动关闭 FileVault/启用自动登录。

## 迁移开源发行版

仅在用户需要并授权迁移时进行。先记录旧发行形式、地址、名称、设置和独立入口。Air 等连接机无需迁移。保持校园网/LAN 管理会话或现场操作：切换客户端和接管端口会中断已有 Tailscale SSH 会话。

按当前官方切换指导停止并移除旧 GUI 和扩展、完成需要的重启；若原包由 Homebrew Cask 管理，可用 `brew uninstall --cask tailscale-app`。不要在唯一 Tailscale 连接上直接卸载或重启。

在目标 Mac 上：

```bash
brew install --formula tailscale
sudo brew services start tailscale
sudo "$(brew --prefix tailscale)/bin/tailscale" up
sudo "$(brew --prefix tailscale)/bin/tailscale" status
sudo "$(brew --prefix tailscale)/bin/tailscale" ip -4
```

使用公式的完整 CLI 路径，避免旧 GUI 包装器/PATH 冲突；用系统服务方式在 root launchd 域启动。完成同一账号认证，重新确认地址/名称，按需更新连接机别名。不要承诺复用旧 IP。开源 daemon 不提供 GUI，也不会像 GUI 版那样自动配置系统 DNS；需要目标主动解析 MagicDNS 时，另核对 DNS 集成方案。

## 可选 Tailscale SSH

当前 macOS 服务端需要开源 tailscaled。后台网络访问规则必须允许来源访问目标 TCP 22，另有 `ssh` 规则允许指定本地用户。保持现有策略，按实际身份合并；不整份覆盖或扩大到全网通行。

对于同一个人拥有的未打标签设备，可以参考以下 SSH 规则；把 `remote-user` 替换为目标实际账户：

```json
"ssh": [
  {
    "action": "accept",
    "src": ["autogroup:member"],
    "dst": ["autogroup:self"],
    "users": ["remote-user"]
  }
]
```

`autogroup:self` 表示来源用户自己拥有的设备，不适用于已转为 tag 身份的目标。已有匹配 `check` 规则可能要求浏览器验证；根据用户所需认证方式处理重叠规则。

被连接机：

```bash
sudo "$(brew --prefix tailscale)/bin/tailscale" set --ssh
```

只接管来自 tailnet、发往 Tailscale 地址 TCP 22 的流量。系统 sshd、authorized_keys 和校园网入口仍可独立工作。新 host key 引起的 known_hosts 警告按核实后的身份处理，不能关闭主机校验。

连接机验证 Tailscale 身份认证：

```bash
ssh -o PubkeyAuthentication=no -o PasswordAuthentication=no -o KbdInteractiveAuthentication=no remote-user@target-address 'whoami'
```

这与默认流程的“仅公钥”验收不同。需要回到普通 SSH 时：

```bash
sudo "$(brew --prefix tailscale)/bin/tailscale" set --ssh=false
```

关闭功能不等于回迁发行版；普通 SSH 仍需已有 sshd 和可用认证。迁移完成后验证注销/重启能力时，保留独立入口并明确哪些场景已实测。

## 来源

- [macOS 支持矩阵与切换说明](https://tailscale.com/docs/concepts/macos-variants)
- [macOS tailscaled 和 Homebrew 系统服务](https://github.com/tailscale/tailscale/wiki/Tailscaled-on-macOS)
- [Tailscale SSH、网络与 SSH 两层授权](https://tailscale.com/docs/features/tailscale-ssh)
