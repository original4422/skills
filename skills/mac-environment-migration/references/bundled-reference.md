# 内置 Mac 参考配置

本配置整理自 2026 年 9 月 27 日的导出，源机使用 Apple 芯片和 macOS 15.7.8。按用户所选范围引用对应内容。拟定计划前，复查目标机的硬件、macOS、现有软件和偏好设置。「未设置」是源机界面的观测结果，目标机已有值默认保留。

## macOS 设置

| 项目 | 源机偏好 |
| --- | --- |
| 程序坞 | 位于底部，关闭自动隐藏和放大。图标大小 57，放大大小 16（放大已关闭）。最小化使用神奇效果。 |
| 访达 | 显示路径栏和状态栏。使用图标视图（`icnv`），默认搜索当前文件夹（`SCcf`）。关闭文件夹优先排序。桌面显示外置磁盘和可移动介质，隐藏内置磁盘。 |
| 键盘 | `KeyRepeat=2`、`InitialKeyRepeat=30`、`AppleKeyboardUIMode=2`。开启自动大写和双空格插入句号。关闭「将 F1、F2 等键用作标准功能键」（`com.apple.keyboard.fnState=false`）。 |
| 触控板 | 开启轻点来点按、辅助点按、三指拖移、捏合缩放和旋转。跟踪速度 1.5，两个点按阈值均为 1。 |
| 触控板轻扫编码 | 源机 `TrackpadThreeFingerHorizSwipeGesture` 和 `TrackpadThreeFingerVertSwipeGesture` 均为 0，对应的四指编码均为 2。以目标机界面显示并支持的手势为准。 |
| 蓝牙鼠标 | 源机为 `MouseButtonMode=OneButton`，横向和纵向滚动均开启。列入计划前检查实际连接的鼠标。 |
| 语言和地区 | 简体中文（中国）在前，英语（英国）在后。地区为中国（`zh_CN`），时区为 `Asia/Shanghai`。 |
| 输入法 | ABC 和简体拼音，使用目标机内置输入法。 |
| 触发角 | 左上角按住 Command 锁屏，源机动作编码为 13，修饰键为 1048576。右下角直接打开快速备忘录，动作编码为 14。右上和左下未设置。 |

源机的程序坞顺序为启动台 → Google Chrome → 系统设置 → 备忘录 → Visual Studio Code → ChatGPT → Claude → 微信 → QQ → Clash Verge → iTerm2 → Notion Calendar。在目标机匹配可用应用，跳过缺失项，并默认保留目标机特有的项目。

| 快捷键功能 | 源机按键 | 快捷键 ID |
| --- | --- | --- |
| 聚焦搜索 | ⌘Space | 64 |
| 访达搜索 | ⌥⌘Space | 65 |
| 上一个输入法 | ⌃Space | 60 |
| 下一个输入法 | ⌃⌥Space | 61 |
| 全屏截图复制到剪贴板 | ⇧⌘3 | 29 |
| 区域截图复制到剪贴板 | ⇧⌘4 | 31 |
| 全屏截图存为文件 | ⌃⇧⌘3 | 28 |
| 区域截图存为文件 | ⌃⇧⌘4 | 30 |

按批准范围逐项修改快捷键。源机将剪贴板和文件的截图快捷键对调过，迁移时在目标机界面核对实际输出位置。本配置排除电源、显示器布局、网络及组织管理偏好。

## 应用

下表是导出时选定的 18 个安装项。cask 名称为当时的候选渠道，列入目标机计划前需核实当前软件包身份和兼容性。

| 应用 | Homebrew cask 候选 |
| --- | --- |
| Antigravity | `antigravity` |
| CC Switch | `cc-switch` |
| ChatGPT | `chatgpt` |
| Clash Verge | `clash-verge-rev` |
| Claude | `claude` |
| Discord | `discord` |
| Docker Desktop | `docker-desktop` |
| Google Chrome | `google-chrome` |
| Inkscape | `inkscape` |
| 飞书 | `feishu` |
| Notion Calendar | `notion-calendar` |
| QQ | `qq` |
| MacTeX | `mactex` |
| Visual Studio Code | `visual-studio-code` |
| 微信 | `wechat` |
| WorkBuddy 国内版 | `workbuddy-cn` |
| iTerm2 | `iterm2` |
| 语雀 | `yuque` |

MacTeX 按一次安装计算，包含 TeX Live、BibDesk、LaTeXiT、TeX Live Utility、TeXShop 和 hintview。WorkBuddy 按导出时确认的国内版规划。账号登录和应用状态按目标机的单应用流程处理。

## 开发环境和终端

- 以 Homebrew 和 Zsh 为基础，使用目标机实际的 Homebrew 安装前缀和 Zsh 启动文件。源机用的是 Oh My Zsh、`git` 插件和 `powerlevel10k/powerlevel10k` 主题。
- Powerlevel10k 使用 Lean 单行风格，布局紧凑、文字简洁，使用 Nerd Font v3 大图标且图标较少，瞬时提示符为详细模式。左侧段为 `dir`、`vcs` 和 `prompt_char`。用目标版本的配置向导复现，或把这些选项合并进现有配置。
- iTerm2 的字体、配色、光标、窗口尺寸和 Option 键设置见[外观偏好](bundled-iterm2-visual.json)。保留目标机已有的配置方案，并核对所选字体是否安装。JSON 使用 iTerm2 的原始字段名。
- 按需合并 Git 全局忽略规则 `**/.claude/settings.local.json`。用户身份取自目标机已有配置或由用户提供。使用 GitHub CLI 作为凭据助手时，在目标机完成配置并走正常登录流程。
- NVM 和 Miniconda 只考虑安装管理器本体。计划中排除 NVM 管理的源机 Node 版本和别名、Conda 环境及旧环境中的包。源机 Conda 使用 `defaults` 渠道并自动激活 base。是否沿用此偏好由目标机计划决定。
- 独立运行时的规划候选包括 Homebrew 的 Node 26、Python 3.13 和 3.14、pnpm 10、JDK 25 和 26、.NET 8 和 10，以及 Rust、uv 和 Bun。按用途和兼容性取舍。源机 Homebrew 所带 npm 下的 GitHub Copilot CLI 和 npm 也可按需核对。
- 其余直接使用的工具按需审阅。源机记录包括 `azure-cli`、`bazelisk`、`cargo-audit`、`cmake`、`curl`、`docker-compose`、`ffmpeg`、`gh`、`graphviz`、`hermes-agent`、`kimi-code`、`librsvg`、`maven`、`ninja`、`opencode`、`openssl@3`、`pre-commit`、`smartmontools`、`trufflehog`、`typos-cli`、`vercel`、`wget`、`antigravity-cli`、`claude-code@latest`、`codex` 和 `font-hack-nerd-font`。
- 根据目标机所选工具确定要追加的 PATH，保留现有有效条目。排除源机过期的 Node 路径、代理别名和工具注入的路径。用户需要代理时，再按目标机的实际环境配置。
