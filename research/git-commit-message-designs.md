# Git commit message 的 type 与正文 Section 设计研究

研究日期：2026-07-22  
研究对象：`skills/git-commit-message/SKILL.md`  
研究目标：为 `<type>(<scope>): <summary>` 标题和按 Section 分组的 bullet 正文建立职责清晰、适合 staged changes、可解释且不过度依赖文件定位的规则。

本文使用三类标记：

- **[规范原文]**：官方规范、项目贡献指南或官方工具文档明确规定的内容；
- **[证据推论]**：由一个或多个一手来源支持，但不是来源逐字规定的设计判断；
- **[本 Skill 建议]**：面向当前 Skill 的取舍，不宣称为上游规范。

## 结论先行

1. **[本 Skill 建议] 保留 Conventional Commits 作为语法外壳，但不要把本地扩展误称为规范原文。** Conventional Commits 只明确规定 `feat`、`fix` 的语义，允许其他 type；scope 是“代码库某个 section 的名词”；body 是自由格式；footer 才是结构化元数据。正文中的路径 Section 属于本 Skill 的本地约定。[规范原文：Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/)
2. **[证据推论] 四层信息应正交：**
   - `type`：这次提交的**主要意图/变更性质**；
   - title `scope`：读者最先需要看到的**单一主影响域**，不承担完整文件覆盖；
   - body `Section`：从 staged paths 得出的**阅读导航和多模块分组**；
   - trailers：供工具或流程消费的**破坏性、问题关联、评审、署名、依赖等元数据**。  
   这种边界分别得到 Conventional Commits 的 type/scope/body/footer 分层、Nx 的“受影响项目由 changed files 而不是 scope 判断”、Git trailer 的末尾结构化信息模型支持。[Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) [Nx](https://nx.dev/docs/guides/nx-release/automatically-version-with-conventional-commits) [git-interpret-trailers](https://git-scm.com/docs/git-interpret-trailers)
3. **[本 Skill 建议] “Section 必须是 staged path 中真实存在的单个路径段”可以采用，但应定位为可验证的本地约束，而不是普适最佳实践。** 它能避免模型凭空发明 `core/runtime` 一类范围，也与 Nx 以 changed files 为事实来源的做法一致；但 Linux tip 偏好语义化 `subsys/component:` 并明确反对文件名或完整路径，Angular 也允许非路径语义 scope 和跨包空 scope。[Nx](https://nx.dev/docs/guides/nx-release/automatically-version-with-conventional-commits) [Linux tip](https://docs.kernel.org/process/maintainer-tip.html#patch-subject) [Angular](https://github.com/angular/angular/blob/main/contributing-docs/commit-message-guidelines.md#scope)
4. **[本 Skill 建议] Section 粒度应随 staged changes 自适应，但“自适应”必须有确定性规则。** 从顶层路径段开始；只有当某组包含多个独立、读者关心的子对象时才下钻；每个标题仍只能是一个真实路径段；无法用单段无歧义地区分时，合并到更宽的真实段并在 bullet 中说明对象，而不是制造 `a/b`、`a+b` 或语义别名。Git、ChromiumOS、Linux tip 和 LLVM 都建议从相关路径的近期历史判断本地 area/component 惯例，但没有任何一个来源规定按 staged paths 自动生成正文 Section。[Git](https://git-scm.com/docs/SubmittingPatches) [ChromiumOS](https://www.chromium.org/chromium-os/developer-library/guides/development/contributing/) [Linux tip](https://docs.kernel.org/process/maintainer-tip.html#patch-subject) [LLVM](https://llvm.org/docs/DeveloperPolicy.html#commit-messages)
5. **[本 Skill 建议] 多模块提交时，scope 不应列举全部模块。** 单一主模块时用它作 scope；多个同等重要模块时省略 scope；body 再按真实模块段分组。Nx 明确不以 scope 判断独立发布中的 affected project，Angular 明确允许跨全部 package 的 `test`/`refactor` 使用空 scope；若多个模块其实是独立意图，优先拆 commit，Conventional Commits FAQ 也建议能拆则拆。[Nx](https://nx.dev/docs/guides/nx-release/automatically-version-with-conventional-commits) [Angular](https://github.com/angular/angular/blob/main/contributing-docs/commit-message-guidelines.md#scope) [Conventional Commits FAQ](https://www.conventionalcommits.org/en/v1.0.0/#what-do-i-do-if-the-commit-conforms-to-more-than-one-of-the-commit-types)

## 一手来源核查：十种规范与实践

### 1. Conventional Commits 1.0.0

**[规范原文]**

- 格式为 `<type>[optional scope]: <description>`，后接可选 body 和 footers。
- `feat` 对应 SemVer MINOR，`fix` 对应 PATCH，任意 type 均可用 `!` 或 `BREAKING CHANGE:` 表达 MAJOR。
- scope 是描述代码库某个 section 的名词；body 可选且自由格式；footer 使用受 Git trailer 启发的 token/value 格式。
- 除 `feat`、`fix` 外的 type 可由项目扩展；一次提交符合多个 type 时，FAQ 建议尽可能拆分。[官方规范](https://www.conventionalcommits.org/en/v1.0.0/)

**[证据推论]** 它适合做 title/footer 的兼容基线，但没有定义完整 type 枚举，也没有定义正文路径 Section；不能从“符合 Conventional Commits”推出固定 `pipeline:`、`src:` 等正文标题。

### 2. Angular commit message guidelines

**[规范原文]**

- type 是闭合枚举：`build`, `ci`, `docs`, `feat`, `fix`, `perf`, `refactor`, `test`。
- scope 通常是“从 changelog 读者视角看到的受影响 npm package”；`dev-infra`、`docs-infra`、`migrations`、`devtools` 是语义例外，跨全部 package 的 `test`/`refactor` 和非特定 package 的 docs 可无 scope。
- 除 `docs` 外 body 必填，解释变更动机和 why，并可比较前后行为说明影响。
- footer 用于 breaking changes、deprecations、issue/PR 关联。[官方指南](https://github.com/angular/angular/blob/main/contributing-docs/commit-message-guidelines.md)

**[证据推论]** Angular 证明范围词优先服务读者认知，不等价于逐字复制目录名；它的 package 白名单和语义别名是项目特定规则，不能跨仓库照搬。

### 3. Git 项目的 SubmittingPatches

**[规范原文]**

- 标题通常以 `area: ` 开头，area 可以是文件名或一般区域标识；拿不准时，对修改文件运行 `git log --no-merges` 查看当前惯例。
- body 要解释现状问题、为什么该解法更好，以及必要时被放弃的替代方案；目标是传递 why。
- Git 项目要求 `Signed-off-by:`，并定义 `Reported-by:`、`Reviewed-by:`、`Tested-by:`、`Co-authored-by:` 等 trailers 的流程含义。[官方文档](https://git-scm.com/docs/SubmittingPatches)

**[证据推论]** 它支持“真实文件或一般 area 都可作为范围线索”，也支持按本地历史调节粒度；但它没有 Conventional Commit type，`area:` 不能机械映射为本 Skill 的正文 Section。

### 4. Linux kernel 通用 SubmittingPatches

**[规范原文]**

- canonical subject 是 `subsystem: summary phrase`；subsystem 标识受影响 area，summary phrase 不应是文件名。
- 一个 patch 只解决一个问题；正文应自包含，说明问题、用户影响和方案。
- `Fixes:` 指向引入问题的 commit，`Signed-off-by:` 表示 DCO 路径，另有 `Acked-by:`、`Reviewed-by:`、`Tested-by:` 等明确 tags。[官方文档](https://docs.kernel.org/process/submitting-patches.html)

**[证据推论]** 它支持“短范围标签 + why-first 正文 + 严格元数据尾注”的职责分离；邮件 `[PATCH nn/mm]`、DCO 和 maintainer tree 流程不适合普通本地 commit Skill 直接照搬。

### 5. Linux tip tree handbook

**[规范原文]**

- tip 偏好的前缀是 `subsys/component:`，例如 `x86/apic:`、`x86/mm/fault:`、`sched/fair:`。
- 明确要求不要使用文件名或完整文件路径；建议用 `git log path/to/file` 寻找惯用前缀。
- body 推荐按 context、problem、solution 分段；`Fixes:` 等 tags 有顺序和自动提取价值。[官方手册](https://docs.kernel.org/process/maintainer-tip.html)

**[证据推论]** 这是“真实单路径段天然最好”的强反例：成熟项目可能有稳定、层级化、并非路径逐字映射的 subsystem taxonomy。它同时偏好 `/` 层级，与当前“不用 `name1/name2`”目标直接冲突。

### 6. ChromiumOS contributing guide

**[规范原文]**

- 示例标题使用 subsystem prefix；不确定目标仓库形式时，查看近期 `git log` 了解本地惯例。
- body 不能只依赖关联 bug，应独立解释 motivation 和 impact/action。
- `BUG=` 关联问题，`TEST=` 具体描述验证，Gerrit `Change-Id:` 放在末尾独立段。[官方指南](https://www.chromium.org/chromium-os/developer-library/guides/development/contributing/)

**[证据推论]** 可借鉴“正文说明作用而非文件列表”和“验证/问题元数据与正文分离”；`BUG=`、`TEST=`、`Change-Id:` 与其 Gerrit/issue tracker 强绑定，不是通用 footer。

### 7. Nx Release Conventional Commits

**[规范原文]**

- 默认 `feat` 触发 minor、`fix` 触发 patch、breaking change 触发 major；其他 type 的版本增量和 changelog 表现可配置。
- 对 independently released projects，Nx 按每个 commit 实际改动的文件判断影响项目，**不按 commit message scope**；`feat(pkg-2)` 也可能触发其他实际被修改项目的发布。[自动版本文档](https://nx.dev/docs/guides/nx-release/automatically-version-with-conventional-commits) [type 定制文档](https://nx.dev/docs/guides/nx-release/customize-conventional-commit-types)

**[证据推论]** 这是支持“路径是影响范围事实源、scope 只是人类标签”的最直接证据；Nx project graph、release group 和 SemVer 自动化不是当前 Skill 必须实现的功能。

### 8. OpenStack commit message 与 impact tags

**[规范原文]**

- 格式为 summary、空行、body、空行、footers；body 解释问题、为何要修和解决方案，footer 是连接外部工具的末尾段。
- `Closes-Bug`、`Partial-Bug`、`Related-Bug` 表示 bug 关系；`DocImpact`、`APIImpact`、`SecurityImpact`、`UpgradeImpact` 表示跨文件的语义影响；`Depends-On` 表示变更依赖；Gerrit 使用 `Change-Id` 跟踪 patch set。[官方贡献指南](https://docs.openstack.org/contributors/en_GB/common/git.html)
- Manila 官方项目指南要求每个 tag 单独一行，并给出 `APIImpact`、`DocImpact`、bug/blueprint tags 的项目实例。[Manila 官方指南](https://docs.openstack.org/manila/latest/contributor/commit_message_tags.html)

**[证据推论]** 它证明“影响维度”与“路径范围”是正交信息，适合放 trailer/tag 而不是 Section name；裸 `DocImpact` 等格式依赖 OpenStack 自动化，不完全等同于 Conventional Commits footer。

### 9. Kubernetes contributor guide

**[规范原文]**

- commit subject 可用社区熟悉的 kind/area 增加上下文，例如 `cleanup:`、`deprecation:`、`etcd:`、`kube-proxy:`。
- body 应说明 what 和 why。
- 大范围 PR 建议根据目录 ownership/SIG 拆分；commit message 中禁止 GitHub closing keywords 和 `@mentions`，以避免自动化副作用。[官方指南](https://github.com/kubernetes/community/blob/main/contributors/guide/pull-requests.md)

**[证据推论]** `cleanup`、`deprecation` 等成熟 area/kind 并非路径，说明语义标签有时比真实目录更适合人类；其禁止 issue closing keywords 的规则也与 OpenStack 的 commit footer 自动关联形成直接冲突。

### 10. LLVM Developer Policy

**[规范原文]**

- title 与 body 用空行分隔，body 应简洁但包含完整 rationale。
- 只有改动局限于代码的特定部分时，才惯例性添加 `[SCEV]`、`[OpenMP]` 等组件 tag，以支持过滤和搜索。
- LLVM 使用 squash workflow，最终需审阅 squashed commit 的 title/body；元数据不能替代自包含的解释。[官方政策](https://llvm.org/docs/DeveloperPolicy.html#commit-messages)

**[证据推论]** 组件标签应在“确有单一限定区域”时使用，宽泛改动不必硬填 scope；这支持多模块时允许空 scope。

## Top 5：最值得本 Skill 借鉴的方法族

### Top 1 — Conventional Commits：四层语法与意图 type

**原始规则**

- type/scope/description + 可选 free-form body + trailer-like footers；
- 标准化 `feat`、`fix`、breaking change，允许扩展 type。[官方规范](https://www.conventionalcommits.org/en/v1.0.0/)

**相似点**

- 当前标题已采用其核心语法；
- 当前 Section + bullets 可以合法地位于 free-form body。

**可借鉴**

- 把 type、scope、body、footer 当成不同信息层；
- 保持 `feat`/`fix`/breaking change 的规范语义；
- 多种独立主意图时推动拆 commit。

**不可照搬**

- 它没有完整 type enum，也没有正文路径 Section；
- 仅满足语法不能保证 scope/body 有信息量。

### Top 2 — Angular：小型 type 集与“读者感知”的 package scope

**原始规则**

- 闭合 type 集；
- scope 通常是 changelog 读者感知的 package，允许语义例外和跨包空 scope；
- body 强调 why/impact。[官方指南](https://github.com/angular/angular/blob/main/contributing-docs/commit-message-guidelines.md)

**相似点**

- 标题格式相同；
- 都追求快速理解性质、范围和作用。

**可借鉴**

- 用小型闭合集减少 type 同义词；
- scope 按读者能否认识该对象选择；
- 多 package 时允许空 scope；
- body 不重述 diff，而说明动机和影响。

**不可照搬**

- Angular package 白名单和 `dev-infra` 等别名是仓库特定知识；
- 若本 Skill 坚持 Section 必须是真实段，就不能照搬这些 Section 别名；
- Angular 当前 type 集没有 `chore`。

### Top 3 — Nx Release：monorepo 中 scope 不是影响范围的权威

**原始规则**

- type 决定版本语义；
- 实际 changed files 决定独立发布项目是否受影响，scope 不作为事实源；
- type 的 semver/changelog 行为可配置。[自动版本](https://nx.dev/docs/guides/nx-release/automatically-version-with-conventional-commits) [自定义 types](https://nx.dev/docs/guides/nx-release/customize-conventional-commit-types)

**相似点**

- 本 Skill 也以 staged changes 为唯一事实范围；
- 需要处理一次提交触及多个模块。

**可借鉴**

- 路径事实与 title scope 解耦；
- Section 候选必须能由 staged paths 验证；
- 多模块影响由 body 展开，不在 scope 中枚举。

**不可照搬**

- 无需引入 Nx project graph、release groups 或发布算法；
- affected files 可精确计算，不意味着正文应成为文件清单。

### Top 4 — Git + Linux：area/subsystem、历史惯例与 why-first 正文

**原始规则**

- Git 允许 `area:` 是 filename 或 general area，并要求查相关文件历史；body 解释问题和 why。[Git](https://git-scm.com/docs/SubmittingPatches)
- Linux 通用格式是 `subsystem: summary`，要求一个 patch 一个问题和自包含正文。[Linux](https://docs.kernel.org/process/submitting-patches.html)
- Linux tip 进一步使用稳定 `subsys/component:` taxonomy，反对 filename/full path，并推荐 context → problem → solution。[tip](https://docs.kernel.org/process/maintainer-tip.html)

**相似点**

- 都要快速显示范围，同时保留正文解释；
- 都可从 changed paths 和历史中选择范围粒度。

**可借鉴**

- 用相关路径历史而不是固定通用词典校正名称；
- summary 写交付，body 写问题、作用和理由；
- 一个 bullet 合并一个逻辑变化，不逐文件复述；
- 独立问题优先拆提交。

**不可照搬**

- tip 的斜杠层级与“不用 `name1/name2`”直接冲突；
- Git 允许 filename、tip 反对 filename，两者不能同时作为硬规则；
- kernel 邮件 patch、DCO、maintainer tree 流程不适合通用 Skill。

### Top 5 — OpenStack + ChromiumOS：把流程影响放到 metadata

**原始规则**

- OpenStack 用 footers 表示 bug、blueprint、文档/API/安全/升级影响、依赖和 Gerrit Change-Id。[OpenStack](https://docs.openstack.org/contributors/en_GB/common/git.html#footers)
- ChromiumOS 用 `BUG=`、具体 `TEST=` 和末尾 `Change-Id:` 表示问题、验证和 review identity。[ChromiumOS](https://www.chromium.org/chromium-os/developer-library/guides/development/contributing/)

**相似点**

- 本 Skill 需要表达作用，但不应把所有作用都挤进 title 或 Section name。

**可借鉴**

- “哪里变了”留给 scope/Section，“产生什么流程影响”留给 trailers；
- 测试、issue、依赖、breaking change 与普通 bullets 分离；
- 只输出有证据的 metadata，不由模型猜测。

**不可照搬**

- `DocImpact`、`BUG=`、`TEST=`、`Change-Id` 依赖特定工具链；
- bare flag 和 `=` 语法不完全符合 Conventional Commits/Git 的默认 `token: value`；
- 仅查看 staged diff 通常不知道真实测试结果、review metadata 或 issue ID。

## 面向本 Skill 的职责边界

### 1. Type：只表达主要变更意图

**[本 Skill 建议] 建议枚举**

`feat`, `fix`, `perf`, `refactor`, `test`, `docs`, `ci`, `build`, `chore`, `revert`

**[规范原文与建议边界]**

- `feat`：新增用户、调用方或工具使用者可感知的能力；规范映射为 MINOR。[Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)
- `fix`：修复错误行为；规范映射为 PATCH。[Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)
- `perf`：主要交付是性能改善。[Angular](https://github.com/angular/angular/blob/main/contributing-docs/commit-message-guidelines.md#type)
- `refactor`：既不修 bug、也不加 feature 的代码结构变更。[Angular](https://github.com/angular/angular/blob/main/contributing-docs/commit-message-guidelines.md#type)
- `test`：只增加缺失测试或修正测试；若测试只是支持 feature/fix，仍用 `feat`/`fix`。[Angular](https://github.com/angular/angular/blob/main/contributing-docs/commit-message-guidelines.md#type)
- `docs`：仅文档变化。[Angular](https://github.com/angular/angular/blob/main/contributing-docs/commit-message-guidelines.md#type)
- `ci`：CI 配置和脚本变化。[Angular](https://github.com/angular/angular/blob/main/contributing-docs/commit-message-guidelines.md#type)
- `build`：构建系统或外部依赖变化。[Angular](https://github.com/angular/angular/blob/main/contributing-docs/commit-message-guidelines.md#type)
- `chore`：仅作为上述类别都不适用时的仓库维护兜底。它是本地扩展；Conventional Commits 允许扩展 type，Nx 也允许配置其版本和 changelog 行为。[Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) [Nx](https://nx.dev/docs/guides/nx-release/customize-conventional-commit-types)
- `revert`：撤销既有提交；Conventional Commits FAQ 建议可用 `revert` + `Refs`，Angular 要求 body 说明被撤销 SHA 和原因。[Conventional Commits FAQ](https://www.conventionalcommits.org/en/v1.0.0/#how-does-conventional-commits-handle-revert-commits) [Angular](https://github.com/angular/angular/blob/main/contributing-docs/commit-message-guidelines.md#revert-commits)

**[本 Skill 建议] 选择顺序**

1. feature/fix 同时更新 tests/docs/build wiring 时，type 仍取主要交付 `feat`/`fix`；
2. 性能结果是主要、可陈述交付时用 `perf`，否则无行为变化的结构调整用 `refactor`；
3. `test`/`docs`/`ci`/`build` 仅在对应内容是提交主体时使用；
4. 多个独立主意图优先拆分，不用 `chore` 掩盖混合提交。[Conventional Commits FAQ](https://www.conventionalcommits.org/en/v1.0.0/#what-do-i-do-if-the-commit-conforms-to-more-than-one-of-the-commit-types)

不建议默认加入 `style`：Angular 当前允许列表没有它；该词也容易混淆代码格式、UI 样式和无行为重构。Conventional Commits 虽允许额外 type，但不会替项目定义这些边界。[Angular type 列表](https://github.com/angular/angular/blob/main/contributing-docs/commit-message-guidelines.md#type) [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)

### 2. Title scope：只表达一个主影响域

**[本 Skill 建议]**

- scope 可选；只有存在一个明显主模块/组件且能提高辨识度时才写。
- 优先使用读者已认识的稳定模块名；可偏好 staged path 中的真实单段名称，但不要为覆盖全部文件拼 `a/b`、`a,b` 或 `a+b`。
- 多个同等重要模块、横切式改动或只能得到 `src`、`packages` 等过宽名称时，省略 scope。
- scope 不负责证明全部 changed files；staged diff 和 body Sections 才是范围事实。Nx 明确按 changed files 而不是 scope 判断 affected project。[Nx](https://nx.dev/docs/guides/nx-release/automatically-version-with-conventional-commits)

**[规范原文]** Conventional Commits 没有要求 scope 必须是目录名；Angular 通常使用 package，但允许语义别名和跨包空 scope；LLVM 只在改动局限于特定区域时才加组件 tag。[Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) [Angular](https://github.com/angular/angular/blob/main/contributing-docs/commit-message-guidelines.md#scope) [LLVM](https://llvm.org/docs/DeveloperPolicy.html#commit-messages)

### 3. Body Section：只做 staged 范围的阅读导航

**[本 Skill 建议] 硬约束**

1. **来源约束**：Section 名必须逐字等于至少一个 staged path 中的单个路径段，区分大小写。
2. **单段约束**：不得包含 `/`；不得用 `,`、`+`、`&` 合并多个名称。
3. **不造词**：不得翻译、缩写、去后缀或创建 staged path 中不存在的语义别名。
4. **分区约束**：每条 staged path 只归入一个 Section，避免同一改动在 `src:` 和 `feature:` 下重复。
5. **可省略**：只有一个清楚的逻辑变化，或没有有用真实段时，允许无 Section 直接写 bullets；Conventional Commits 的 body 本来就是可选自由格式。[Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)

**[仓库内证据]** 当前映射把 `pipeline/<method>/demo.py` 归为 `demo:`。若采用“逐字真实路径段”，`demo` 并不合格，真实段是 `pipeline`、`<method>`、`demo.py`。主代理需要确认 basename 去扩展名是否允许；否则规则与当前示例直接冲突。

**[本 Skill 建议] 自适应算法**

1. 读取全部 staged paths 并拆为 segments。
2. 先按顶层 segment 分组。
3. 仅当某组包含两个或更多独立、值得分别阅读的子对象时，下钻到子 segment；不要因为文件多就下钻。
4. 顶层只是容器（如 `packages`、`skills`、`src`），下一层才是模块身份时，使用下一层真实 segment。
5. source 与 tests 路径都含同一模块段（如 `src/foo/...` 与 `tests/foo/...`）时，可统一归到 `foo:`，bullet 再说明实现和测试。
6. 不同分支有同名 segment 且语义不同，先选各自唯一的单段祖先；仍不能无歧义时，合并到更宽的真实段，并在 bullets 中区分，不创建复合路径标题。
7. 若每个文件都成为一个 Section，说明粒度过细：上收一级、取消 Section，或建议拆 commit。

上述算法是本 Skill 的设计，不是上游规范。可引用的一手证据仅支持“从 changed paths 和本地历史选择 area 粒度”：Git 允许 filename/general area 并建议查相关文件 log；ChromiumOS 建议看近期 log；Linux tip 建议 `git log path/to/file`；LLVM 仅在改动受限于特定部分时使用组件 tag。[Git](https://git-scm.com/docs/SubmittingPatches) [ChromiumOS](https://www.chromium.org/chromium-os/developer-library/guides/development/contributing/) [Linux tip](https://docs.kernel.org/process/maintainer-tip.html#patch-subject) [LLVM](https://llvm.org/docs/DeveloperPolicy.html#commit-messages)

**[本 Skill 建议] Section 是 “where/which object”，bullet 才是 “what/why/impact”。** Git 要求 body 解释问题和方案理由；Angular 要求 why/影响；Linux tip 推荐 context/problem/solution；Kubernetes 要求 what/why；LLVM 要求完整 rationale。因此 bullet 不应退化为文件清单。[Git](https://git-scm.com/docs/SubmittingPatches) [Angular](https://github.com/angular/angular/blob/main/contributing-docs/commit-message-guidelines.md#commit-message-body) [Linux tip](https://docs.kernel.org/process/maintainer-tip.html#changelog) [Kubernetes](https://github.com/kubernetes/community/blob/main/contributors/guide/pull-requests.md#use-the-commit-message-body-to-explain-the-what-and-why-of-the-commit) [LLVM](https://llvm.org/docs/DeveloperPolicy.html#commit-messages)

### 4. Trailers：只放可操作元数据

**[本 Skill 建议]**

- 仅在有明确证据时写 trailer；staged diff 不能可靠证明评审人、测试执行结果、issue 编号或签署身份。
- 可识别/保留 `BREAKING CHANGE:`, `Fixes:`, `Closes:`, `Refs:`, `Co-authored-by:`, `Reviewed-by:`, `Tested-by:`, `Signed-off-by:`, `Depends-On:`；项目特有格式只在仓库已有惯例或用户明确要求时输出。
- `BREAKING CHANGE:` 只描述兼容性破坏和迁移要求；Conventional Commits 允许用 `!` 或 footer 表示 breaking change。[Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)
- trailer block 位于 body 之后并以空行分隔；每个 trailer 独立一行。Git 把消息末尾类似 RFC 822 header 的行解析为结构化 trailer，默认形如 `key: value`。[git-interpret-trailers](https://git-scm.com/docs/git-interpret-trailers)
- Section 属于 body，不属于 trailer；最后一个 Section 的 bullets 后若有 trailers，必须再空一行。[git-interpret-trailers](https://git-scm.com/docs/git-interpret-trailers)

OpenStack 证明 impact 适合 metadata 而非路径分组；ChromiumOS 证明问题和验证也可成为独立 metadata。但其 bare flags、`BUG=`、`TEST=`、`Change-Id` 依赖特定自动化，不应默认泛化。[OpenStack](https://docs.openstack.org/contributors/en_GB/common/git.html#footers) [ChromiumOS](https://www.chromium.org/chromium-os/developer-library/guides/development/contributing/)

## 多模块提交如何分组

### 情形 A：一个主模块，其他改动是配套

**[本 Skill 建议]**

- type：按主交付，例如 `feat`；
- scope：主模块，例如 `foo`；
- body：若 source/tests/docs 路径都含真实段 `foo`，统一归入 `foo:`；否则按真实段分为 `foo:`、`tests:`、`docs:`；
- trailers：只放已知问题关联、breaking change 等。

依据是 type 表意图、Angular scope 表主要 package、Nx 仍以 changed files 判断真实影响项目。[Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) [Angular](https://github.com/angular/angular/blob/main/contributing-docs/commit-message-guidelines.md#scope) [Nx](https://nx.dev/docs/guides/nx-release/automatically-version-with-conventional-commits)

### 情形 B：多个同等重要模块，共同交付一个意图

**[本 Skill 建议]**

- type：共同意图，例如 `feat` 或 `fix`；
- scope：省略，不写 `foo/bar`；
- body：用真实 `foo:`、`bar:` 分组；
- summary：概括共同交付，不枚举文件。

Angular 对跨 package 的部分提交允许空 scope；Nx 不把 scope 当 affected project 的权威来源。[Angular](https://github.com/angular/angular/blob/main/contributing-docs/commit-message-guidelines.md#scope) [Nx](https://nx.dev/docs/guides/nx-release/automatically-version-with-conventional-commits)

### 情形 C：横切基础设施改动

**[本 Skill 建议]**

- type：`ci`、`build` 或 `test`；
- scope：仅在存在稳定、单一主影响域时使用，否则省略；
- body：优先真实横切段，如 `.github:`、`scripts:`、`tests:`；若路径布局以 package 为主，则按 package 段分组。

Angular 把 CI、build、test 作为意图 type，并允许部分跨 package 改动无 scope。[Angular type](https://github.com/angular/angular/blob/main/contributing-docs/commit-message-guidelines.md#type) [Angular scope](https://github.com/angular/angular/blob/main/contributing-docs/commit-message-guidelines.md#scope)

### 情形 D：多个模块、多个独立意图

**[本 Skill 建议]** 优先拆 commit。不能拆时，type 取主要交付，scope 省略，body 按真实模块段分组并明确各自作用；不要用 `chore` 模糊处理。Conventional Commits 建议多 type 时尽可能拆分，Linux 要求一个 patch 只解决一个问题。[Conventional Commits FAQ](https://www.conventionalcommits.org/en/v1.0.0/#what-do-i-do-if-the-commit-conforms-to-more-than-one-of-the-commit-types) [Linux](https://docs.kernel.org/process/submitting-patches.html#separate-your-changes)

## “真实单路径段 + staged 自适应粒度”的证据与反例

### 支持证据

1. **[规范原文]** Nx 根据 commit 实际 changed files 判断受影响项目，不信任 scope；这支持 staged paths 作为范围事实源。[Nx](https://nx.dev/docs/guides/nx-release/automatically-version-with-conventional-commits)
2. **[规范原文]** Git 允许 filename 或 general area 作为范围前缀，并建议从相关文件历史学习惯例。[Git](https://git-scm.com/docs/SubmittingPatches)
3. **[规范原文]** ChromiumOS 建议不确定格式时看目标仓库近期 `git log`；Linux tip 建议 `git log path/to/file` 找前缀。[ChromiumOS](https://www.chromium.org/chromium-os/developer-library/guides/development/contributing/) [Linux tip](https://docs.kernel.org/process/maintainer-tip.html#patch-subject)
4. **[规范原文]** Angular 默认以受影响 package 为 scope，说明稳定模块对象通常是高价值范围单位。[Angular](https://github.com/angular/angular/blob/main/contributing-docs/commit-message-guidelines.md#scope)
5. **[证据推论]** 以上来源共同支持“范围候选应能被 changed paths 或本地历史验证”，但并未要求正文 Section 必须逐字复制路径。

### 反例与风险

1. **[规范原文]** Linux tip 明确不用 filename/full path，偏好维护者定义的 subsystem/component。[Linux tip](https://docs.kernel.org/process/maintainer-tip.html#patch-subject)
2. **[规范原文]** Angular 的 `dev-infra`、`docs-infra` 是语义例外，跨包变更还允许空 scope；严格路径绑定会排除这种成熟 taxonomy。[Angular](https://github.com/angular/angular/blob/main/contributing-docs/commit-message-guidelines.md#scope)
3. **[规范原文]** Kubernetes 使用 `cleanup`、`deprecation` 等非路径 kind/area。[Kubernetes](https://github.com/kubernetes/community/blob/main/contributors/guide/pull-requests.md#providing-additional-context)
4. **[证据推论]** `src`、`lib`、`packages` 等真实段可能过宽，最深段又可能退化为文件清单；真实性不等于读者价值。[Angular](https://github.com/angular/angular/blob/main/contributing-docs/commit-message-guidelines.md#scope) [Linux tip](https://docs.kernel.org/process/maintainer-tip.html#patch-subject)
5. **[证据推论]** Git、Angular、Linux tip、Kubernetes、LLVM 都把 body 首要职责放在问题、动机、方案或 what/why；没有一个被核查来源要求正文按路径 Section 分组。[Git](https://git-scm.com/docs/SubmittingPatches) [Angular](https://github.com/angular/angular/blob/main/contributing-docs/commit-message-guidelines.md#commit-message-body) [Linux tip](https://docs.kernel.org/process/maintainer-tip.html#changelog) [Kubernetes](https://github.com/kubernetes/community/blob/main/contributors/guide/pull-requests.md#use-the-commit-message-body-to-explain-the-what-and-why-of-the-commit) [LLVM](https://llvm.org/docs/DeveloperPolicy.html#commit-messages)
6. **[约束自身结果]** 严格逐字规则下，根文件只能得到 `README.md`、`pyproject.toml` 等 basename；`demo.py` 去扩展名得到 `demo` 已不再是逐字真实段。

### 判定

**[本 Skill 建议] 有条件支持。** 把它作为 body Section 的“防幻觉、可审计”约束，但保留三个逃生口：

1. 没有有用真实段时允许无 Section；
2. 多模块 title scope 允许省略；
3. Section 只负责导航，不能替代 bullets 的 what/why/impact。

不建议把“真实单段”提升为 title scope 的绝对规则，也不建议声称它来自 Conventional Commits、Angular 或 Linux。

## 来源间的关键冲突及取舍

### 冲突 1：type 固定还是可扩展

- Conventional Commits 只固定 `feat`、`fix`、breaking change 的语义，允许其他 type。[Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)
- Angular 使用闭合 type 集。[Angular](https://github.com/angular/angular/blob/main/contributing-docs/commit-message-guidelines.md#type)
- Nx 允许自定义 type、semver 和 changelog 行为。[Nx](https://nx.dev/docs/guides/nx-release/customize-conventional-commit-types)

**[本 Skill 建议]** 采用小型闭合集，明确 `chore`、`revert` 是本地扩展；增加 `build`，避免把依赖/构建都塞进 `chore`。

### 冲突 2：范围来自路径还是语义组件

- Git 允许 filename/general area。[Git](https://git-scm.com/docs/SubmittingPatches)
- Linux tip 反对 filename/full path，偏好语义 `subsys/component:`。[Linux tip](https://docs.kernel.org/process/maintainer-tip.html#patch-subject)
- Angular 以 package 为主但允许语义别名和空 scope。[Angular](https://github.com/angular/angular/blob/main/contributing-docs/commit-message-guidelines.md#scope)
- Nx 以 changed files 判断真实影响，scope 不作权威。[Nx](https://nx.dev/docs/guides/nx-release/automatically-version-with-conventional-commits)

**[本 Skill 建议]** title scope 允许“稳定语义对象，真实路径段优先”；body Section 才实施“必须真实单段”的硬校验。

### 冲突 3：是否允许层级 scope

- Linux tip 偏好 `subsys/component:`，甚至有 `x86/mm/fault:` 多级示例。[Linux tip](https://docs.kernel.org/process/maintainer-tip.html#patch-subject)
- 当前目标明确不要 `name1/name2`。

**[本 Skill 建议]** 不采用斜杠层级；用一个可选 scope + 多个 body Sections/bullets 展开，以较低定位精度换更快扫读。

### 冲突 4：body 可选自由格式还是强制 rationale

- Conventional Commits 允许 body 缺省且自由格式。[Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)
- Angular 除 `docs` 外要求 body 并解释 why。[Angular](https://github.com/angular/angular/blob/main/contributing-docs/commit-message-guidelines.md)
- Git、Linux、Kubernetes、LLVM 强调问题、理由、影响或 what/why。[Git](https://git-scm.com/docs/SubmittingPatches) [Linux](https://docs.kernel.org/process/submitting-patches.html) [Kubernetes](https://github.com/kubernetes/community/blob/main/contributors/guide/pull-requests.md#commit-message-guidelines) [LLVM](https://llvm.org/docs/DeveloperPolicy.html#commit-messages)

**[本 Skill 建议]** 小而自明的提交可无 body；有多 Section、多模块或非显然动机时必须写 body，且 bullets 写逻辑变化和作用。

### 冲突 5：元数据语法不统一

- Conventional Commits footer 用 `token: value` 或 `token #value`。[Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)
- Git 默认 trailer 形如 `key: value`。[git-interpret-trailers](https://git-scm.com/docs/git-interpret-trailers)
- OpenStack 有 bare impact flags；ChromiumOS 使用 `BUG=`、`TEST=`。[OpenStack](https://docs.openstack.org/contributors/en_GB/common/git.html#footers) [ChromiumOS](https://www.chromium.org/chromium-os/developer-library/guides/development/contributing/)

**[本 Skill 建议]** 默认只生成 Conventional/Git 风格 trailer；检测到明确仓库惯例时才使用项目专有语法。

### 冲突 6：标题大小写

- Angular 和 Git 在 type/area 后偏好小写开头。[Angular](https://github.com/angular/angular/blob/main/contributing-docs/commit-message-guidelines.md#summary) [Git](https://git-scm.com/docs/SubmittingPatches)
- Linux tip 要求前缀后首字母大写。[Linux tip](https://docs.kernel.org/process/maintainer-tip.html#patch-subject)
- Conventional Commits 除 `BREAKING CHANGE` 外不要求实现区分大小写，并建议项目保持一致。[Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)

**[本 Skill 建议]** 沿用当前英文小写 type/summary，最终以仓库历史优先；无历史时采用 Angular 风格。

### 冲突 7：issue 引用放 commit 还是 PR

- OpenStack 用 commit footers 自动关联和更新 bug/任务。[OpenStack](https://docs.openstack.org/contributors/en_GB/common/git.html#footers)
- Kubernetes 禁止 commit message 中的 GitHub closing keywords，要求放 PR body，避免副作用。[Kubernetes](https://github.com/kubernetes/community/blob/main/contributors/guide/pull-requests.md#do-not-use-github-keywords-or-mentions-within-your-commit-message)

**[本 Skill 建议]** 不泛化 `Fixes #...`；先看仓库贡献指南。无明确惯例时使用中性 `Refs:` 或不生成 issue trailer。

## 推荐模板（设计示意，不修改 Skill）

无主 scope 时省略整个 `(<single-dominant-scope>)`；breaking change 可在冒号前加 `!`。[Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)

```text
<type>(<single-dominant-scope>): <delivered outcome>

<real-path-segment>:
- <logical change and its effect>
- <logical change and why it matters>

<another-real-path-segment>:
- <logical change and its effect>

<verified-trailer>: <value>
```

约束：

- scope 不是完整影响清单；
- Section 必须是真实单段，但可以省略；
- bullet 不写文件清单；
- trailer 必须有证据，并与 body 空行分隔；
- 多个同等重要模块用多个 Sections，不用复合 scope；
- 多个独立意图优先拆 commit。

## 一手来源清单

1. Conventional Commits 1.0.0：语法、`feat`/`fix`、scope、free-form body、footer、breaking change、拆 commit FAQ。  
   https://www.conventionalcommits.org/en/v1.0.0/
2. Angular Commit Message Guidelines：闭合 type、package scope、跨 package 空 scope、why-first body、breaking/deprecation footer。  
   https://github.com/angular/angular/blob/main/contributing-docs/commit-message-guidelines.md
3. Git SubmittingPatches：`area:`、filename/general area、从相关文件历史选择标识、why-first body、署名和评审 trailers。  
   https://git-scm.com/docs/SubmittingPatches
4. Git `interpret-trailers`：末尾结构化 trailer 的位置、解析和 `key: value`。  
   https://git-scm.com/docs/git-interpret-trailers
5. Linux kernel SubmittingPatches：`subsystem: summary`、单问题 patch、正文影响、`Fixes:`、`Signed-off-by:`。  
   https://docs.kernel.org/process/submitting-patches.html
6. Linux tip tree handbook：`subsys/component:`、禁止 filename/full path、从路径历史找前缀、context/problem/solution。  
   https://docs.kernel.org/process/maintainer-tip.html
7. ChromiumOS Contributing Guide：本地 `git log` 惯例、`BUG=`、具体 `TEST=`、Gerrit `Change-Id`。  
   https://www.chromium.org/chromium-os/developer-library/guides/development/contributing/
8. Nx Automatically Version with Conventional Commits：type 到版本、独立发布、affected project 由 changed files 而非 scope 决定。  
   https://nx.dev/docs/guides/nx-release/automatically-version-with-conventional-commits
9. Nx Customize Conventional Commit Types：自定义 type、semver bump、changelog title/visibility。  
   https://nx.dev/docs/guides/nx-release/customize-conventional-commit-types
10. OpenStack Contributor Guide：summary/body/footer、bug/blueprint、impact、dependency、`Change-Id`。  
    https://docs.openstack.org/contributors/en_GB/common/git.html
11. OpenStack Manila Commit Message Tags：`APIImpact`、`DocImpact`、bug/blueprint 和 tag 位置实例。  
    https://docs.openstack.org/manila/latest/contributor/commit_message_tags.html
12. Kubernetes Pull Request Guide：kind/area 前缀、what/why body、按 ownership 拆分宽仓改动。  
    https://github.com/kubernetes/community/blob/main/contributors/guide/pull-requests.md
13. LLVM Developer Policy：特定组件 tag、完整 rationale、squash workflow 的最终 commit message。  
    https://llvm.org/docs/DeveloperPolicy.html#commit-messages

## 仍需主代理核验的薄弱点

1. **仓库本地历史缺失。** 研究时 `main` 尚无 commit，`git log` 无法提供 area/scope 惯例；当前只有 `skills/git-commit-message/SKILL.md` 处于 staged 状态。Git、ChromiumOS、Linux tip 建议的“查近期历史”暂不可执行，需要确认这是新仓库、浅克隆还是尚未接入上游历史。
2. **“真实路径段”是否允许 basename 去扩展名。** 严格解释下 `demo.py` 不能写成 `demo:`。需明确选择逐字 segment（更可审计）或对象 stem（更易读但需要规范化规则）。
3. **Section 是否必须覆盖每个 staged file。** 本报告建议全部覆盖且每条 path 只归组一次，但上游规范没有该要求；若目标只是快速了解，是否忽略生成文件或低价值配套文件仍需产品取舍。
4. **`chore`、`build`、`revert` 的最终枚举。** 当前 Skill 有 `chore`、没有 `build`/`revert`；Angular 当前规则有 `build`、没有 `chore`。应结合未来 release/changelog 工具是否消费 type 决定。
5. **trailers 的宿主平台行为。** GitHub、Gerrit、OpenStack、ChromiumOS 对 issue、Change-Id、bare flags、`TEST=` 的处理不同；不知道目标工作流时不应自动生成。
6. **OpenStack Wiki 原页可访问性。** 优先核查项 `wiki.openstack.org/wiki/GitCommitMessages` 当前有反自动化挑战；本报告改用 OpenStack 官方 Contributor Guide 和 Manila 官方文档交叉核查。若必须核对历史 Wiki 的完整旧标签列表，需人工浏览或从 OpenStack 官方仓库定位源文件。

