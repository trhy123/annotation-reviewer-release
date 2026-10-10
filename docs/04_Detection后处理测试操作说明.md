# 4 Detection 后处理测试操作说明

[返回总目录](00_操作手册.md)

## 4.1 输入与状态边界

输入为同一视频的 raw 缓存；局部试验重放候选并重新建立身份状态。它不修改已审阅 SQLite，也不重新运行 YOLO。设置窗口可与播放器同时操作。进入试验前处理未提交编辑；试验图层为只读检查，正式标注编辑应返回审阅图层。

## 4.2 标准试验规程

1. 打开视频，在 Control 点击 **Choose raw**，选择同一视频的缓存。
2. 把播放器停在想观察的时间，点击 **Settings**。
3. 在 **Before (s)** / **After (s)** 输入当前锚点前后要看的秒数，默认各 30 秒。播放不会自动改变锚点；点击 **Center here** 才改为当前帧。
4. 修改表格 **Current** 列。有效修改停止 500 毫秒后自动计算；也可点 **Update**。
5. 播放器顶部一行 **Updating preview…** 表示正在更新。计算期间仍显示旧结果；新请求会取消旧请求，迟到结果不会覆盖最新请求。
6. 完成后，原播放器直接显示新结果，不需要再点 Load。逐帧或循环查看，继续修改 Current。
7. 满意时点击 **Apply / Close** 保存参数；需要正式结果时先做 **Full replay**。

预览计算存在延迟：目标密集、区间较长或首次解码时仍可能等待。应以 Showing 列及完成状态确认画面对应的参数。失败或停止时保留旧结果，并在窗口状态栏说明。

## 4.3 表格与暂存方案

表格四列分别是：

- **Parameter**：参数项目，悬停看作用。
- **Current**：当前草稿，可编辑；自动预览使用这一列。
- **Reference**：可编辑的参考副本；与 Current 不同的值用浅黄色标出，不改写其来源文件或 Trial。
- **Showing**：画面正在使用的结果配置，只读；与 Current 不同的值标浅红。计算中保留旧画面时，此列仍显示旧结果参数。Raw / Off 没有后处理配置，显示破折号。

布尔只读值使用 √ / 空白。数字去掉多余末尾零；表格不显示选中单元格的强调边。

Preset / Trial 下拉框可选择预设文件或暂存 Trial，复制到 Reference。**选择来源、编辑 Reference 都不修改 Current**；点击 **Use reference** 才复制到 Current 并更新预览。选择另一个来源会重置 Reference 临时副本；想保留一组效果，先 Use reference 完成预览，再 Keep trial。完整配置中未在表格暴露的参数会保留，不会因编辑几个可见参数而丢失。

**View** 控制播放器看什么：

- **Current**：最近完成的当前试验结果；计算中可能是上一版。
- **Trial 1…5**：点击 Keep trial 保存的结果和参数。切换 Trial 同时在 Reference 列展示它的参数，但不覆盖 Current。
- **Raw**：上游框和 raw ID，不是后处理稳定 ID。
- **Off**：关闭试验图层，返回原审阅图层；不卸载 raw。

**Keep trial** 只能暂存已经完成且未过期的 Current，最多五组；第六组挤出最旧一组。Trial 仅在当前视频会话中保留，不是长期工程存档。建议在换视频前用 **Save JSON** 导出想保留的参数。

**Open JSON** 把完整参数快照复制到草稿；**Save JSON** 导出当前完整参数，不运行算法，也不载入/覆盖标注。保存文件是显式操作，之后点 Cancel 不会删除该文件。

## 4.4 Apply 与 关闭窗口

- **Apply / Close**：提交 Current、前后秒数、循环等选项到 settings.ini，并保留预览。
- **Cancel / 关闭窗口 / Esc**：丢弃这一轮草稿及区间修改，取消未完成请求，恢复打开窗口前的设置和预览。
- 已明确执行 Full replay/Save JSON 生成的独立文件不会被取消操作删除。
- 只有正式 **Load result** 才将结果载入审阅数据；未保存标注的保护仍生效。

设置窗口是非模态，可以开着它播放、定位视频。自动预览不修改已审阅 SQLite。

## 4.5 单只观察、恢复标记和事件

点击试验图层中的真实检测框：

- 显示简短英文摘要，包括 stable ID、raw ID、观测/估计属性、检测序号及记录到的关联/拒绝原因。
- 聚焦对应的上游观测 `(frame, det_index)`，只显示该观测在当前方案中所属轨迹；后端仍计算所有目标，不以单只输入改变竞争关系。
- 换 Trial 时重新通过该观测寻找对应轨迹，不把不同方案里数值相同的 stable ID 当作同一只。
- **Previous event / Next event** 跳到聚焦轨迹记录的前后关联事件；**Clear focus** 恢复显示全部框。

若某方案压掉了锚点观测，可能没有可对应轨迹，此时可 Clear focus 后重新点框。估计框没有可靠原始观测锚点。

标签 **R** 标记发生跨缺失帧恢复的那一帧；**~** 表示估计位置而非真实检测。R 只说明执行了恢复，不保证恢复正确。普通相邻帧关联无需每帧特别标记。Raw 图层仍显示 raw ID；点击时可附带 Current 对同一个原始检测的诊断，并明确标注 Candidate diagnostics 及 stale 状态，不把 raw ID 当成稳定 ID。

局部画面没有框时，先确认当前帧处于窗口显示的 Frames 范围，再确认是否启用了聚焦，不要立即认定为漏检。

## 4.6 身份连续性与几何位置控制

框坐标变化和 ID 切换是两个不同问题。

| 参数 | 作用与代价 |
| --- | --- |
| Preserve observed boxes | 真实观测框保持上游坐标，禁用会移动/缩放观测框的兼容调整；不能消除 YOLO 本身抖动 |
| Gap recovery | 所有跨缺失帧身份恢复的总开关；关闭仍保留相邻帧关联，但更容易断轨 |
| Position hold | 缺失时是否短暂输出占位框；与身份记忆分开 |
| Gap interpolation | 恢复后是否回填估计框；与恢复身份分开 |
| Clear raw aliases | 换 raw ID 后释放旧映射，避免残留归属参与后续竞争 |
| Guard missing owners | 防止缺失目标仅靠旧框压掉新观测 |
| Guard raw continuation | raw ID 没变也检查几何和身份竞争；更严格可能断轨 |
| Guard gap assignment | 对缺失恢复做歧义检查，不额外收紧普通相邻帧匹配 |
| Conservative assignment | 对所有关联使用严格检查，可能增加断轨；不是前四项保护的必要总开关 |
| Overlap ID reuse | 允许仅基于重叠路径复用身份，有串 ID 风险 |

General relink 只是一个恢复路径。关闭它后，raw ID 延续、短间隔匹配、drop、静止、遮挡、全局路径仍可能恢复身份。要禁止全部跨缺失恢复，用 Gap recovery。

DORMANT_STATIC_SECONDS、HORNET_IDENTITY_MEMORY_SECONDS 控制记忆多久；MAX_LOST_SECONDS、HORNET_POSITION_HOLD_SECONDS 控制占位多久。插值上限另外由 MAX_INTERP_SECONDS、MAX_DROP_INTERP_SECONDS 及相关开关控制。

建议先固定上游和其他参数，只比较 Preserve observed boxes，再分别观察恢复开关和歧义检查的影响。不要同时收紧所有阈值；错误续接减少时也要观察断轨和真实跌落恢复损失。保留原始坐标不等于已经解决身份交换。

## 4.7 预设与完整参数快照

- **General.json / General**：通用基础关联，关闭墙面物种规则和补位置类操作，不假设目标都属于蜜蜂/胡蜂；类别名称来自模型或 raw 元数据。
- **bee_hornet_revised.json / Bee / Hornet wall**：保留墙面场景原有类别保护及恢复规则，保持观测坐标，释放旧归属并增加独立保护；保留短位置 hold，默认不做恢复后的回填插值。

这些是可试验的起点，不是所有视频的最优参数保证。

程序从根目录 presets_detection 文件夹读取 JSON 的 preset 字段作为名称，并读取默认标志；不在代码里规定场景名。旧 Default 标识由文件内兼容别名识别。已保存的完整旧参数快照按其记录值恢复，不会因为同名预设文件更新而悄悄改算法。采用文件预设时，在 Preset / Trial 选择来源，再点击 Use reference 和 Apply / Close。

settings.ini 保存的是参数和选择，不是 Python 算法。预设为数据文件，不执行任意 Python 代码。

## 4.8 局部试验、全片结果和文件安全

局部试验会加入至少 15 秒前置上下文，身份记忆更长时相应增加；末尾增加 2 秒。仅显示所选区间。有限上下文不能保证 stable ID 编号和最终清理与全片一致。

**Full replay** 从缓存起点计算到最后已提交帧并执行最终清理，自动显示结果，同时生成独立结果 SQLite。缓存不完整时只处理已有范围，不补造缺失帧，也不自动重新跑 YOLO。

选择 `实验5/csv` 为输出目录时，试验结果写入同级 `实验5/postprocess_lab`。局部试验保存临时 preview.sqlite；全片结果保存一个自包含 SQLite 工程，包含 raw、final、试验预览与诊断表，metadata 保存配置与 provenance，不另存 result.json。可重复使用的 features.sqlite 属于试验工作缓存，不是最终结果文件。原视频、boutlist、原 raw、既有审阅 SQLite 保持不变。

常驻回放进程复用 raw 输入和与关联参数无关的图像特征。每次试验都重置身份状态；不会复用旧参数算出的轨迹。解码缓存有限容量，不能保证长窗口即时完成。

最终审阅或导出前，请用 Full replay 并自行检查身份连续性。仅看框平滑、ID 总数减少，不能证明关联正确。


## 4.9 参数分组与验证

模型的 Conf floor 决定 raw 包含的候选下限。Conf main 和 Dual confidence 决定回放如何使用已有候选；Low Conf Max Seconds 限制仅靠低置信度观测的连续支撑时间。前者变低时通常需要新推理，后者可在缓存包含相应观测时直接回放。

表格显示模块开关和主要参数，英文参数说明读取当前预设 JSON 的 `tips` 字典。相应内容为空、缺失、格式不正确或读取失败时显示 `--`；修改预设文件后重新打开参数窗口读取。输入控件悬停仍只显示当前值。未显示的配置项仍保存在完整参数快照中。改变参数前记录 Current；用 Keep trial 留住已完成结果，按同一个原始观测对比不同试验。

**例：静止蜜蜂短时遮挡。** 固定 raw，先比较 Gap recovery 开关。恢复身份与生成占位框分开：需要保留身份但不猜测位置时，可保留恢复及身份记忆而关闭 Position hold 和 Gap interpolation。查看恢复处 R 标记和源观测，确认没有接到邻近蜜蜂。

**例：低置信度尾部。** 开启 Dual confidence 后，高阈值检测建立身份，处于两阈值之间的观测仅在类别、raw ID、几何及竞争条件允许时支撑已有身份；不会凭低置信点创建无限持续的新轨迹。超过 Low Conf Max Seconds 时停止这种延续，主检测出现后重新计时。

局部窗口中的 ID 编号不作为全片身份编号依据。最终参数必须 Full replay 后核对全片结果，再正式 Load result、审阅和保存。

## 4.10 模块开关补充说明

| 开关 | 作用及解释 |
| --- | --- |
| Dual confidence | 主、低置信观测分流；低置信观测不独立建立新身份 |
| Species rules | 使用蜜蜂/胡蜂等场景规则；通用场景应核对类别含义 |
| Drop relink | 针对跌落运动线索的恢复路径 |
| General relink | 普通重现关联路径；关闭不等于关闭其他恢复路径 |
| Duplicate suppression | 抑制重复候选，需检查近邻真实个体是否被误抑制 |
| Hornet occlusion | 胡蜂遮挡相关保护和恢复规则 |
| Dormant static relink | 利用长期静止历史重连短暂消失目标 |
| Capped interpolation | 按插值时间上限限制估计跨度 |
| Separate identity memory | 区分身份可恢复时间和输出占位位置的时间 |
| ROI similarity | 使用局部图像相似度辅助身份关联，增加图像处理工作 |
| Low conf hints | 用低置信线索辅助评分，区别于 Dual confidence 的直接支撑路径 |
| Global relink | 对多个待恢复目标进行全局竞争匹配 |
| Post ignore | 执行相应后处理排除规则 |
| Ghost rollback | 回退短促、与宿主高度重叠的疑似幽灵轨迹；需检查真实短轨迹 |

其余保护、位置保持、插值与观测保真开关见本册“身份连续性与几何位置控制”。开关之间存在前提关系：总恢复已关闭时，某个具体恢复路径打开也不能凭此跨缺失接续。

## 4.11 可见主要数值参数

| 参数 | 单位/控制内容 | 调大时主要影响 |
| --- | --- | --- |
| MAIN_DET_CONF_THRESHOLD | 0–1 主检测阈值 | 主观测更少，低置信支撑占比可能增加 |
| LOW_DET_CONF_THRESHOLD | 0–1 可用低阈值，必须不高于主阈值 | 排除更多低分候选 |
| LOW_CONF_MAX_SECONDS | 秒，低置信单独支撑上限 | 允许更长的低分延续 |
| MAX_LOST_SECONDS | 秒，普通丢失/占位相关窗口 | 更长保留，需检查拖影 |
| RETRIEVAL_WINDOW_SECONDS | 秒，检索重现候选窗口 | 更多历史候选和错误续接机会 |
| DORMANT_STATIC_SECONDS | 秒，静止身份记忆 | 保留更久，不等于每帧输出框 |
| HORNET_IDENTITY_MEMORY_SECONDS | 秒，胡蜂身份记忆 | 更长缺失后仍可能关联 |
| HORNET_POSITION_HOLD_SECONDS | 秒，胡蜂位置保持 | 增加估计占位，不提高图像实测量 |
| MAX_INTERP_SECONDS | 秒，普通补间跨度上限 | 更长缺口可产生估计行 |
| MAX_DROP_INTERP_SECONDS | 秒，跌落补间跨度上限 | 允许更长跌落桥接 |
| STATIC_MAX_DISPLACEMENT_FACTOR | 相对目标尺度的静止判据 | 更宽松地归为静止历史 |
| STATIC_RELINK_DIST_FACTOR | 相对尺度的静止重连距离 | 扩大候选范围，邻蜂歧义增加 |
| STABLE_MATCH_DIST_FACTOR | 相对尺度的稳定关联距离 | 接受更大位移 |
| STABLE_MATCH_IOU_MIN | 最小重叠约束 | 更严格要求重叠，快速目标可能断轨 |
| MATCH_COST_GATE | 关联代价门限 | 按当前代价定义放宽接受范围 |
| ASSIGNMENT_AMBIGUITY_MARGIN | 候选竞争差异要求 | 更严格地拒绝不明确对应 |
| ADJACENT_RESIDUAL_FACTOR | 相邻关联几何残差容许比例 | 容许更大残差，需检查串号 |

时间参数按当前视频 FPS 转换为帧相关窗口，实际边界还受模块开关、其他几何/类别门限和已确认状态限制。单个参数不是“漏检容忍度”的总开关。

完整 JSON 含有更多未在表格暴露的高级参数。编辑可见项不会丢失它们；更改高级值时应保留完整快照，并按同样的局部预览与全片重放流程验证。

## 4.12 对照实验实例

### 4.12.1 区分几何抖动与身份跳变

先固定所有关联门限，只比较 Preserve observed boxes。若抖动仍跟随 raw 框，问题主要来自上游几何；再收紧重连门限不能修复像素位置。若位置稳定但 ID 交换，应检查竞争和缺失恢复诊断。

### 4.12.2 静止蜂被另一只经过

保留一份 Current 为 Trial；分别比较 Guard missing owners、Clear raw aliases 和 Guard gap assignment。点击同一原始观测跟踪目标，检查原静止身份是否在旧位置压掉新观测、旧 raw 映射是否残留，以及恢复处 R 是否接错。比较结束后 Full replay 验证全片。

### 4.12.3 空缓存尾部

raw 只提交到第 8000 帧时，Full replay 只能处理已有范围。预览窗口越过尾部没有框并不代表模型在后半段全部漏检，应先检查缓存完成状态，再决定重新推理或仅分析已完成片段。

## 4.13 预设中的算法流程

每个预设 JSON 的 `pipeline` 描述三个执行序列：

| 序列 | 默认顺序 | 作用 |
| --- | --- | --- |
| frame | prepare → camera_motion → association → low_confidence → observed_rows → lost_tracks → publish | 每帧的候选准备、运动估计、身份关联、低置信延续、结果行、丢失维护和发布 |
| relink | hornet_resume → general_relink → drop_relink → static_relink | 未分配候选的恢复策略优先级；首个成功策略终止本次搜索 |
| finalize | trim_terminal → ghost_rollback → post_ignore → dedupe → first_last → sort | 全段末尾的尾部清理、回滚、后处理、去重、首尾标志与排序 |

frame 与 finalize 具有数据依赖，不能任意重排；缺失、重复、未知阶段或违反依赖时，加载配置会报错。relink 可以调整策略顺序，但仍受相应模块开关和分数/几何门限约束。所有算法共享当前视频的身份记忆。

**例：** general_relink 与 drop_relink 都能提出候选时，前者排在前面会优先采用前者；交换顺序可能改变身份恢复结果。应在相同 raw 缓存上进行对照测试，核查实际输出再选择配置。现有预设保持原先的计算顺序。
