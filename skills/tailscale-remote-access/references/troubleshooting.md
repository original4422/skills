# 分层排障与经验依据

| 层次 | 检查 | 解释与下一步 |
| --- | --- | --- |
| 目标选择 | `ssh -G <alias>` | 核对有效 hostname/user/port/identityfile/proxy 配置；命令行别名不等于 DNS 名。 |
| DNS | `dscacheutil -q host -a name <host>` | IP 能连但名称失败，查 MagicDNS、搜索域和客户端 DNS 配置。 |
| Tailscale 状态 | `tailscale status` | 自己行末 `-` 正常；offline/last seen 是状态线索。active/direct、累计收发量不是实时探测。 |
| 隧道 | `tailscale ping --c 1 --timeout 3s <address>` | pong 支持当前隧道可达；direct 与 DERP 都可以承载 SSH。失败也要独立检查 TCP，不只用 ping 下结论。 |
| TCP | macOS `nc -vz -G 5 <address> 22` | 成功只证实端口可达。超时查睡眠、网络、接入策略/防火墙及 shields-up；拒绝通常查服务是否监听。 |
| 认证 | 仅公钥 BatchMode + `whoami` | Permission denied 查用户名、密钥、authorized_keys 权限和服务器设置；已经进入认证阶段才查认证。 |
| 长期稳定 | 闲置后重测、Sleep/Wake 日志 | 区分闲置睡眠、Tailscale 退出、断网、注销和重启。 |

优先用已有可信校园网/LAN SSH 通道检查被连接机，确认能联网、Tailscale 进程/健康状态和 SSH 服务。不要为了排查直接关闭所有防火墙、删除所有 known_hosts、清空配置或重装正常客户端。遇到持续同一失败而无新证据，汇报具体失败层及需要用户执行的一项动作。

Tailscale 访问也受 tailnet 网络访问策略和客户端“允许入站连接”控制。网络受限可能走 DERP，不能只因为未直连就判定无法 SSH；跨网连接失败时两端 `tailscale netcheck` 可补充 UDP/中继可达性证据。

## 可复用经验的证据强度

来自一次 Mac Air ↔ Mac mini 实际配置：

- 读到被连接机 `sleep 1`，观察到 Tailscale 多次短暂在线后离线：支持自动睡眠假设，但未单凭这些证据确认唯一根因。
- 校园网 SSH 可登录：证明当时系统 SSH 与该账户可用，不代表 Tailscale 路径同时正常。
- 后续实测 Tailscale 地址 TCP 22 可达，名称解析可用：分别确认端口和 DNS 恢复；不能据此声称已验证重启或整夜稳定。
- 新增设备的实际 Tailscale 名称与用户口述简称不同：应读取实际设备列表，不能假定名称或账户。
- 同一设备经校园网地址、MagicDNS 和 Tailscale IP 连接时，首次主机确认可能显示相同密钥已知于其他地址；身份记录与地址解析职责不同。

不把上述个例写成“Tailscale 掉线一定是睡眠”或“设备 IP 永不变化”。

按需监控只在用户请求时创建；离线且无可行动变化保持安静，实际 SSH 端口恢复再通知，并按用户约定停止。监控不能代替配置修复。

## 来源

- [设备连通性排查](https://tailscale.com/docs/reference/troubleshooting/connectivity/connect-device-failure)
- [使用同网常在线设备进行网络唤醒](https://tailscale.com/blog/wake-on-lan-tailscale-upsnap)
