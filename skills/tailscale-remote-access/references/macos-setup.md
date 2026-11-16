# macOS 两端配置

以下变量都是运行时填写的占位值，禁止把示例当作真实设备信息。先用 `hostname`、`whoami`、`sw_vers`、`pmset -g custom` 识别被连接机。已有会话中，迁移客户端/重启前保留一条不依赖 Tailscale 的入口。

## 1. 发行形式与联网（两端）

- `brew list --cask --versions tailscale-app`、应用 Info.plist、`command -v tailscale` 用于确认来源；命令存在不代表安装了开源发行版，可能只是 GUI CLI 包装器。
- Standalone（官网 pkg / Homebrew Cask）是默认方案。当前 Cask 名为 `tailscale-app`，旧名 `tailscale`；`brew install --formula tailscale` 安装的是不同的开源 CLI/daemon。
- 已安装且正常则复用，常规接入不顺带升级/迁移。新装可运行 `brew install --cask tailscale-app`，打开应用完成扩展和 VPN 授权并登录。不要同时运行两个 Tailscale 发行形式。
- 启用 Tailscale“登录时启动”，用其状态确认已连接；不要把登录启动称作开机登录前运行。

没有配置 CLI 集成时可使用应用内命令：

```bash
/Applications/Tailscale.app/Contents/MacOS/Tailscale status
/Applications/Tailscale.app/Contents/MacOS/Tailscale ip -4
```

可将这个路径赋给当前 shell 的 `TS_BIN`，后续用 `"$TS_BIN" ...`。确认两端在预期账号/tailnet 下，记录实际设备名、IPv4 及完整 MagicDNS 名。

MagicDNS 在管理后台 DNS 页面配置，机器名在 Machines 页面管理。macOS 上用 `dscacheutil -q host -a name <name>` 查询系统解析，`scutil --dns` 查看 Tailscale resolver 和搜索域；`dig`/`nslookup` 的路径可能不同，不能单独用其结果判定系统解析失败。`known_hosts` 保存身份密钥，不提供 DNS 映射。

## 2. 远程登录（被连接机）

系统设置 → 通用 → 共享 → 远程登录：开启，并允许实际需要登录的本地账户。普通终端访问不额外授予完全磁盘访问。

具备相应权限时可通过终端查看/启用：

```bash
sudo systemsetup -getremotelogin
sudo systemsetup -setremotelogin on
```

如果 systemsetup 明确要求当前终端的完全磁盘访问，改由系统 UI 完成这次设置，或让用户按需批准；不假称命令已成功。从连接机用 `nc -vz -G 5 <address> 22` 和 `ssh <user>@<address>` 验证。

首次主机密钥确认：通过已有可信连接或被连接机本地核对 `ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub`；首次出现同密钥已知于其他可信地址是有用证据。密钥改变时核实原因再更新相应记录，不禁用校验。

## 3. 稳定性（被连接机）

读取并记录原来的 `pmset -g custom` 与必要的 `pmset -g sched`。常接电 Mac mini 等台式机可执行：

```bash
sudo pmset -c sleep 0
pmset -g custom
```

`sleep 0` 关闭该供电配置下的闲置系统睡眠；`displaysleep` 是显示器计时器，可以保留。`sleep 1` 表示允许闲置 1 分钟后睡眠，不是已经实际休眠的证明。保持锁屏密码要求；自动睡眠关闭不等于处理器持续满载。

恢复时用记录的数值：`sudo pmset -c sleep <original-minutes>`。只修改解决当前问题的项目。`womp 1` 是网络唤醒能力，不会让 Tailscale 在睡眠中持续处理连接。手动睡眠、断电和系统重启另行处理。

笔记本默认保留电池睡眠策略；要接电长期服务时明确设置仅作用于 AC，并说明 `sleep 0` 不保证合盖运行。合盖使用先核对该机型及外接设备的官方要求，不套用台式机结论。

验收时在用户允许的窗口断开测试 SSH、保持息屏/锁屏并闲置后重连；活跃 SSH 或其他防睡眠进程可能影响观测。日志需要时用 `pmset -g log` 查真实 Sleep/Wake 事件。不要仅凭一次上线就确认休眠是唯一根因。

## 4. 公钥（连接机）

读取有效 SSH 配置并列出已有 `.pub`，不输出私钥。可用 `ssh-keygen -lf <public-key>` 记录指纹。优先复用用户选定的密钥；缺失时创建独立 Ed25519 密钥且不覆盖已有文件：

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_tailscale
```

让用户交互选择口令。需要避免重复输入私钥口令时，macOS 可执行 `ssh-add --apple-use-keychain <private-key>` 并配置 `AddKeysToAgent yes`、`UseKeychain yes`；这和远端账户密码是两回事。

常用安装：

```bash
ssh-copy-id -i <public-key> <user>@<address>
```

不带 `-f`，保留去重行为。若目标已有该密钥而登录仍失败，查权限、账户、sshd 和认证日志，不强制再追加。

只有缺少 ssh-copy-id 时才用以下 shell 模板，先将变量替换为真实参数。用固定命令在远端去重，并校正 OpenSSH 所需权限：

```bash
PUBKEY="$HOME/.ssh/id_ed25519_tailscale.pub"
TARGET='remote-user@target-address'
cat "$PUBKEY" | ssh "$TARGET" 'set -eu
umask 077
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
touch "$HOME/.ssh/authorized_keys"
chmod 600 "$HOME/.ssh/authorized_keys"
IFS= read -r key
if ! grep -qxF -- "$key" "$HOME/.ssh/authorized_keys"; then
    printf "\n%s\n" "$key" >> "$HOME/.ssh/authorized_keys"
fi'
```

公钥是单行 OpenSSH 公钥。目录/文件若不属于该账户，先查明实际所有者与来源，不直接递归 chown。

## 5. SSH 别名（连接机）

先读现有 config、Include 和有效值，保存原文件再合并具体 Host 块。SSH 多数配置使用最先匹配的值，Host * 在前可能抢先设置 User；不能只追加后就宣称生效。

```sshconfig
Host my-mac
    HostName target-magicdns-or-ip
    User remote-user
    IdentityFile ~/.ssh/id_ed25519_tailscale
    IdentitiesOnly yes
```

配置文件权限 `600`。选择 MagicDNS 可随名称映射使用，固定 IP 可减少名称解析依赖；以用户选择为准。验证：

```bash
ssh -G my-mac
ssh -o BatchMode=yes -o PreferredAuthentications=publickey -o IdentitiesOnly=yes -i ~/.ssh/id_ed25519_tailscale my-mac 'whoami'
```

BatchMode 失败可能是加密私钥尚未加入 agent；区分远端密码与私钥口令，不能通过设空口令静默处理。

## 6. 可选 GUI

被连接机系统设置 → 通用 → 共享 → 屏幕共享，允许目标账户。连接机 `open 'vnc://<tailscale-ip>'`，用远端账户登录。端口 5900 可达不等于权限认证通过；屏幕共享与 SSH 公钥各有认证机制。SSH config 的 Host 别名不自动成为 VNC 的 DNS 名。

## 来源

- [Tailscale macOS 发行形式](https://tailscale.com/docs/concepts/macos-variants)
- [MagicDNS](https://tailscale.com/docs/features/magicdns)
- [Apple 远程登录](https://support.apple.com/zh-cn/guide/mac-help/mchlp1066/mac)
- [Apple 屏幕共享](https://support.apple.com/zh-cn/guide/mac-help/mh11848/mac)
- 睡眠选项、SSH 参数与 Keychain 集成以目标机器 `man pmset`、`man ssh_config`、`man ssh-add` 为准。
