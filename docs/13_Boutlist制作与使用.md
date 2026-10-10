# 13 Boutlist 制作与使用

[返回总目录](00_操作手册.md)

## 13.1 用途与一行记录的范围

Boutlist 是普通 CSV 表，每行组织一个需要审阅的 bout：视频、自动标注、人工轨迹及对齐/分析元数据。它便于逐条打开和回写简短信息，不保存全部逐帧框，也不替代标注 SQLite。

同一视频可以有多个分析片段，但应使用明确 bout_id 和范围区分。回写前必须核对当前选中行，不能只凭视频文件名认定某一行就是目标。

## 13.2 文件制作规程

1. 使用支持 UTF-8 的表格工具或文本编辑器新建 CSV，第一行为列名。
2. 每行填写 bout 标识及实际存在的视频路径；逐帧标注和人工文件没有时可以留空。
3. 已知的 Start、End、Capture 和人工对齐信息按对应列填写。
4. 含逗号、引号或换行的文本使用标准 CSV 引号规则；不要手工按逗号切割记录。
5. 保存后，在 Display → Boutlist fields 配置列名映射，再 Open Boutlist。
6. 用一行试开并检查同步结果，确认后批量组织其他记录。

**最小示例：**

```csv
bout_id,origin_video_file,detection_file,analysis_start_frame,analysis_end_frame,capture_frame
trial01,E:/videos/clip01.MTS,E:/results/clip01_review.csv,100,1200,1185
trial02,E:/videos/clip02.MP4,,1,950,930
```

使用绝对路径最容易直接核对。使用相对路径时，需保持 boutlist 和相关目录的位置关系，并实际试开确认路径解析；不要将另一台计算机的盘符路径当作通用路径。

## 13.3 Boutlist fields 映射设置

设置位于 Display 中 Playback 与 Others 之间。左侧项目代表程序内部含义，文本框填写 boutlist 中的实际列名。

- 按列名精确匹配，包括大小写；输入值两端空白会被去除。
- 留空表示停用该项目的读取和回写。
- 两个项目不能指向同一个非空列名；Save settings（All 或 Boutlist fields） 会阻止重复映射。
- 列名输入框为草稿。只有范围选为 All 或 Boutlist fields 并点击 Save settings 后，映射才写入 `settings.ini`，并从本次会话开始生效。保存其他分组不会应用这组草稿。
- 未保存时打开或回写 Boutlist，继续使用上一次保存的映射。恢复为已保存值后，未保存提示自动消失。
- 改映射不会直接重命名或重写 CSV 列。
- 更改后应重新打开当前 boutlist 记录，避免沿用旧映射选行时的快照。

**例：** 表格列名为 `Video`、`Start`、`Capture`，分别填入 origin_video_file、analysis_start_frame、capture_frame 对应文本框。程序仍把它们理解为视频路径、分析开始帧和捕获帧；输出标注 SQLite 的规范字段名不改变。

## 13.4 可映射字段

### 13.4.1 标识与来源

| 项目 | 含义 |
| --- | --- |
| bout_id | 片段标识，建议稳定且可区分 |
| trial_id | 实验/试次标识 |
| phase | 阶段信息 |
| origin_video_file | 视频文件 |
| detection_file | 自动或审阅标注 SQLite |
| manual_track_file | 人工轨迹文件 |
| trk_file | Tracker 工程来源 |

### 13.4.2 分析范围与主体

| 项目 | 含义 |
| --- | --- |
| analysis_start_frame / analysis_end_frame | 包含两端的视频分析范围 |
| capture_frame | 成功捕获参考帧 |
| nest_x_px / nest_y_px | 巢门口像素坐标摘要，与程序的 Hive 信息对应 |
| scale_px_per_cm | 简短的代表性 px/cm |
| victim_id_at_capture / captor_id_at_capture | 被捕蜜蜂与得手胡蜂的已核对身份 |
| left_censored | 真实互动起点早于可用分析画面 |
| verified_capture_pair | 捕获主体轨迹已核验 |
| verified_exposed_bees | 低位和外围蜜蜂已核验 |
| verified_other_hornets | 其他胡蜂及同类干扰已核验 |
| review_notes | 审阅备注 |
| camera_motion | Camera 相关摘要标志，不能代替完整锚点观测 |

### 13.4.3 人工轨迹对齐与视频属性

| 项目 | 含义 |
| --- | --- |
| trk_capture_frame | Tracker 时间轴中的对应参考帧 |
| trk_align_first_frame / trk_align_last_frame | 使用的 Tracker 帧范围 |
| trk_reverse | 是否来自倒放人工标注 |
| trk_fps | 人工标注视频帧率 |
| frame_offset | 额外视频帧偏移 |
| x_offset / y_offset | 人工点在原图中的位置偏移 |
| fps | 视频帧率摘要 |
| resolution_width / resolution_height | 分辨率字段 |
| video_width / video_height | 视频宽高字段 |

字段存在不代表已填写且有效。帧号和身份应为合理整数；布尔项目使用一致、可识别的表示；文件路径必须能够访问。不要把 Excel 的自动日期转换、科学计数法或浮点显示当作 ID 的真实值。

## 13.5 打开与同步规程

### 13.5.1 读取

Open Boutlist → 选择记录 → 核对 File 中实际路径 → 检查 Points 和 Match 参数 → 播放关键帧。字段映射只改变列名对应，不会修正错误视频配对或错误帧号。

### 13.5.2 回写

1. 在 Points 或 Match 修改相关信息并确认。
2. 执行 Sync to，或在程序提示回写时核对差异。
3. 确认显示的目标行和实际列名。
4. 完成后重新读取这一行验证。

Sync from 会把表中内容重新带入对应元数据。若当前会话有更准确的新值，应先判断是否需要覆盖。取消回写不意味着撤销已经保存到标注 SQLite 的结果。

## 13.6 写入边界与文本保留

回写只更新相应映射字段，其他列和未修改单元格的文本保持原样，例如标识 `001` 和自定义列 `1.2300` 不应因为更新 Capture 而被整体重新格式化。

完整 `scale_calibration` JSON 始终写入输出标注 SQLite。Boutlist fields 中可独立指定 `scale_px_per_cm` 与 `scale_calibration` 列名，二者可以同时启用。另可启用 `info_points`、`info_events` 和 `camera_anchor_keyframes` JSON 列。清空输入框只灰显项目标签，输入框保持可编辑；点击 Save settings（All 或 Boutlist fields） 后该项停止读写，不会清空表中已有内容。默认映射启用现有 tethered boutlist 中的同名列，其他项目为空；已保存的自定义映射优先。Points JSON 与单独标量字段并存时，非空的单独标量字段优先。加载标注 SQLite 时，元数据冲突仍通过原有对话框选择来源。

Events、逐帧位置、模板图像和全部 History 不在此表逐项保存。多人或多个实例同时修改同一个 CSV 时，应避免互相覆盖同一记录，并以写入前差异核对为准。

## 13.7 自动打开对应文件

Boutlist fields 中的 Auto open corresponding file 控制双向关联：打开视频时查找对应标注文件；打开标注文件时查找对应视频。视频查找使用标注来源字段、info_video 中的来源信息、检测 sidecar 和已保存 Boutlist 字段映射；有效来源路径优先。没有有效路径时，按来源文件名或去掉检测结果后缀后的同名视频查找。

查找限定在标注目录、其父目录、项目目录和上次视频目录，不递归扫描整个磁盘。只有一个候选时自动打开；多个候选时弹窗选择，取消不切换视频。没有找到时保留当前状态并在状态栏提示。自动打开视频不会再次打开标注，从而避免循环或替换刚载入的标注。

该选项关闭时，打开标注不自动切换视频。向当前审阅追加另一份标注仍要求来源属于同一视频，不根据追加文件自动切换视频。

## 13.8 典型检查

- 打开错误视频：检查映射列、当前行和路径，不先调整标注坐标。
- 某项未读入：检查映射是否空白、拼写大小写、列是否存在、值是否有效。
- 更换映射后不能直接回写：重新选择 boutlist 记录建立新映射下的行快照。
- 回写后出现新列：确认映射填写的是原有列名，而不是另一个相似名称。
- 需要精确空间分析：读取标注 SQLite 的完整标定，不能只用 boutlist 的平均比例。
