# 11 Points 与 Events 操作说明

[返回总目录](00_操作手册.md)

## 11.1 记录目的与存储

Points 记录分析边界、捕获参考帧、主体身份、巢门口和审阅备注；Events 记录行为或数据质量事件区间。它们是人工采集信息，不由轨迹自动推断实验结论。

保存标注 SQLite 时，基础信息写入 `info_points`，事件写入 `info_events`。基础字段可按映射同步到 Boutlist；事件区间不因 Sync to 自动逐项展开为 Boutlist 列。完整标尺另存于 `scale_calibration`。

## 11.2 Points 的 Set 与 Goto

| 按钮 | set point | goto point |
| --- | --- | --- |
| Start | 将当前帧设为分析开始 | 定位已存开始帧 |
| End | 将当前帧设为分析结束 | 定位已存结束帧 |
| Capture | 将当前帧设为捕获参考帧 | 定位捕获参考帧 |
| Hive | 进入巢门口位置点选 | 查看已记录参考位置 |
| Captor | 点选得手胡蜂框，记录其 ID | 选中该 ID，必要时定位其最近存在帧 |
| Victim | 点选被捕蜜蜂框，记录其 ID | 选中该 ID，必要时定位其最近存在帧 |

`set point` 和 `goto point` 为互斥模式。同一个按钮在两种模式下作用不同，操作前先核对当前模式。

Start、End、Capture 的 Confirm edit 窗口中，Yes 设置当前帧，Clear 清除对应字段，No 放弃；修改与清除均可通过主 History 撤销。提交修改或清空 Start、End、Capture、Hive、Captor、Victim 时，检查已启用映射的 Boutlist 字段；存在差异时询问是否同步，确认清空则写入空单元格，拒绝同步不回滚程序内的编辑。清除 End 后分析范围仍可按已有 Capture 或视频边界采用缺省终点，应区分显式记录与范围计算的缺省值。

Hive、Captor、Victim 使用待提交选择。点击按钮进入选择状态，按钮保持按下；在画面内选择 Hive 坐标或正确对象框，按钮文字显示候选值；点击画面以外的主窗口其他位置清空候选，按钮文字显示空值；再次点击同一按钮提交，Esc 放弃候选。除同一提交按钮外的窗口区域均可用于清空候选，原数据在提交前保留。Hive 不再使用画面外位置设置坐标。

进入 Hive 设置后，首次画面点选前坐标轴预览随鼠标移动；点击后预览固定在候选原点，直至重新点选、提交或取消。仅载入视频而没有标注时也可使用该预览。预览使用当前 Axis 外观与 Camera 坐标变换，不改变 Axis 显示开关，也不提前写入 Hive 数据。

在进度条下方标记区点击 Start、End 符号正下方与 Capture 箭头同高的位置，也可定位到对应帧。定位到已经设置的 Start、End 或 Capture 帧时，画面左下角按 Events 的 HUD 样式显示相应文字。同一帧兼有多个标记或事件时，标签同时显示。播放预览与启用 HUD 的视频导出使用一致的标签规则。

另设有 Notes 输入框用于记录影响理解和分析的简短事实，例如遮挡不确定性或特殊片段条件。

Points 第三行的 `Save only the target segment` 控制 Save 与 Save as 是否仅保存 Start–End 内的最终标注，包含两端；不删除范围外内存数据。该选项为当前会话的保存范围选择，不作为配置项写入 INI，关闭或更换文件时复位。

## 11.3 各信息字段的含义

| 字段 | 定义 |
| --- | --- |
| analysis_start_frame | 本次捕获关联互动纳入分析的第一帧 |
| analysis_end_frame | 纳入分析的最后一帧；应与分析目的和 Capture 核对 |
| capture_frame | 得手胡蜂首次实际接触被捕蜜蜂，并连续导致成功控制和带走的第一帧 |
| captor_id_at_capture | 已核对的得手胡蜂身份 |
| victim_id_at_capture | 已核对的被捕蜜蜂身份 |
| hive_x_px / hive_y_px | 巢门口参考坐标；Camera 模式下应核对所属坐标空间 |
| left_censored | 真正互动起点早于可用分析画面，不能完整观察起点 |
| verified_capture_pair | 已核验得手胡蜂与被捕蜜蜂全过程的身份和轨迹 |
| verified_exposed_bees | 已重点检查低位、外围、孤立蜜蜂的漏检、重复和漂移 |
| verified_other_hornets | 已检查其他胡蜂逐帧存在情况及同类干扰事件 |
| review_notes | 自由文本审阅备注 |

用于记录互动过程是否完整的左删失标记 `left_censored` 由人工判断并指定，互动起点完整则记为 false；不会根据自动检测的第一帧、胡蜂进入方向或画面边缘位置自动推断。如果能观察到实际互动的起点，应设置 Start 并记为 false （不勾选）；若开始时互动已进行，则记为 true （勾选）。分析起点的状态只是该时刻已存在的状态，不能直接将完整的互动起点称为未受干扰的“清洁基线”。

## 11.4 Points 标准操作规程

1. 先校正关键主体的身份与轨迹。
2. 切换 set point，定位互动开始帧并点 Start。
3. 定位成功捕获过程，逐帧确定 Capture；按分析范围设置 End。
4. 分别点 Captor、Victim，在画布选正确框后，再点同一按钮提交。
5. 点 Hive，在画面指定巢门口参考位置，再点 Hive 提交。需要清除时，进入对应选择状态、点击画面外主窗口区域，再点原按钮提交。
6. 切回 goto point，逐项点击验证记录正确。
7. 需要时填写 Notes，并同步 Boutlist，最后保存标注文件。

**例：视频开始时胡蜂已持续施压。** Start 使用实际可用分析起点，核验窗口勾选起点左截断；不要虚构一个画面外起点。Capture 仍按真实成功接触帧记录。

## 11.5 Events 类型

### 11.5.1 默认研究类型

以下为平台设置模板提供的默认类型，实际类型以 settings.ini 和 Types 设置表为准。

| 显示/存储类型 | 标注判据 | 不应据此标注的情况 |
| --- | --- | --- |
| conspecific_interference | 得手胡蜂暂停蜜蜂导向活动，转而追逐、回避、驱赶其他胡蜂 | 仅同框出现 |
| noncaptor_engagement | 非得手胡蜂主动接近、悬停、往复或向蜜蜂群施压 | 单纯飞过而无相关活动 |
| bee_slip | 蜜蜂突然向下移动，形成新的低位/孤立机会 | 仅检测框抖动 |
| loss_or_blur | 严重运动模糊、遮挡或群体检测坍缩，使空间点集明显不可靠 | 个别轻微漏检 |

bee_slip 记录事件时间，不要求确定蜜蜂长期 ID。事件不自动划分诱导型等最终研究分类；这些结论应由后续分析结合客观轨迹推导。

### 11.5.2 配置类型

1. 在 Edit → Events 点击 Types，打开非模态类型表。
2. Add 新建定义，Delete 移除选中定义；Up／Down 上移或下移选中定义，调整下拉列表顺序。Internal key 是稳定存储标识，只能以字母开头并包含字母、数字和下划线，不能重复。
3. Enabled 控制该类型是否可新增及是否显示其 HUD／条带；Name 控制下拉框、事件表和 HUD 中的名称。双击 Color 选择颜色，表格以十六进制颜色代码 `#RRGGBB` 保存，应用于事件表和条带。
4. Band 为 0 时隐藏该类型条带；1、2、3 分别使用进度条下方的三个条带行。条带隐藏不删除事件，也不禁止 HUD 显示。
5. 有效修改即时预览名称、颜色和条带。Close 接受修改并供本次运行使用，不写入 INI；Cancel 或窗口 × 放弃本次打开后的修改并恢复原显示。点击 Save settings，或在 Display 的保存范围选择 Event types／All 后保存，才供后续运行使用；保存成功后，Cancel 只放弃此后未保存的修改。

修改名称和颜色不改变已存事件的内部标识或帧区间。停用、删除类型定义不删除已有事件。重新命名 Internal key 不会迁移原标识下的事件，应在事件表明确调整类型。未在本机配置的既有事件仍保留；结果文件中的类型定义可用于显示其名称与颜色。类型配置是程序设置，不属于标注 History；事件区间修改仍进入 History。

**例：** 新建 `camera_obstruction`，Name 为 `Camera obstruction`，颜色选择红色，Band 设为 3。保存 Event types 后，下拉框可以选择该类型并记录区间。将 Band 改为 0 并保存，仅隐藏条带；取消 Enabled 并保存后，该类型的 HUD 和条带均不显示，已有区间仍保存在结果中。

## 11.6 建立、修改与删除事件

### 11.6.1 建立区间

1. 在事件类型下拉框选择类型，清除已有事件选择。
2. 定位起始帧，点击 Start；新事件先以 start=end 建立并被选中。
3. 定位结束帧，点击 End；该事件更新为包含两端的区间，完成后清除选择。
4. 在表格点击事件检查范围；播放区间前后确认边界。

没有选中事件时点击 Start 或 End 都会以当前帧创建点事件。单帧事件使用 start=end，与区间共用结构，例如 `{"type":"bee_slip","start":2301,"end":2301}`。

同类干扰区间、其他胡蜂施压区间和 loss_or_blur 可以在时间上重叠；重叠表示不同事实同时成立，不应强制合并成一个排他分类。

### 11.6.2 修改既有事件

点击事件列选择它，改变类型下拉框可更新类型；定位新的边界帧后用 Start/End 更新所选事件。双击相应表格内容可编辑类型或范围。多个事件同时选中时，边界或类型修改可能作用于全部所选事件，执行前核对选择。

表格每个事件为一列；当前帧处于某区间时有相应强调。点击用于选择和定位，不能凭列位置推断事件优先级。Delete 删除选中的事件记录，不删除轨迹框或原视频。

## 11.7 Verify 与保存核验

Points 中位于 Victim 下方的 Verify 按钮和 Save / Save as 前的核验窗口记录独立的 bout 状态。窗口内项目勾选表示 true，未勾选表示 false；不要求为了允许保存而全部勾选。

Confirm 提交窗口中已显示项目的结果并继续相应流程；Back 放弃本次核验操作，在保存流程中会取消继续保存。未显示的项目保留当前 bout 中已有的值。

核验窗口不包含保存范围选项。默认焦点位于 Confirm，按空格可提交确认；此时不触发 Tracking 的空格快捷键。

Display → Boutlist fields 提供 Verify review status before saving 总开关。开启后每次 Save／Save as 均弹出一次；关闭文件时如选择保存，也经过同一保存核验流程，不另加一次关闭核验。关闭总开关后 Save／Save as 不自动弹出核验窗口，保留原有核验状态；仍可在 Points 点击 Verify 主动打开核验窗口。

总开关下方为可增删的核查定义表。表中开关是设置，不是当前 bout 的核查结果。

| 列 | 行为 |
| --- | --- |
| Internal field | 核查状态的稳定内部字段；字母开头，可含数字和下划线，不得重复或占用既有 Points 字段 |
| Enabled | 是否启用该项；停用后不询问、不同步，保留结果中已有状态 |
| Question | 核验窗口显示的英文问题文本 |
| Boutlist field | Boutlist 中对应的列名；空白不参与 Boutlist 读写 |
| Sync | 是否允许从 Boutlist 读取或向其同步；要求启用、列名非空且实际存在该列 |

使用 Add／Delete 增删定义，编辑单元格修改内容。通过 Save settings 的 Boutlist fields 或 All 范围保存并激活草稿。保存其他分组不应用本组修改。每项 Enabled 即表示在 Verify 中询问，不再设置单独的 Ask。所有项目均未启用时，Verify 为空，仅保留 Confirm／Back。核验窗口内确认的实际状态进入项目 History 和结果 SQLite；设置表修改不进入项目 History。删除或停用定义不清空已有状态，变更内部字段不自动迁移旧字段。

**例：** 新增 `identity_checked`，启用并填写问题，Sync 关闭。该问题会出现在 Verify，回答保存到结果 SQLite，但不询问 Boutlist 同步。之后在 Boutlist 增加 `identity_checked` 列，在配置表指定该列并开启 Sync，保存配置后方可同步。未指定 Boutlist field 时，Sync 灰显且自动取消勾选。未配置或缺失对应列时，不通过 Points JSON 间接改写该项。


### 11.7.1 核验建议

- Capture pair：检查整个分析范围的得手胡蜂和被捕蜜蜂，不只看捕获那一帧。
- Exposed bees：重点检查最容易影响低位/孤立机会统计的框。
- Other hornets：检查逐帧数量与位置，允许无关个体 ID 不连续，但不能因此忽略大量漏帧。
- Left censored：记录是否能观察互动真实起点，与“已经核验”不是同一种含义。

## 11.8 同步和验收

Sync from Boutlist / Sync to Boutlist 使用 Display 中配置的 Boutlist 字段映射；Hive 在 Boutlist 中按程序映射使用 nest 坐标列。同步前核对当前行，空白映射字段不读写。保存后重新载入，检查 Start/End/Capture、Captor/Victim、Hive、启用的核查状态、Notes 和事件区间。

Points 的 Boutlist 同步只处理已映射且实际存在的字段，未提供的列不会清除当前身份、核验或 Camera 状态。数值保存精度差异不作为冲突；已有完整 Scale 标定不会被简单 `scale_px_per_cm` 摘要替换。完整标定的来源选择见 [Scale](09_Scale操作说明.md#98-单值范围和完整输出)，字段和比较规则见 [Boutlist](13_Boutlist制作与使用.md#135-打开与同步规程)。
