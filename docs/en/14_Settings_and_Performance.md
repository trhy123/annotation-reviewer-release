# 14 Settings and Performance

[Return to the main contents](00_Annotation_Reviewer_User_Manual.md)

## 14.1 Scope of settings

Display settings primarily affect display, decoding, playback, and runtime resources. Some take effect immediately; use Save settings for persistent changes. The root-level `settings.ini` stores appearance, decoding and inference parameters, path preferences, field mappings, and encoding configuration. The current video's postprocessing test cache and start/end frames, video export time range and image crop, and target-only annotation-saving option are session state, not written to the INI, and are recreated when videos change.

Settings sections and keys retain the logical order defined by the platform template. New custom keys follow the known settings.

Hover over a window label for a setting explanation, or over a field/drop-down for its full current content. Buttons and checkboxes describe their actions. Ordinary mouse-wheel movement should not accidentally change input values.

For Box, Axis, Metric grid, and Trail appearance, see [Interface and segment-by-segment review](02_Interface_and_Segment-by-Segment_Review.md); for Recovery, see [Undo and recovery](12_Undo_and_Recovery.md); for field mappings, see [Boutlist](13_Creating_and_Using_a_Boutlist.md).

## 14.2 Playback and decoding

### 14.2.1 Video presentation and decoding backends

Render/Backend selects a video presentation and decoding combination. Qt raster, OpenGL Overlay, and video decoding are separate stages: using OpenGL does not imply GPU model inference, and hardware decoding does not imply that all trajectory calculations run on the GPU.

| Setting | Meaning and adjustment criteria |
| --- | --- |
| Backend | Select an available decoding implementation; after changing it, check navigation, forward/reverse playback, and the timeline |
| HW accel | Request supported hardware decoding; actual support depends on video encoding and runtime |
| Codec | Restrict or select the decoder; automatic selection is delegated to the backend |
| Threads | Number of decoding threads, not template-matching or YOLO Workers |
| Index workers | Blank / 0 starts one segment, then adjusts up to 4 workers from measured aggregate throughput and current RAM. 1–8 sets a manual upper limit. Keep at least 512 MiB or 10% of total RAM free; a new worker is estimated at `width × height × 48 bytes + 64 MiB`. Auto waits before admitting another segment under pressure. Existing scans finish normally. Short videos use one scan; overlap must match before joining, otherwise use a single scan. Applies on the next index job; this is admission control, not an OS memory limit. |
| Reverse MiB | Reverse-frame buffer budget, 0–16384 MiB. Blank / 0 uses up to 4 GiB or one eighth of RAM left after the system reserve; manual requests are capped at one quarter. RAM is sampled once per second during playback, shrinking future blocks under pressure. Already decoding / queued pictures drain normally. At least three full-size pictures are needed. The budget is a ceiling, not a fill target; decoder and display allocations are extra. |
| Seek | Navigation strategy; precise image correspondence takes priority over unverified fast time estimates |
| FFmpeg / FFprobe | Paths to decoding and media-information tools |
| libmpv library | Path to the dynamic library required for mpv_gl playback |

When a video has PTS gaps, frame identity follows the image index. After changing backends, check that the same number displays the same image, rather than comparing playback-time text alone.

When the actual implementation can be determined, automatic HW accel, Codec, Preview backend, and similar options display forms such as `auto (actual backend or decoder)` and `cuda_auto (actual decoder)`. Drop-down lists widen to show full contents. Parentheses indicate current runtime state; auto in the INI has no parenthetical suffix.

### 14.2.2 Two Playback constraints

No drop prioritizes displaying every frame; insufficient processing capacity can reduce actual playback speed. Correct speed prioritizes timing; observe the current implementation and status to determine whether display frames are skipped to maintain speed. Neither deletes annotation records nor changes the consecutive image numbering used for recognition.

Forward playback reuses a continuous decoding pipeline. Both cpu_frames and mpv_gl reverse playback decode forward into image blocks and present them backwards while preparing the preceding block. A block is an application image-cache unit, not a codec GOP; it may cover part of a GOP or several GOPs. The forward queue and pending-display buffer together stay below 256 MiB. Up to three reverse blocks share the Reverse MiB budget. The first block has at most 8 pictures; subsequent blocks have at most 64 for No frame drop and 12 for Correct speed, constrained further by the budget and aligned to keyframes when practical. The cache does not grow with video duration or need to fill its budget before playback.

FFmpeg seeks near the preceding keyframe and verifies each output timestamp. A failed hardware path retries precise FFmpeg software decoding before falling back to counting from the beginning. Hardware-frame download accepts both 8-bit and 10-bit formats. Decoder Threads controls input decoding; increasing it can also increase memory and does not guarantee higher throughput.

FFmpeg RGB conversion honors the source color matrix and range. Untagged HD uses BT.709 and SD uses BT.601, matching mpv’s heuristic. OpenCV may convert colors differently; use FFmpeg when color consistency matters.

Correct speed reverse playback starts its clock when the first small block is ready, without waiting for two complete blocks. Fast forward and reverse playback coalesce the latest target within the decoding worker, skip obsolete work, and avoid repeatedly canceling a worker that is still starting. Later buffer shortages preserve the clock and choose available pictures by elapsed video time. Insufficient decoding or presentation throughput can still leave visible gaps; No frame drop instead preserves every picture and may run slower.

Ordinary playback and automatic tracking have different performance characteristics. Tracking must update predictions and templates sequentially, rather than simply displaying precomputed results rapidly. Speed also limits tracking display cadence; Tracking Rate includes `(limit Nx)` only when that limit is reached.


### 14.2.3 Rendering GPU and decoding device

Decoder → Render GPU requests an OS rendering preference. On Windows choose Auto, Power saving, or High performance, then save Decoder settings and restart. This preference applies to the executable; source runs therefore share the Python executable's preference. Linux Primary / Secondary GPU is applied through DRI_PRIME before Qt creates its context. macOS retains system GPU selection. Active render reports the actual OpenGL renderer; the OS and remote desktop driver can override a preference.

HW accel controls FFmpeg / reverse playback. Native HW separately controls libmpv forward playback, keeping its safe Auto default. FFmpeg device and Native device independently select their hardware API's adapter or accept an API-specific index / device path. Changing the API resets it to Auto; click Apply to restart preview decoding at the current position. Auto choices show resolved values in parentheses; the Active line reports runtime information. An unreported adapter is shown as such rather than inferred from free memory. Windows indirect/virtual display adapters are excluded from device choices; separate physical GPUs with identical names remain separate.

### 14.2.4 Color and HDR preview

The Color group is directly below Decoder. Source defaults to Auto, using matrix, primaries, transfer and range tags. Untagged SD / HD falls back to BT.601 / BT.709; these heuristics cannot identify an untagged HDR recording. Override Source with BT.601, BT.709, BT.2020 SDR, PQ, or HLG when needed, and override Range independently. Auto shows the resolved source, range and HDR mode in parentheses. The information line shows matrix, primaries, transfer and range; inferred values are marked, and its tooltip identifies each value’s origin. Failure to read metadata is reported explicitly. Apply clears old decoded and thumbnail images; Save settings for Color or All persists the choices.

Preview output is SDR in both video modes, using the same 203-nit reference white for HDR conversion. Auto keeps native GPU tone mapping in libmpv and uses FFmpeg in CPU / reverse decoding. SDR (same mapping) also uses the FFmpeg conversion chain in libmpv, for closer agreement between paths at a higher CPU cost. Off / clip clips highlights instead of compressing them. Peak nits blank / 0 uses source HDR peak metadata, with a 1000-nit fallback; enter a positive value to override. FFmpeg uses 16-bit samples and a reusable, high-precision tone/gamut lookup table before reducing to 8 bits. The small temporary lookup file is removed on exit. Ordinary SDR keeps its inexpensive path. HDR and manual color previews use FFmpeg when OpenCV cannot apply the policy. This is static PQ / HLG mapping, not native HDR output or Dolby Vision dynamic metadata processing. It does not change source media, annotation coordinates, or YOLO inputs.

### 14.2.5 Prebuilding video indexes

Decoder → Indexes… opens a modeless batch queue. Add videos or Add folder, select a writable PTS cache directory, and Start. Files run in sequence; each video uses the current Index workers limit. Status, indexed frames, estimated progress and completed cache size appear per row. Cancel current stops this queue; an index already shared with the main player continues. Remove removes queue rows, not source videos or caches.

The queue reuses existing indexes and active scans. Cache location is saved as paths/pts_cache_dir. The default is the application's temporary PTS folder (or the macOS bundle's external cache directory); choose a persistent folder to avoid OS temporary-file cleanup. There is no age-based deletion of completed PTS caches. Indexing consumes decoder memory as well as timestamp storage; Auto pauses admission of new segments when the current RAM reserve is insufficient.

## 14.3 Overlay renderer

### 14.3.1 Qt raster and retained-mode OpenGL

Qt raster organizes and draws Overlay through the CPU path, offering broad compatibility. Retained-mode OpenGL maintains drawing data and suits large numbers of continuous segments and gradient trails; availability depends on graphics drivers and context.

Check the status label after selection. Initialization failure, unsupported configuration, or unavailable export capabilities are reported through status/messages explaining fallback. A normal display does not prove that the requested GPU path is active; check the actual backend.

Video export follows the same Overlay renderer selection. Export backend is read-only status, with no independently saved backend setting. Qt raster export creates no OpenGL context. Grid and annotations use the same drawing backend, and fixed HUD elements are drawn at the final image dimensions.

The small number of interactive Tracking boxes may still be drawn by Qt alongside OpenGL annotations/trails. Manual template and search regions are few; performance problems should not all be attributed to these boxes.

### 14.3.2 Trail shader

Trail shader computes color, width, and opacity from point frame age during GPU drawing, reducing per-frame reconstruction of gradient appearance. It applies to supported playback trails, pending Tracking trails, and OpenGL export, and does not require CUDA.

Enabling the shader does not change trajectory coordinates or match results. Solid, dashed, dotted, dash-dot and wavy lines are supported. Patterns follow accumulated trajectory distance rather than restarting at each interpolation subdivision. If the shader is unavailable, the existing rendering path is used and status explains the fallback.

### 14.3.3 Packets, caches, and parallelism parameters

| Parameter group | Function | Cost when too large |
| --- | --- | --- |
| Packet workers | Prepare background-capable Overlay packets in parallel | Increased scheduling overhead and memory |
| Packet prefetch frames | Prepare future display frames in advance | More tasks can become stale after navigation/editing |
| Packet cache MiB | Packet-cache memory limit | Higher memory usage without guaranteed cache hits |
| Preview workers | CPU preview drawing/fallback parallelism | Resource competition with the main thread |
| Export workers | CPU export-drawing parallelism | Limited benefit when encoding or decoding is the bottleneck |
| Preview batch | Number of future frames processed per preview scheduling operation | Excessive GUI work can impair interaction |
| Export batch | Composited export frames per batch | Increased RAM, GPU memory, and response latency |
| Export decode queue | Number of batches decoded in advance | RAM usage and more queued work on cancellation |
| Prefetch frames | Playback trail prefetch range | Higher costs for long trajectories and recalculation after seeks |
| Cache layers | Cache reusable static/simple trail layers | Limited hits for dynamic gradients; growth must remain bounded |

Start with small queues and use Profiler to identify bottlenecks before adjusting one parameter at a time. Do not increase every parameter together and judge benefit from one video's average playback multiple.

### 14.3.4 Optional CUDA Overlay settings

TF32, Trail raster, Geometry, Canvas warp, and GPU layer cache in GPU overlay are a separate set of CUDA-path options, distinct from the OpenGL trail shader.

TF32 controls the precision/speed tradeoff for supported CUDA mathematics; Trail raster draws trails; Geometry draws boxes, points, and other geometry; Canvas warp transforms the expanded canvas; Layer cache limits resident GPU layers. Small images or simple Overlays can be slower than CPU rendering because of full-frame transfer overhead.

Alpha/color bucket controls gradient quantization steps: 1 retains finer granularity, while larger values reduce subdivisions but can produce more visible banding. Compare visual differences and actual timing when choosing values, rather than observing GPU utilization alone.

## 14.4 Tracking throughput settings

Decode ahead in Weights overlaps decoding of the next image with matching of the current image; Match workers matches independent templates in parallel. Prediction, result acceptance, and Evolution still advance in frame order. Multi-channel candidates, larger Budget values, and HSV histogram in Advanced increase per-frame matching work; compare accuracy and time separately. Guard template updates controls learning conditions without making video frames independently parallel.

More templates, wider rotation/scale searches, larger search regions, or Assist increase workload. Disable obsolete templates to reduce matches; hiding the Templates page does not stop checked templates from being used. More threads may provide no benefit for small templates.

**Test procedure:** Use identical starting frames, templates, thresholds, and intervals. Set Speed high enough to avoid throttling. Record baseline throughput, enable Decode ahead/increase Workers one at a time, then compare trail and shader separately. Do not directly compare speed multiples across different templates or video segments.

## 14.5 Others and cache directories

### 14.5.1 Classes, language, and interface

**Classes** is a horizontal table with three rows: YOLO model class number, annotation class name, and Tip, such as `0 / bee` and `1 / hornet`. Tips are optional, appear on class choices exactly as entered, and are not translated. Click **Edit** to begin; **Add / Remove** adds/removes selected columns. **Apply** validates and immediately writes `[classes]` and `[class_tips]` in `settings.ini` (tips are keyed by model number), updating editing/tracking class options and IDs subtables. Numbers must be unique nonnegative integers; names must be nonempty and unique and cannot contain `, ; |`. This defines class mappings without batch-renaming classes in existing annotations; use Change class to modify annotations.

Existing `[id_groups]` are preserved where possible, and new classes are appended as separate groups. When loading CSV/SQLite, unique classes are extracted and compared in the background from the already loaded `class` column, without rereading disk or adding file fields. A prompt asks whether to add missing classes. Acceptance automatically assigns unused model numbers before loading the table. If actual model numbers differ, correct them in Classes. Declining still opens the file, displaying unknown classes in Other.

**Language** defaults to **English**, with **简体中文** (Simplified Chinese) also available. The change applies immediately to existing windows, tooltips, and status text, retaining the current document, selection, and editing drafts. Use **Save settings** for Others or All to retain the choice for the next run. It does not translate or rewrite user-entered classes, IDs, paths, notes, or annotation data. Verification-list titles, buttons, column names, and built-in statuses follow the same language setting, while internal CSV values remain unchanged.

**Theme**, beside Language, selects Follow system (default), Light, or Dark for this application. It applies immediately; save Others or All to retain it. Classes appears before UI size in this group. Axis, Metric grid, and Camera canvas are between Trajectory picking and HUD.

The bottom-left **Frame: / Time:** selector changes the navigation input, total display, and timeline ticks together. The choice is saved/reset with Others or All (`ui/timeline_units`); it does not change the integer frame numbers used in annotations and edit ranges.

Chinese interface text uses the external [`translations/zh_CN.json`](../../translations/zh_CN.json), keyed by English source text and processed through the shared `app.i18n.tr` entry point. Drop-downs and headers translate only their display, without changing internal values. The English/Chinese reference CSV is a maintenance artifact stored outside the project and is not read by the application. Runtime reads JSON; retain format fields such as `{v0}` when editing translations. Manuals are maintained separately in `docs/zh` and `docs/en`; interface language does not require translating the manual. In merged manuals this link still points to the actual file in the project root, relative to the merged document.

### 14.5.2 Preview and caches

| Setting | Behavior |
| --- | --- |
| Point to Selection | Use an arrow to help locate the selected target |
| Keep arrow visible | Retain the corresponding selection indicator |
| Seek preview | Display a video thumbnail when hovering over or dragging the progress bar, without annotations or changes to the main image |
| Width px | Thumbnail width; default 240, range 80–999; height is calculated proportionally |
| Idle layer cache | Prepare reusable layers while idle to reduce later repeated drawing |
| Overlay cache directory | Display-cache directory, not the formal result-output directory |

Thumbnail previews have resident base images and a refinement cache. After file and index loading, idle time uniformly preloads up to 256 base images along the timeline; these are excluded from refinement-cache eviction. Movement immediately displays the nearest cached image. Slow movement or a pause of about 90 ms requests a more accurate frame at the current position, replacing the image when ready. With no cache, initial decoding must complete first. Playback, navigation, tracking, and mouse previews pause base-image preloading; newer requests cancel stale targets. Approximate images can still be requested before indexing completes. Previews are hidden when another window has focus.

The hover area extends from the widget top to its vertical center. Leaving it hides the popup immediately, and late decoder results cannot reopen it. Movement reuses a refinement at the requested position if available; otherwise it shows the nearest base image before the new refinement arrives.

Images are stored only in memory, not in recovery or disk caches. Each is at most 240×135, about 95 KiB in RGB pixels; 256 base images occupy about 23.7 MiB. The refinement cache additionally retains up to 768 images or 72 MiB, whichever limit is reached first. Both layers total at most about 95 MiB, excluding decoding workspace and Qt display overhead. Leaving the progress bar retains completed caches; closing or switching videos clears them. Thumbnails do not establish annotation frame numbers; formal navigation still uses the precise-frame path. Both controls are saved with Save settings for Others or All.

Hold Ctrl while moving along the progress bar to generate local thumbnails for the player's currently visible region, including zoom, pan, and the current Camera coordinate transform. Local images are not preloaded; at most 64 are retained, sharing the 768-image/72 MiB limit with ordinary refined images. Local images are evicted first at capacity. Previews with verified image identity display `Frame N`; base images, images before indexing completes, or images with unmatched decoding timestamps retain an approximate indicator.

The Playback group displays Correct speed before No frame drop. During No frame drop playback, the right side shows newly presented images per second and their multiple relative to the original video FPS, to two decimal places. Repeated redraws of the same frame are excluded. Sampling occurs only while this row is visible and the main window is active; hiding or pausing stops sampling and clears the display.

Unsaved before the button lists groups differing from their saved state; None means they match. Hover to view the full list when long. Returning a setting to its saved value clears that group's indicator.

The save bar for all page settings sits at the bottom, outside every group. Its scope drop-down defaults to All or can select one group. Event-type definitions use Event types; verification definitions and field mappings use Boutlist fields. Save settings saves only that scope and retains other drafts. Boutlist fields column mappings apply to current and subsequent reads/writes only after successful saving; other display controls retain live-preview behavior. The two field-editing windows also provide independent Save settings buttons that write their own definitions directly to settings.ini. Closing a window discards its unsaved edits. Invalid drafts in the other window do not block those buttons. Duplicate active mappings still require correction; saving an unrelated Display group remains independent.

**Example:** Change both Box line width and Boutlist column names, then save with scope Box. Only line width is persisted. Boutlist saving still uses the original column names, and Unsaved continues showing Boutlist fields. New names take effect only after that group is selected and saved.

Recovery and display-cache directories serve different purposes. Do not treat cache files as annotation SQLite, or delete an original-data directory merely because the cache directory changes.

**Reset**, between the scope list and Save settings, restores the selected scope to its saved values while keeping unsaved drafts in other groups. All restores every Display group. Reset does not write settings.ini and does not restore factory defaults.

## 14.6 Profiler

### 14.6.1 Sampling and interpretation

Enable frame profiler starts timing frame-display stages; disabling it stops sampling. Clear resets current statistics for comparing settings. Copy copies current records to the clipboard for saving or comparison. The interface shows stage timings, cache hits, and resource information, which should be read alongside actual frame presentation rates.

Profiler primarily locates stage overhead within this program and does not replace graphics-driver-level analysis. Reducing one stage's time may not increase overall speed; faster decoding can expose matching or encoding as the next bottleneck.

### 14.6.2 Reproducible comparison procedure

1. Fix the video, interval, window size, displayed content, and speed multiple.
2. Wait for one-time preparation such as initial decoding and model loading to finish.
3. Clear, then play or recognize the same segment and record stage timings and actual rates.
4. Change only one setting, then Clear and repeat.
5. Compare throughput, interaction responsiveness, and memory rather than average GPU utilization alone.

### 14.6.3 Common bottlenecks

- High decoding waits: check the source disk, encoding format, backend, and decoding prefetch.
- High matching computation: check template count, search regions, pose-search range, and CPU parallelism.
- High Overlay cost: reduce visible long trajectories for comparison, then check the actual OpenGL/shader path.
- Poor GUI responsiveness with low resource usage: check GUI-thread batch tasks, table refreshes, and wait chains.
- Slow export: compare decoding, Overlay compositing, encoding, and disk writing separately.

### 14.6.4 Annotation saving and large-table overhead

Save (Ctrl + S) writes back to the current SQLite. Ordinary edits freeze only changed rows and deleted UIDs, saving data, metadata, and history in one transaction. Background-save completion clears only changes included in that save; edits made while it runs remain pending for the next Save. When multiple instances edit the same file, version checking prevents overwriting a newer save.

For Save as to a new file, a trusted SQLite save baseline at the same version permits copying the complete database first, then writing changed rows, metadata, and history in an incremental transaction. Embedded raw data, existing audits, and command history remain in the database; unchanged annotations are not serialized row by row again. Saving stops if the source database version changes or the destination appears after preparation, avoiding overwriting other modifications.

Initial CSV conversion, segment export, files needing completed provenance, and some batch operations/undo still use full snapshots. Compatible CSV export must also rewrite the entire output table and lacks SQLite's incremental performance; raw data, audits, and full commands remain in SQLite. The in-memory editing layer is still a DataFrame, so opening full results still requires reading the working table. Content-addressed deduplication of recovery `.pkl` snapshots remains unchanged.

Detection statistics on the File page describe the currently selected annotation file on disk, showing saved frame, row, and identity counts without pending edits or embedded raw data. They are read and cached when entering File, then updated on a later visit after saving or external file modification. With multiple sources, select each required file separately; do not confuse their in-memory working rows with disk-file statistics.

The IDs page builds identity summaries on first viewing. Selection-only changes reuse statistics and cells, updating only highlights. For large multiselections, the upper-right information area summarizes counts without changing actual selections or batch-operation scope. Trail curves are prepared in background batches; time initial preparation separately from subsequent per-frame drawing.

SQLite projects may temporarily use `-wal` and `-shm` auxiliary files during detection or save transactions. SQLite manages them. Connections close after directory matching and metadata reads, allowing auxiliary files with no remaining users to be removed automatically. Active writers or unfinished transactions retain the relevant files; do not delete WAL manually.

The default name when Save first selects a destination has no date/time; Save as includes date/time by default. Save settings saves configuration only and cannot replace annotation Save. See [Basic operations](01_Basic_Operations.md#15-saving-annotations-and-exporting-data-tables) for operations and CSV companion-file requirements, and [Undo and recovery](12_Undo_and_Recovery.md) for recovery and read-only history.

## 14.7 Saving configuration and checking failures

Record effective configurations and corresponding sample videos. After starting in a supported environment, verify playback, precise seek, reverse frame stepping, refresh after modification, and short-clip export separately. If changing a backend or hardware switch causes problems, restore the preceding verified configuration and investigate one setting at a time, rather than modifying annotation geometry to compensate for display errors.
