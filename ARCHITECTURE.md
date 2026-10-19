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
| Filter/运动派生指标 | `ui/operations/filter.py`, `ui/filter_controller.py` | `core/annotation_filter.py`, `workers/filter_query.py` |
| 操作暂存 | `ui/operations/stash.py` | `core/operation_stash.py`, `ui/timeline.py` |
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

主操作区在 `ui/window.py::_build_command_panel` 使用原生 `QTabWidget` 和 `setFixedHeight`。高度唯一读取 `ui/command_panel_height`；默认值集中在 `app/config.py::DEFAULT_COMMAND_PANEL_HEIGHT`。不要恢复按页面 sizeHint 推算主操作区高度或另加 maximum-height 配置。

类别目录由 core/class_catalog.py 读取 INI 的 classes（模型编号到类别名）与 id_groups（按数字排序的类别组合）。具体类别仅在平台配置模板中定义；UI 动态建立 ID 分表及类别选项，未知/跨组身份进入 Other。Detection 和 ROI Worker 接收同一映射；raw 重放使用来源记录的映射及物种角色，不用当前 INI 重释已保存 raw。物种专用后处理的适用范围仍由预设决定。

ID 表 Ctrl+A 只作用于当前分表。超过 512 行的选择由 GUI 定时器分批收集，完成前不提交选择状态；Esc 恢复原选择，不取消 Tracking 或编辑。数据、筛选、排序、表格内容改变时废弃过期任务。ID 成员检查须一次取得已知 ID 集合，不得在每个 ID 的循环中复制全部集合。类别显示按数据修订缓存每个 ID 的单一/混合状态，展开列表只显示配置项，multiple 仅作本体提示。多来源 set_id 使用 track_ids 并在完整回放与增量索引中保持同一范围，避免为每个来源反复重建索引。

Display 的 review/verify_before_save 与 review/ask_<字段名> 属于 Boutlist fields 的 INI 偏好，review_prompt_checks 仅控制是否询问，不能修改项目 info_points 或进入 History。Verify 窗口只提交启用项目的实际 bout 状态，禁用项目保留原值；全部禁用时仅保留 Confirm/Back。保存范围为 Points 的 save_target_only_check，绑定会话级 save_target_only，不写 INI，换文件时复位。Verify review status 窗口的 Confirm 按钮保持默认焦点，Tracking 空格过滤不得消费独立对话框按键。

Tracking 的四个子页为 Track Motion、Templates、Weights、Advanced。空间不够时使用可滚动区域而不扩大主操作区。`tracking/tracking_candidates.py` 为普通及姿态模板共用候选生成和颜色描述，`tracking_engine.py` 区分位置接受与可选的模板更新门槛。候选／颜色设置改变后需使旧请求与权重标定证据失效，不能继续使用旧特征下的标定结果。

Detection 的 Monitor 入口在 Control/Inference 标签栏右侧。`ui/performance_monitor.py` 只负责非激活窗口与显示，`workers/performance_monitor.py` 在独立 QThread 采样 psutil、Windows GetPerformanceInfo 和有超时限制的 nvidia-smi；workers/windows_telemetry.py 用 DXGI 标识适配器，并经 PDH/WDDM 提供 GPU 分配与所属进程指标。硬件名称和数量运行时枚举；同型号多卡不能靠名称猜测映射。System/Reviewer 两列分开，Reviewer 只统计主进程与当前子进程；CPU 选择按系统拓扑和进程亲和性，GPU 支持全体、单卡和实际使用设备。关闭窗口暂停采样，Controller.close 终止线程；不得在 GUI 定时器内同步查询 GPU，不可把不支持的指标显示为零。模型元数据 QProcess 与正式 Detection 分开，按归一化 Path 校验选择、限制读取时长，且仅元数据进程禁用 CUDA。

## 4. 依赖与线程边界

### 4.1 依赖方向

Tracking 新会话由 OperationsTrackingMixin.prompt_tracking_setup 先确认身份、类别与初始框参数，Cancel 必须在暂停播放、提交 Continuous、创建 buffer 之前返回。同会话接管/恢复不重复提示；Curve/Camera 保持独立流程。TrackingController 的 template_bank 仅保留当前 Session/视频中的各目标模板，不持久化；Finish/Cancel 不清除模板，显式移除全部模板须同步删除缓存，换视频/Session 清空。时间轴协调须原子映射活动 engine 和缓存 engine，避免切回目标后出现旧帧号。

Tracking 的删除范围窗口仅在实际应用删除时创建 Delete buffer，已有 buffer 删除时保持原 mode。Auto 的人工接管尺寸与光标预览共用 manual_box_size，优先当前模板尺寸。失败恢复使用点击前的引擎快照匹配，两次沿追踪方向相邻、可靠且接近人工点的确认才恢复；Alt 接管等待松键，人工位置不被候选覆盖。Template/Search 按钮运行时可点，进入区域编辑先暂停并结束人工点选。Space 在 Tracking 页按 buffer 是否存在分派为追踪/播放，不能由该页按钮、复选框或下拉框抢占，也不能影响独立对话框。

Tracking ID 可空白，refresh_choices 不预分配；启动对话框接受空白，在确认 Start 后分配未用 ID，Cancel 不修改面板身份。search_offset 表示最新模板取样时 Search 中心减 Template 中心的原图像素偏移，人工修正和恢复不得清零。template_area_box 用于联动参考框的绘制与命中，不替代真实匹配框；Search 拖动复制引擎的可变位置/权重状态，避免修改在途请求，取消恢复原状态，且不生成标注。低分暂停时普通左键可人工指定；引导恢复须保留已切到但未标记的当前帧。

Selected ID 连续段缓存以 Session、navigation_revision、活动 ID、帧界限为键，跳转按钮复用段范围，不得每次重建全部帧集合。逐行 Video/video_path/video_name 不属于标注契约；载入、表格投影及输出均排除，项目级视频关联 metadata 保留。旧 SQLite 工作表的重复列在保存事务内移除并重建行摘要，不能把结构整理记录为逐行人工修改。

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

Filter 先按单条记录执行 Rows 条件，再按命中行汇总 IDs 条件。规则只允许受控运算符与 All/Any 组，不执行用户表达式。后台处理数据快照；查询结果由数据/查询世代校验，测量缓存不随播放帧变化。Continuous 暂存修改和局部撤销同样须失效查询快照，不能只依赖用于身份/帧索引的 navigation_revision 判断坐标是否变化。

Use matched rows 冻结稳定行 UID 与人工点三元身份；普通 ID/Range 不能扩大精确作用域。当前支持 Delete/Class，其他工具要求释放作用域。自动修改使用一个带 target_uids 的增量命令，核心 affected_index 直接查询 UID 索引，再与帧/可选身份限制取交集，完整回放 mask 使用同一交集。混合人工来源时，既有 manual_state_snapshot 连同 Session replay 状态形成一次撤销；_manual_history_owner 防止在 History 中重复显示内部命令，命令仍被归档。不得将筛选结果转换成 ID×Range 笛卡尔积。

Operation Stash 按视频在内存中保存草稿，不持久化、不入编辑 History。端点记录 PictureRef，在索引完成时原子协调；Use/Send 只恢复输入。QDialog 不可使用 window 作为实例属性遮蔽 QWidget.window()，全局输入过滤器依赖此方法。

暂存表以稳定草稿 key 定位，排序后的显示行号不能直接索引后端条目。New 建立当前帧草稿，Connect／Add point 修改选中草稿，并维护 last_frame 及相应画面引用。列宽使用 tables/operation_stash/column_widths，在隐藏窗口时保存。Filter 忽略完全空白的条件及空分组；未取得有效查询结果时显示原表，并禁用精确筛选编辑入口，不能把这些行当作有效命中集合。

### 5.4 元数据契约

`info_points`、`info_events`、`scale_calibration`、Camera 数据、手工绑定数据和位置来源是文件契约，不是 Python 模块名称。事件使用统一起止帧结构；点事件 start=end。

`set_window` 允许只提供 start_frame 或 end_frame；缺失表示保留原值，显式 None 表示清空。增量执行、完整回放、确认预览和 Boutlist 字段映射必须保持同一含义。点字段清空时，Boutlist 同步必须包含空值，不能因过滤 None 而跳过用户明确的清空。

完整 Scale JSON 写入结果数据库 metadata；Boutlist 可按映射保存简短尺度摘要和完整 JSON，两者独立启用，只更新用户确认的当前行。`core/boutlist_fields.py` 负责规范字段到实际列名的映射；读取和写入必须使用同一映射，空映射停用，重复目标列拒绝。

### 5.5 Boutlist 编辑

`ui/boutlist_dialog.py` 提供非模态 Select bout，`core/boutlist_edit.py` 提供原始文本单元格事务和每文件的独立 Undo/Redo。主窗口持有编辑器，关闭对话框或切换 Bout 不销毁撤销记录；退出程序不持久化。直接单元格编辑不走规范字段映射或标注 History。成功的程序内元数据回写须通知编辑器刷新；其他外部变更通过内容版本检查拒绝覆盖，显式刷新后清除过期记录。调整快捷键时同时检查主窗口、独立对话框和单元格编辑器的焦点优先级。

### 5.6 Display 设置事务

`display_settings_values()` 收集界面草稿，`display_settings_group()` 定义持久化键所属分组。启动时保存有效值快照；恢复相同值后不再标记未保存。Save settings 只写选中范围，成功后更新该范围快照。Boutlist 列名只在写入成功后替换 `_boutlist_field_mapping`；数据读写不可直接读取列名输入框。

BoutSelect 显示 `BoutlistEditor` 读取的原始列名、顺序和单元格文本；打开 Bout 与元数据同步另经 `read_boutlist()` 和 `canonical_columns()` 生成内部视图，消费映射列而不保留重复别名。显示不能直接使用内部视图。Boutlist 读入冲突及双向同步统一使用 `boutlist_values_equal()`；整数身份/帧号精确比较，浮点允许序列化误差，JSON 递归比较。文件自身的 `annotation_metadata` 与推断 Boutlist 元数据分开，空 SQLite 也须保留文件元数据参与比较。简单比例不得取代结构化标定；有效完整标定可整体选择，比例与标定同步为一组。

### 5.7 关联文件打开

标注→视频自动关联由 `core/annotation_links.py` 解析容器无关的来源字典，`ui/operations/file.py::auto_open_annotation_video` 负责读取当前标注/Boutlist 来源和候选选择。新存储格式应提供来源字典并复用该入口，不能在解析器里假定所有 SQLite 都是审阅标注。现有 SQLite raw cache 继续使用专用预览入口。

### 5.8 数据结果保存

`annotation_writer()` 对新文件及经验证无数据的失败空壳先在同目录暂存，提交并 checkpoint 后发布；已有正常库保持增量事务写入。发布不得覆盖保存过程中由其他实例新建的文件。`resolve_raw_source()` 优先使用项目内嵌 raw，再按记录路径及源标注同目录的同名文件查找，并核验来源身份。`OperationsFileMixin.prepare_save_raw_source()` 在 GUI 线程提供指定来源／不带 raw 保存／取消，决定只进入冻结快照，成功后再更新当前会话；Worker 不弹窗。没有 raw 的标注工程合法，明确舍弃状态使用 metadata.raw_storage=omitted，raw 表与引用清理属于同一保存事务，不能在 GUI 预检查时直接删库内数据。缺少列元数据的未提交空库应明确报错，不能生成空 SELECT 或当作有效空标注载入。

新目标发布不得创建或清理结果名的零字节占位：Windows 使用拒绝覆盖的 rename，POSIX 使用同目录排他 hard link，清理仅限本次 .ar-save 临时文件。正常关闭由 `finalize_result()` 尝试 checkpoint/DELETE 日志模式，忙或不可写时跳过；绝不手工 unlink 结果或活跃 WAL/SHM。关闭窗口前若已保存项目缺失，须保留内存数据并进入保存确认，不能因为 dirty 原先为 false 而直接退出。SessionRecoveryStore 删除入口只接受快照文件；目录清理仅限 sessions 的直接会话子目录，且遇到 SQLite 等非恢复文件必须保留，不得递归删除外部手动快照的父目录。

`core/annotation_store.py` 定义带 application_id 与 schema version 的结果库；不要仅凭 `.sqlite` 后缀把结果库当作 raw 缓存。`AnnotationSession.load_csv()` 保留内部入口名称，按格式读取旧 CSV 或 reviewed_detections 到同一 DataFrame。该名称及 session.csv_path 不作为磁盘格式判断依据；恢复 pickle 和编辑算法沿用原契约。

每视频一个结果库，内含 frames/raw_detections、raw_metadata、reviewed_detections、raw_sources、metadata、events、history、history_commands、manual_edits 和 save_transactions。raw_sources 只记录来源，不承担外部依赖。metadata 的 raw_storage=embedded 时，载入器将 raw_cache 解析为当前库路径，不能持久化对自身文件名的依赖。稳定 `_review_uid` 必须持久化，不能在每次载入时重建。首行 compact JSON 在磁盘提升到 metadata，载入时重构同名内存列以复用现有控件与算法；空工作表也必须保存元数据。

ResultStore 使用单写者 WAL/FULL 事务。普通 Save 通过 Session 的 UID 变更记录冻结新增/修改行与删除 UID，`save_delta()` 仅读取和更新这些行，同时提交 metadata/events/history 与增删改审计；成功仅清理该保存版本的变更，保留后台保存期间的新编辑。加载行与 save_revision 来自同一读事务，保存拒绝覆盖其他实例提交的新版本；文档加载世代保护旧保存任务不会改写新文档的路径。所有 schema/行/审计修改同一事务回滚，关闭写连接时 checkpoint；标注保存使用 finalize=True，非阻塞地尝试转回 DELETE 日志模式，被并发连接占用则保留 WAL。Detection 默认不切换模式；只读连接不得忽略活跃 WAL，也不得手动删除活跃辅助文件。

另存不存在的新文件时，可信基线使用 SQLite backup 克隆，再应用脏行事务；prepare_save 记录 _save_clone_source 与预期版本，ResultStore.copied_source 确认实际复制来源。源版本改变或目标抢先出现时拒绝发布，不能把稀疏快照写到空库或其他库。raw、审计与命令归档随完整数据库复制。首次导入、来源字段升级、片段导出、Undo/Redo 重建、Camera 全表变化和未跟踪的外部物化修改使用完整比较回退。未变化的命令归档不重复复制或编码；变化的 History payload 仍可能较大，不能宣称整个保存过程严格只与脏行数有关。重开后的 history_commands 保持只读。现有内容寻址 pickle 恢复机制保留，恢复后首次保存使用完整比较。

Save/Ctrl+S 写回当前 SQLite；CSV 输入首次保存需要选择 SQLite。Save as/Ctrl+Shift+S 默认名带日期时间，可选择新 SQLite 或 Legacy CSV；Save 默认名不追加时间。CSV 仅作兼容导出，不切换当前工作库、不清除脏状态、不回写 boutlist detection_file。CSV 输出公开字段、首行 compact JSON、metadata.json 与只读 edit_log，不带 raw/命令归档/行审计。范围设置同时作用于 Save 和 Save as：Save 按范围同步当前最终工作表，Save as 输出独立片段并禁止覆盖当前库。片段内帧号保持不变，raw 与历史保留来源覆盖。export_frame_range 记录已保存范围，后续取消范围设置须完整物化，不能沿用裁剪前的增量基线。source_annotation_path 保留每行来源，旧库首次保存允许全量升级该字段。人工新增/插值行不继承模板 raw 行引用；绑定对齐改变结果帧时用 raw_frame 保留原始观测帧。不同 raw_source_id 的项目不允许追加，防止外来 raw ordinal 误指当前 raw；没有可验证 raw 身份的旧 CSV 追加保留 legacy_raw_det_index/legacy_raw_frame 诊断，但不建立当前 raw 行关联。额外列名不能仅大小写不同，保存会明确拒绝并保持原库。

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

tracking_weights.py 管理 Fixed/Calibrated/Adaptive 的共有有效权重。Match.components/evidence 只记录匹配器原有分项，标准候选最多 12 项、姿态背景证据有固定数量上限；不能额外累计每帧证据。候选生成及五项评分公式保持原样，自动权重不让颜色/边缘生成新的候选。Motion 不从背景差异学习。Calibrated 在模板/显式标定时计算，Adaptive 只从可信接受结果低频更新；Worker 拷贝和既有世代检查隔离迟到结果。UI 保留固定输入与只读有效百分比两套值，不能把自动显示值重新作为输入而造成反馈。

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

`rendering/overlay_data_store.py`、`overlay_scheduler.py`、`trail_overlay_store.py` 管理绘制数据与缓存；Qt raster、保留式 OpenGL 和可选 trail shader 是不同路径。导出有独立组合/编码任务。GUI 导出始终跟随全局 Overlay renderer；rendering/qt_export_renderer.py 消费同一 FrameOverlayPacket，使用 QPainter 且不创建 OpenGL 上下文；rendering/hud_renderer.py 共享预览与导出的 HUD 外观，rendering/export_annotations.py 处理最终裁切与 HUD。ui/export_crop.py 管理独立画面选区，ui/file_dialogs.py 的 ExportSettingsDialog 为非模态确认窗口。视频范围与裁切只存于 MainWindow.export_selection，不持久化到 INI。

HUD 各类型的默认字号和位置集中在 rendering/hud_renderer.py::HUD_DEFAULTS，hud_layout 按水平／垂直锚点和优先级排布有内容的项目。UI 为每类提供独立颜色、字号、描边和位置，使用 display/hud_<type>_<field> 设置，主开关仍为 display/hud_<type>；不得恢复成全局统一字号。Export settings 的关闭和 Cancel 保留当前视频的范围输入与 File 页预览，仅切换视频时重置。

shader 以图片年龄计算渐变样式；不适用时说明回退，不偷偷改变轨迹。少量 Tracking 交互框仍由 Qt 绘制。避免逐帧扫描全部累积缓冲、重建全量 DataFrame 或无界缓存。

侧栏派生查询使用 `session.navigation_revision` 区分数据代次；它包含工作表身份、保存修改代次和索引重建代次。轨迹帧号、摘要与帧边界的有界缓存不进入 Session 的复制或恢复文件。当前行坐标仍即时读取；自动 Selected ID 表额外检查 Continuous 两个局部撤销栈的变化，切帧只更新焦点。未提升数据代次而原地更新展示列的通路，须像 Compact metadata/Camera 保存同步一样清除表格内容缓存。人工轨迹、Binding 与 Tracking 待提交内容分别遵循各自的更新来源，不能只用 Session 代次判断。轨迹点选缓存还必须区分前后轨迹归属、可见窗口及屏幕变换；画布矩形缓存依赖图片尺寸、控件尺寸、缩放和平移。

验证性能时固定视频、帧区间、模板、显示内容和速度上限。分清初始化、解码、匹配、数据包准备、绘制、编码及写盘耗时。offscreen 测试不能证明真实 GPU/驱动路径可用。

完整 SQLite metadata 由 Session 持有；DataFrame.attrs 仅携带导入核验需要的 raw_source_id。pandas 会在取列、切片和分组时深复制 attrs，不得把整份项目参数或 raw_metadata 放回其中。帧/ID 索引以数值列分组的位置数组建立，保留工作表的实际行标签；载入只建立一次索引。

IDs 的统计内容与选择高亮分别缓存：选择变化只更新原生选区，排序后通过现有 item 的 row() 定位，不重填单元格。数据修订、筛选和离开 Detection 预览时重新核对内容缓存。少量多选的顶部摘要按选择和数据代次复用；超过 24 个 ID 只显示数量汇总。大量多选的帧并集/交集采用一次分组统计，当前对象与箭头只筛当前帧，不逐 ID 查询当前帧。颜色混合状态在发现第一种不同颜色时即可确定。

Selected boxes 计数使用所选 ID 的 track_index 行数总和，并按 navigation_revision 与选择缓存；不能回退成当前帧计数。IDs 的 x/y 范围按当前可见行的源图像中心坐标计算，忽略非有限值，与其余统计使用同一内容缓存。

Hive 的 axis_preview_point 属于画布瞬时状态，不写入 Session 或设置。首次点选前跟随源图像鼠标坐标，固定候选遵循既有 Hive/Camera 坐标空间；Qt 与 GL 静态 Overlay 使用同一预览原点。预览强制可见但不改变 Axis 开关，退出选择时清除。

File 面板在激活时更新。Detection 信息计数来自所选磁盘文件的 reviewed_detections，不混入 raw 或待保存工作表；缓存依赖文件及活动 WAL 的修改时间和大小。未保存编辑不能使磁盘统计失效。Camera 载入筛出每帧第一条运动记录与第一条关键帧记录，避免逐帧构建完整小表。Qt raster 预览不启动未使用的 OpenGL 保留层编译；切回 OpenGL 时再准备相应快照。拖尾编译先按数组分组，Catmull-Rom 采样按固定大小批次计算，维持原采样数、断段与帧顺序。

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
