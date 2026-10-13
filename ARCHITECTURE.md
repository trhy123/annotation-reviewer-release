# Annotation Reviewer：开发与修改导航

## 1. 阅读入口与项目边界

本文面向维护者和 AI Agent，描述代码职责、数据契约、修改入口与验证方法。用户操作规程从 [操作手册](docs/00_操作手册.md) 阅读；不要把开发历史、讨论回复或尚未实施的方案写入正式手册。

本项目是 Python/PySide6 桌面程序。UI 英文，用户手册中文。源码通过包导入组织，不保留根目录旧模块转发文件。修改导入位置时，应同步内部调用、进程入口、测试和打包资源；不得把 Python 导入路径替换规则应用到 CSV 字段或 settings.ini 键名。

## 2. 启动、进程与发布目录

### 2.1 实际入口

| 入口 | 职责 |
| --- | --- |
| `python -m app.launch` | 调用 `main()`，创建 QApplication、MainWindow，进入 Qt 事件循环 |
| `start_annotation_reviewer.bat` | 切换到项目根目录并启动上述模块；优先 PATH 中的 pythonw |
| `ui/window.py::MainWindow` | 持有窗口状态，装配页面和控制器，管理生命周期 |
| `detection/detection_worker.py` | 独立检测进程，包含设备探测、推理、缓存/重放和 ROI 服务入口 |
| `packaging/build_release.py` | 从真实入口构建 GUI 与 DetectionWorker，组装媒体资源和配置 |

`app/constants.py::application_title()` 统一窗口基本标题。源码实例用 `os.getpid()` 标识；载入文件和 dirty 状态由 `ui/operations/file.py::update_window_title()` 追加。窗口标题不可用来决定数据身份或业务模式。

`__init__.py` 声明普通 Python 包，可以只有包说明。不要将其误判为旧入口残留。跨进程任务入口必须能由稳定的包路径导入，不能依赖主窗口实例或动态执行源代码。

### 2.2 路径与共享资源

- 源码设置根由 `app/config.py` 的应用目录解析确定，`settings.ini` 为现行设置文件。
- 源码预设在根目录 `presets_detection/`。算法默认值与类型 schema 位于 `presets_detection/postprocess_schema.json`，GUI 与 Worker 共用外置文件，不列入预设菜单。
- 发布套件只有一份根目录 `presets_detection/`。`detection_config.presets_directory()` 从 GUI、DetectionWorker 或 macOS 应用路径解析到同一套件根。
- schema 与用户可调整预设均为套件根 `presets_detection/` 资源。不要重新把 GUI 与 Worker 的预设各复制一份到其 `_internal`。
- Windows/Linux 的 Worker 位于套件 `DetectionWorker/`；macOS GUI 可位于 `.app/Contents/MacOS`。路径修改必须测试这些结构。
- 模型、媒体工具、输出和缓存路径通过现有配置解析；不能随某个模块移动而改用该模块目录作为全局根。

## 3. 修改入口索引

| 修改目标 | 首先阅读 | 关联代码 |
| --- | --- | --- |
| 窗口装配/共享状态 | `ui/window.py` | `app/launch.py`, `ui/widgets.py` |
| 播放区域/手势 | `ui/video_area.py`, `ui/video_canvas.py` | `ui/input.py`, `ui/selection.py` |
| 底部播放控制 | `ui/transport.py` | `ui/playback.py` |
| 帧号、seek、进度条与条带 | `ui/timeline.py`, `ui/timeline_widgets.py` | `media/video_timeline.py`, `media/video_pts_index.py` |
| 右上信息栏 | `ui/info.py` | `ui/operations/metadata.py` |
| Current frame/IDs/Selected ID | `ui/data/current_frame.py`, `ids.py`, `selected_id.py` | `ui/tables.py`, `ui/selection.py` |
| Manual traj/Binding 表 | `ui/data/manual.py`, `binding.py` | `ui/operations/binding.py`, `binding_actions.py` |
| Box/ID/Swap/Interpolate | `ui/operations/edit.py`, `interpolate.py` | `core/reviewer_core.py` |
| Tracking 页面与控制 | `ui/operations/tracking.py`, `ui/tracking_controller.py` | `tracking/` |
| Trajectory 页面 | `ui/operations/trajectory.py` | `tracking/trajectory_edit.py`, `trajectory_worker.py` |
| Detection 页面/参数窗口 | `ui/operations/detection.py`, `ui/detection_controller.py`, `ui/detection_dialogs.py` | `detection/detection_config.py` |
| 后处理试验 | `ui/postprocess_lab.py` | `detection/postprocess_lab.py` 及服务/评估模块 |
| Match 对齐与审阅 | `ui/operations/match.py`, `binding_actions.py` | `matching/manual_track_matching.py`, `manual_binding_model.py` |
| Camera | `ui/operations/camera.py` | `tracking/camera_tracking.py`, `ui/tracking_controller.py` |
| Scale | `ui/operations/scale.py` | `core/scale_calibration.py` |
| Points/Events/Boutlist 同步 | `ui/operations/metadata.py` | `app/config.py`, `core/boutlist_fields.py` |
| Boutlist 列名设置 | `ui/data/boutlist_fields.py` | `core/reviewer_core.py::read_boutlist` |
| Display/Profiler | `ui/data/display.py`, `ui/operations/profiler.py` | `rendering/`, `app/settings.py` |
| History/恢复 | `ui/data/history.py`, `ui/recovery.py` | `core/session_recovery.py` |
| 保存/导出 | `ui/operations/file.py`, `ui/file_dialogs.py`, `ui/export_window.py` | `workers/annotation_save.py`, `core/annotation_store.py`, `workers/video_export.py` |
| 英文悬停文案 | `ui/help_text.py` | `ui/widgets.py`, `ui/detection_controller.py` 的内容提示 |

UI 页面通过普通 mixin 方法使用同一个 MainWindow 状态，不是彼此独立的窗口。移动方法前检查其 `self.*` 依赖和信号连接；不要为了拆分复制一套 Session、选择集合或撤销栈。

## 4. 依赖与线程边界

### 4.1 依赖方向

UI 调用 core、matching、tracking、media、rendering 和 workers。后台算法不能导入 MainWindow、页面类或 QWidget。后台任务使用 QtCore 信号并不意味着它属于 UI。

`workers/` 包含 SQLite 保存、视频导出、匹配和解码任务。输入应为快照或任务数据，输出通过已有信号/队列发布；不能从工作线程读取正在变化的控件值。

模型推理由独立 DetectionWorker 承载。GUI 不为读取模型信息或预览配置直接导入 torch/ultralytics。ROI Assist 与全视频检测需要遵循现有互斥/排队规则，避免无意中在同一设备加载多份模型。

### 4.2 Detection 后处理模块

`detection/detection_engine.py` 保留模型推理、解码、视频生命周期与结果输出；`detection/postprocess/` 按职责提供 appearance、filtering、confidence、motion、identity、relink、occlusion、interpolation、cleanup 算法 mixin。它们共享一个 BeeBehaviorAnalyzer 的轨迹状态，不建立独立状态副本，也不反向导入引擎。geometry 提供无状态框几何计算。

pipeline.py 使用单帧 FrameContext 调度各阶段，阶段输出供后续阶段使用。`presets_detection/*.json` 的 pipeline.frame/relink/finalize 保存顺序，并写入有效配置快照。frame/finalize 的依赖顺序必须保持；relink 可排列恢复策略优先级。新增阶段须同步注册、依赖校验、预设与测试。参数及功能开关仍由配置控制。

调整算法后运行生命周期、双置信度、raw cache replay、后处理试验、历史输出对照测试。Worker 来源哈希包含 postprocess 下的源码。GUI 只导入轻量 pipeline 配置校验，不因参数窗口加载模型。

### 4.3 异步结果的有效性

Tracking、精确 seek、后处理试验等任务带有世代、帧或会话身份。用户切帧、手动修正、换视频、改变模板/参数后，旧结果必须被拒绝，不得覆盖新状态。

取消通常是请求取消及忽略迟到结果；不能假设按钮返回时底层工作已立即停止。关闭窗口应保留原有清理顺序和进程退出处理。

## 5. 数据状态与事务

### 5.1 会话数据

`core/reviewer_core.py` 管理源标注、工作数据与 EditCommand。源行、人工输入、匹配候选、绑定最终行、待提交 Tracking buffer 是不同层。刷新显示不能隐式把预览写入正式工作表。

ID 与来源 UID 有不同作用：ID 是对象身份，来源 UID 用来追踪具体源行的消费/恢复。Match 解绑、重绑定与冲突判断不能仅依赖数值 ID。

### 5.2 浏览记录

`ui/browse_history.py` 维护当前视频的帧位置和对象选择两套瞬时记录。人工导航入口用 `browse_navigation`，对象选择入口用 `browse_selection`；播放显示不入栈，内部撤销定位用 `browse=False`。恢复期间使用抑制守卫，避免重复入栈。进度条按一次拖动记账，连续步进按 500 ms 合并。索引完成时协调图片引用，具体人工点保留对应图片身份；整条人工轨迹仅存轨迹名。不能把浏览操作加入 Session.commands。

### 5.3 三层撤销

1. TrackingBuffer、Trajectory 和 Continuous 在提交前使用轻量局部历史。
2. Finish/Apply 将一组修改提交为相应 EditCommand/History 事务。
3. 磁盘 SQLite/恢复快照由独立保存任务写入。

逐帧追踪不能每次深拷贝整个 Session 或写完整 History 快照。修改回放/撤销时同时测试新建、覆盖、单点删除、范围删除、Redo 和取消。

### 5.4 元数据契约

`info_points`、`info_events`、`scale_calibration`、Camera 数据、手工绑定数据和位置来源是文件契约，不是 Python 模块名称。事件使用统一起止帧结构；点事件 start=end。

完整 Scale JSON 写入结果数据库 metadata；Boutlist 可按映射保存简短尺度摘要和完整 JSON，两者独立启用，只更新用户确认的当前行。`core/boutlist_fields.py` 负责规范字段到实际列名的映射；读取和写入必须使用同一映射，空映射停用，重复目标列拒绝。

### 5.5 Boutlist 编辑

`ui/boutlist_dialog.py` 提供非模态 Select bout，`core/boutlist_edit.py` 提供原始文本单元格事务和每文件的独立 Undo/Redo。主窗口持有编辑器，关闭对话框或切换 Bout 不销毁撤销记录；退出程序不持久化。直接单元格编辑不走规范字段映射或标注 History。成功的程序内元数据回写须通知编辑器刷新；其他外部变更通过内容版本检查拒绝覆盖，显式刷新后清除过期记录。调整快捷键时同时检查主窗口、独立对话框和单元格编辑器的焦点优先级。

### 5.6 Display 设置事务

`display_settings_values()` 收集界面草稿，`display_settings_group()` 定义持久化键所属分组。启动时保存有效值快照；恢复相同值后不再标记未保存。Save settings 只写选中范围，成功后更新该范围快照。Boutlist 列名只在写入成功后替换 `_boutlist_field_mapping`；数据读写不可直接读取列名输入框。

BoutSelect 显示 `BoutlistEditor` 读取的原始列名、顺序和单元格文本；打开 Bout 与元数据同步另经 `read_boutlist()` 和 `canonical_columns()` 生成内部视图，消费映射列而不保留重复别名。显示不能直接使用内部视图。Boutlist 读入冲突及双向同步统一使用 `boutlist_values_equal()`；整数身份/帧号精确比较，浮点允许序列化误差，JSON 递归比较。文件自身的 `annotation_metadata` 与推断 Boutlist 元数据分开，空 SQLite 也须保留文件元数据参与比较。简单比例不得取代结构化标定；有效完整标定可整体选择，比例与标定同步为一组。

### 5.7 关联文件打开

标注→视频自动关联由 `core/annotation_links.py` 解析容器无关的来源字典，`ui/operations/file.py::auto_open_annotation_video` 负责读取当前标注/Boutlist 来源和候选选择。新存储格式应提供来源字典并复用该入口，不能在解析器里假定所有 SQLite 都是审阅标注。现有 SQLite raw cache 继续使用专用预览入口。

### 5.8 数据结果保存

`core/annotation_store.py` 定义带 application_id 与 schema version 的结果库；不要仅凭 `.sqlite` 后缀把结果库当作 raw 缓存。`AnnotationSession.load_csv()` 保留内部入口名称，按格式读取旧 CSV 或 reviewed_detections 到同一 DataFrame。该名称及 session.csv_path 不作为磁盘格式判断依据；恢复 pickle 和编辑算法沿用原契约。

每视频一个结果库，内含 frames/raw_detections、raw_metadata、reviewed_detections、raw_sources、metadata、events、history、history_commands、manual_edits 和 save_transactions。raw_sources 只记录来源，不承担外部依赖。metadata 的 raw_storage=embedded 时，载入器将 raw_cache 解析为当前库路径，不能持久化对自身文件名的依赖。稳定 `_review_uid` 必须持久化，不能在每次载入时重建。首行 compact JSON 在磁盘提升到 metadata，载入时重构同名内存列以复用现有控件与算法；空工作表也必须保存元数据。

ResultStore 使用单写者 WAL/FULL 事务。普通 Save 通过 Session 的 UID 变更记录冻结新增/修改行与删除 UID，`save_delta()` 仅读取和更新这些行，同时提交 metadata/events/history 与增删改审计；成功仅清理该保存版本的变更，保留后台保存期间的新编辑。加载行与 save_revision 来自同一读事务，保存拒绝覆盖其他实例提交的新版本；文档加载世代保护旧保存任务不会改写新文档的路径。所有 schema/行/审计修改同一事务回滚，关闭写连接时 checkpoint；只读连接不得忽略活跃 WAL。

首次导入、另存新文件、Undo/Redo 重建、Camera 全表变化和未跟踪的外部物化修改使用完整比较回退。未变化的命令归档不重复复制或编码；变化的 History payload 仍可能较大，不能宣称整个保存过程严格只与脏行数有关。重开后的 history_commands 保持只读。现有内容寻址 pickle 恢复机制保留，恢复后首次保存使用完整比较。

Save/Ctrl+S 写回当前 SQLite；CSV 输入首次保存需要选择 SQLite。Save as/Ctrl+Shift+S 默认名带日期时间，可选择新 SQLite 或 Legacy CSV；Save 默认名不追加时间。CSV 仅作兼容导出，不切换当前工作库、不清除脏状态、不回写 boutlist detection_file。CSV 输出公开字段、首行 compact JSON、metadata.json 与只读 edit_log，不带 raw/命令归档/行审计。区间导出设置只在 Save as 生效，不能覆盖当前完整库或其他已有项目文件。source_annotation_path 保留每行来源，旧库首次保存允许全量升级该字段。人工新增/插值行不继承模板 raw 行引用；绑定对齐改变结果帧时用 raw_frame 保留原始观测帧。不同 raw_source_id 的项目不允许追加，防止外来 raw ordinal 误指当前 raw；没有可验证 raw 身份的旧 CSV 追加保留 legacy_raw_det_index/legacy_raw_frame 诊断，但不建立当前 raw 行关联。额外列名不能仅大小写不同，保存会明确拒绝并保持原库。

DetectionWorker 与批量入口使用同一个数据库连接写 raw 与 reviewed；raw_metadata 的 state 描述推理缓存，metadata 的 state 描述处理结果。先提交 raw 批次，再提交引用该批次的工作行；允许中断时 raw 比 reviewed 超前，不允许 reviewed 引用未提交 raw。Raw only 使用同样的工程格式，has_reviewed=false 时走只读 raw 预览；正常打开 reviewed 不可切换为 raw 预览。暂停/中断先提交 pending rows 再发布事件，最终清理以一个结果事务替换被修正行。raw_det_index 与 frame 对应 raw 中的 det_index；插值/人工新增不伪造 raw 来源索引。GUI 通过 prepare_save 冻结所需行，AnnotationSaveWorker 在后台线程写出，维持当前 snapshotReady 协议。命令参数含 DataFrame、数组、整数键和元组时使用 JSON 类型编码，禁止将 pickle 作为 SQLite 的载入协议。history_commands 归档参数及撤销状态，不重新注入当前撤销栈。另存新文件通过 SQLite backup 继承 raw 和审计记录后同步工作表；旧独立 raw 导入只复制一次，事务失败不得留下半份 raw。CSV 保留为兼容输入/导出，Boutlist 和外部人工轨迹格式不在结果格式迁移范围。检测启动配置及控制文件位于系统临时目录，结果配置存储于库内 metadata。

## 6. 帧身份与时间轴

### 6.1 编号的权威来源

识别、标注使用真实解码图片顺序，从 1 连续编号。容器 PTS 不是 `frame/FPS` 的必然等价物。PTS 缺口不能被扩展成不存在的图片。

`VideoPtsIndex` 管理图片时间戳索引；`VideoTimeline`、`PictureMapper` 和 picture refs 支持索引建立期间的新编辑身份确认。索引完成后的协调涉及 Session、撤销/重做、Tracking 缓冲、模板、Trajectory、Camera 和人工输入。

不得在索引发布时猜测重排原 CSV。只对记录了可核验图片身份的新编辑按原有映射机制处理。不能解析的身份通过 `UnresolvedPicture` 等现有状态阻止最终写出，而不是取最近时间凑合。

### 6.2 播放与暂停定位

播放路径与精确暂停 seek 使用不同调度。暂停定位必须在图片与目标身份匹配后发布显示，不能先更新 Overlay 帧号，再继续显示旧图片。

mpv 的 time-pos 需要正确时间原点和图片索引映射；任何秒数换算修改都要回归 PTS 间隔、非零起始时间、前后 seek、反向播放及保存后重开。

## 7. 坐标链

| 空间 | 内容 |
| --- | --- |
| Source | 每帧原始图像坐标，标注中心和框尺寸的基础单位 |
| Camera/expanded canvas | 用相机运动变换得到的稳定参考画布 |
| Widget/display | 加上视图缩放、平移后的屏幕坐标 |
| Metric | Scale 模型给出的厘米度量 |

画布点选必须沿显示映射的逆向回到正确原图位置。Tracking 模板匹配在原始图片上进行；稳定画面不能被当作另一份未补偿原始输入重复补偿。

Scale 保存 `source` 或 `camera_canvas` 空间及原始约束。缺少必要 Camera 变换时不能静默改换标定空间。Hive/Axis 原点与 Scale 度量分离；代表性 scale_px_per_cm 不能替代完整可变标定。

## 8. Tracking、Trajectory 与 Camera 的协作

### 8.1 Tracking

`tracking_models.py` 定义设置与缓冲，`tracking_matcher.py` 执行模板匹配，`tracking_predictor.py` 提供搜索预测，`tracking_worker.py` 管理任务。UI controller 决定交互、接受/拒绝、节奏与提交。

多个模板可独立并行评分，但帧间预测和模板 Evolution 按顺序更新。仅获胜且被接受的模板演化；拒绝结果不能污染原模板、位置预测和缓冲。Tether 引用原始模板，姿态搜索以原始模板为基准，不能逐帧累计缩放/角度。

Mark offset 在模板坐标中定义，随已识别姿态转换为最终标注位置。Assist 必须保持人工/自动指定点在可接受局部框内，受中心与尺寸边界保护。迟到 Assist 结果必须同时通过会话和帧版本检查。

### 8.2 Trajectory

五个工具为 Edit、Draw、Smooth、Redistribute、Transform。预览算法与画布控件分开；结果必须保留原帧顺序，缺失填充由显式选项决定。重新分配曲线上点的位置会改变速度解释，不能仅作为显示效果处理。

曲线/平滑后台计算完成后仍要核对预览世代。Apply 一次提交整段，Discard 恢复进入预览前状态。手柄拖动和参数变化不能抢先创建多条完整 Session 历史。

### 8.3 Camera anchor

Camera anchor 追踪复用模板引擎，但目标是锚点槽而非物体 ID。提交进入 Camera 状态/History，不写成普通对象标注。槽数量、原有其他槽和范围外帧必须保留；不要把 Class、对象 Assist 或普通对象 Alt 添加混入锚点会话。

## 9. Detection 与 Match 的边界

### 9.1 推理与重放

Raw 缓存是已完成上游筛选的观测，不是原始网络张量。Conf floor、NMS、模型等改变需要重新推理才能获得原来不存在的候选。Conf main 和后处理模块使用已缓存候选可重放。

后处理试验区分 Current 草稿、Reference 副本和 Showing 结果；不能用正在计算的新草稿冒充画面当前结果。Trial 按同一个原始观测锚点跨方案比较，不能把不同方案相同 stable ID 当成同一对象。

### 9.2 Match

候选计算与身份确认分开。Binding 行的 frame snapshot 是精确动作输入，Link selection 不得扩大表格行的帧范围。低帧率 resolution gap 与真实 GAP 分开处理。

位置策略 Detected/Mix/Manual 与身份策略分别维护。Mix 是明确的位置折中，Transition 处理来源交接，不是全局最优平滑。更改绑定应回归源行消费、解绑恢复、类别冲突、同帧唯一性及 Finalize 审核阻塞。

## 10. Overlay 与性能

`rendering/overlay_data_store.py`、`overlay_scheduler.py`、`trail_overlay_store.py` 管理绘制数据与缓存；Qt raster、保留式 OpenGL 和可选 trail shader 是不同路径。导出有独立组合/编码任务。

shader 以图片年龄计算渐变样式；不适用时说明回退，不偷偷改变轨迹。少量 Tracking 交互框仍由 Qt 绘制。避免逐帧扫描全部累积缓冲、重建全量 DataFrame 或无界缓存。

侧栏派生查询使用 `session.navigation_revision` 区分数据代次；它包含工作表身份、保存修改代次和索引重建代次。轨迹帧号、摘要与帧边界的有界缓存不进入 Session 的复制或恢复文件。当前行坐标仍即时读取；自动 Selected ID 表额外检查 Continuous 两个局部撤销栈的变化，切帧只更新焦点。未提升数据代次而原地更新展示列的通路，须像 Compact metadata/Camera 保存同步一样清除表格内容缓存。人工轨迹、Binding 与 Tracking 待提交内容分别遵循各自的更新来源，不能只用 Session 代次判断。轨迹点选缓存还必须区分前后轨迹归属、可见窗口及屏幕变换；画布矩形缓存依赖图片尺寸、控件尺寸、缩放和平移。

验证性能时固定视频、帧区间、模板、显示内容和速度上限。分清初始化、解码、匹配、数据包准备、绘制、编码及写盘耗时。offscreen 测试不能证明真实 GPU/驱动路径可用。

## 11. 文案、提示与手册维护

通用说明性 tooltip 和动态提示模板集中在 `ui/help_text.py`，页面使用 `help_message()` 和 `set_help()` 引用。预设专属参数说明保留在 `presets_detection/*.json` 的 `tips` 字典中，由 `detection.detection_config.preset_tip()` 读取；缺失、空白、类型无效或文件读取失败时显示 `--`，不使用内置解释替代。输入内容 tooltip 可在控件内部直接更新。

规则：标签解释含义，输入框/下拉框只显示当前内容，按钮/复选框解释动作；表格参数名解释参数，数值单元格显示值。`bind_label_help()` 只绑定现有相邻控件，不改变布局；特殊布局应显式绑定。状态原文、异常详情、文件路径等内容提示可复用对应内容，不再复制一份固定说明。

新增文案应使用稳定语义键，动态值用命名占位符，保留统一翻译入口。UI 标签/对象 ID/配置键不要互相借用作为业务判断条件。暂不引入完整多语言框架。

新增设置时同步：语义说明、值的单位与范围、生效时点、保存位置、所属手册、测试。手册文件按 00–15 编号，内部使用章节号和多级大纲；删除旧文件后更新所有链接，不保留重复版本入口。

各章节手册文件可一键合并：运行 `python docs/build_manual.py` 能够将 `docs/00_*.md` 至连续编号的最后一章合并到 `docs/AnnotationReviewer操作手册.md`。支持 `--docs`、`--output`。脚本校验文件/标题编号和链接，按当前完整标题生成 GitHub 风格锚点并重写跨文件链接；复制相对资源，保留代码区内容。生成文件不作为编辑源稿。

## 12. 验证矩阵与运行命令

### 12.1 最小检查

从项目根目录、具备依赖的环境运行：

```text
python -m compileall -q app core ui workers media rendering matching tracking detection
python -m app.launch --smoke-test
python -m unittest discover -s tests -v
python detection/detection_worker.py --probe-device --device cpu
```

`--smoke-test` 验证入口导入，不等于打开真实视频完成全部操作。无显示环境可使用 `QT_QPA_PLATFORM=offscreen`；不要据此声称验证了 OpenGL/mpv 驱动。

部分历史对照测试依赖当前 Git 仓库中的参考提交；复制源树到临时目录测试时，需提供只读 Git 上下文或明确报告其不可执行。真实模型/视频回归需要相应素材与显式运行条件；跳过必须报告，不能算作通过。

### 12.2 按变更选择检查

| 修改 | 必要检查 |
| --- | --- |
| 启动/资源 | source PID、GUI 启动、Worker probe、Windows/Linux/macOS 套件路径、实际打包 smoke |
| Tooltip/UI | 标签语义、数值变化后的内容 tip、动态窗口、无滚轮误改、固定高度/宽度 |
| 时间轴/解码 | PTS 缺口、非零时间原点、逐帧/拖动/播放一致、映射等待与保存 |
| Tracking/Trajectory | 人工接管、覆盖、单点/范围删除、局部 Undo/Redo、取消/提交、迟到结果 |
| Match | 行范围精确性、source UID、类别保护、绑定/解绑、审阅和数据回放 |
| Scale/Camera | 原图/稳定画布转换、约束求解、保存重开、History、导出 |
| Boutlist/保存 | 自定义列映射、空字段、重复列、前导零/未修改文本、完整 Scale 输出边界 |
| 文档 | 链接、编号、控件名称、默认值、实际状态转换与至少一个完整操作实例 |

`tests/test_help_and_resources.py` 覆盖本项目的标题、共用预设路径、提示规则和集中化约束；`tests/test_module_boundaries.py` 检查后台导入边界。更改实际行为后更新相应测试，不要通过移除断言掩盖行为退化。

## 13. 修改纪律

检查工作树和现有用户改动后再修改；先说明作用边界。涉及文件迁移时用具体清单和备份，验证内部引用与打包资源后移除旧文件。不要删除项目外参考笔记或数据，不自动同步远端。

文档以当前代码和验证行为为准。旧设计笔记可提供例子与原理，但其中未实现的建议、旧按钮名、历史问题回答不能直接作为现行功能说明。
