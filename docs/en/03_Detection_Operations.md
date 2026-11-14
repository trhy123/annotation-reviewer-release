# 3 Detection Operations

[Return to the main contents](00_Annotation_Reviewer_User_Manual.md)

## 3.1 Purpose and Startup Checks

Detection uses a model to generate frame-by-frame candidates, then saves original detections or performs stable-identity postprocessing according to the selected mode. Before starting, check the video, model, classes, output directory, and device. Template matching in Tracking and this model inference are separate functions.

## 3.2 Controls

Detection has two subtabs:

- **Control**: Output directory, mode, Settings, Batch, Choose raw, Start/Pause/Stop, Load, progress, device, half, batch size, pipeline, wait time, Workers, and Follow progress.
- **Inference**: Contains only model information and YOLO parameters. Below Model are the model family, training size, and Training info button. Reading occurs in a separate process without inference. Load only trusted .pt files; other formats or missing metadata are shown as unavailable rather than fabricated.

Metadata is reread after switching models. The reader process uses only CPU and does not occupy the CUDA device used for actual inference. Reading failures or timeouts exceeding 45 seconds show unavailable; hover to see the reason and reselect the model to retry. Older read results do not overwrite a new model selection.

**Monitor** on the right of the subtab bar opens a nonmodal performance monitor. The window stays on top without receiving keyboard focus, allowing simultaneous operation of the main interface. Pressing Monitor again or closing the monitor window pauses sampling; exiting the application stops the sampling thread.

The monitor distinguishes total system usage from this application's usage in System and Reviewer columns. Reviewer includes the main interface and its current background subprocesses, excluding other Reviewer instances. CPU, GPU, VRAM, GPU commit, RAM, and Committed appear in order; GPU utilization and video memory usage are displayed separately.

CPU defaults to Total, displaying aggregate utilization across all logical processors. Options also include All CPUs (separate physical processor packages), a single package, and In use. In use determines eligible processors from this application's process affinity; threads migrate among eligible processors rather than occupying a fixed CPU. CPU device selection affects the System column; Reviewer CPU always uses the entire machine's logical processing capacity as 100%, with `(total)` appended to application usage in per-device displays. Device categories and numbers appear only once in the left category column; System and Reviewer show values. RAM and Committed always show totals.

GPU selection supports all adapters, one adapter, and In use. In use prioritizes adapters actually used by this application, falling back to the current inference device when idle. Models, device counts, and identifiers are enumerated at runtime rather than relying on the current computer configuration. Windows adapter numbers are not guaranteed to match CUDA numbers; duplicate adapters created by RDP are filtered using native device identity and kernel counters. Driver numbers for same-model GPUs that cannot be uniquely matched are not guessed by name.

System RAM shows physical memory used/total, and Committed shows Windows committed memory/commit limit; Reviewer shows the total resident memory and private committed memory of its processes, respectively. Summed resident memory may count shared pages between processes more than once and cannot simply be subtracted from system physical memory. VRAM shows dedicated video memory usage. GPU commit is the Windows WDDM Total Committed allocation counter, which can be backed by dedicated or shared memory; it is not physical video memory usage and has no independent commit limit equivalent to physical video memory capacity.

CPU and memory update approximately once per second, and GPU approximately every two seconds. System metrics for uniquely identifiable NVIDIA GPUs are read through nvidia-smi; Windows GPU allocation and process metrics are read through WDDM performance counters. This application's GPU utilization aggregates its processes by engine and takes the busiest engine rather than simply adding multiple engines. Device rows use CPU, GPU, VRAM, and runtime device numbers as identifiers; interface separators distinguish metrics. Usage values with valid capacities or percentages use a green-to-yellow-to-red gradient. Because GPU commit has no independent fixed capacity limit, no usage percentage is fabricated from physical video memory capacity. Sampling occurs in the background, with driver-command timeouts. Metrics unsupported by tools, the system, or drivers show unavailable, which must not be interpreted as zero usage.

**Procedure:** Open Monitor before detection and record physical memory, committed memory, and video memory baselines. After starting a single task, observe their growth and GPU utilization before deciding whether to increase batch size or concurrency. Batch is the maximum number of frames per inference call; actual batches are also affected by Batch wait, decoding speed, and remaining frames. track_batch frame collection is also limited by Batch wait: when waiting expires, the collected partial batch is submitted. Thus, setting 4096 does not mean 4096 frames are input at once; the actual submitted count determines tensor and activation memory requirements for that call. Decoding speed, prefetch backlog, and the video tail all affect the actual count. Input dimensions generally undergo aspect-ratio-preserving resizing and stride alignment and are not necessarily an Image size square. Original video compression mainly affects decoding throughput and buffering; color conversion is distinct from model activation memory.

A successful first small batch does not guarantee that later batches will be equally small. Video memory exhaustion can occur independently of the system commit limit; available committed memory does not rule out display-driver timeouts or GPU faults.

Batch defaults to 32 in new configuration templates only as a starting point for trial runs, not a guarantee for every model and video memory capacity. Existing saved personal settings retain their original values. After switching models or increasing Image size, validate again from a smaller batch.

Mouse-wheel value changes are disabled in input fields; hovering over option labels shows English explanations, while hovering over input fields shows current contents. Interface settings are saved to the project's existing settings.ini. Parameters are not changed live for running tasks.

## 3.3 Two Parameter Categories

### 3.3.1 Inference: Parameter Changes and Rerunning Inference

- **Conf floor**: Upstream YOLO confidence threshold. Lowering it retains more candidates but may increase false detections and computation.
- **IoU**: Upstream YOLO NMS threshold, not the postprocessing matching IoU threshold.
- **Image size**: Inference size; use a multiple of 32.
- **Max detections**: Maximum upstream output count per frame. Verify that it is sufficient for dense scenes.
- **Augment**: Test-time augmentation, default False; support depends on the model and may be slower.
- **NMS**: Auto (None) preserves the model default; True uses ordinary NMS; False uses a native NMS-free detection head and requires model support. IoU is disabled in NMS-free mode. Older Ultralytics versions convert internally through end2end; their export-only nms parameter must not be treated as an inference switch.
- **Agnostic NMS**: Default False; means cross-class suppression in ordinary NMS and cross-class output selection in supported end-to-end detection heads.
- **rect=True** is fixed. When editing ends, Image size is rounded to the nearest multiple of 32, with ties rounded up; special models with larger strides may still receive further backend padding.
- Models, inference pipelines, and devices are also upstream settings.

Training info displays the weight save date, valid checkpoint epoch, last training-log epoch, readable cumulative duration, and training parameters. The checkpoint epoch may have been stripped; the training log may extend beyond the best weights, so these are distinguished. Duration is calculated from cumulative seconds fields in logs and omitted if unreadable; completed training time is not fabricated from the configured number of training epochs.

Changing these values does not modify an existing raw cache. Replay restores the upstream information recorded in the cache without calling YOLO. New parameters are written to new raw metadata.

### 3.3.2 Postprocess settings: Testing Directly with Raw Data

These parameters affect only custom stable IDs, recovery, position generation, and final cleanup, without rerunning YOLO. Detections discarded by upstream thresholds/NMS cannot be recovered from raw data.

## 3.4 Three Run Modes

| Mode | Purpose | Output |
| --- | --- | --- |
| Raw only | Completes expensive inference first and postpones postprocessing tuning | One SQLite project with raw data and metadata, but no final working rows yet |
| Raw + Postprocess | Runs inference while generating an initial postprocessed result | One SQLite project with raw, final, parameters, and provenance |
| Replay | Regenerates results using existing raw data | A new SQLite project containing copied raw data, recalculated final results, and parameters; the input file is read-only |

Both single-video and Batch tasks support all three modes. Batch tasks read settings when each actually starts; running tasks do not change parameters. Pausing/stopping commits completed cache frames; the unfinished tail is not a complete video.

Raw consists of detections already output by YOLO/tracker and saved before custom postprocessing; it is not unthresholded network tensors. Manual points and interpolated rows in working annotations cannot serve as raw data or restore candidates already discarded upstream.

**Selecting raw data:** Click **Choose raw**. If the currently open result contains embedded raw data, a prompt first asks whether to use it: **Yes** mounts raw data from the current result directly, **No** opens an external file dialog, and **Cancel** retains the original input. If the result has no embedded raw data, select an external cache or another result database with embedded raw data directly. Raw is displayed immediately after selection, without automatically computing postprocessing or replacing current working annotations. Raw IDs are italicized; the Raw / Preview suffix in Current frame reflects the actual source at the current frame.

When a cache is mounted, clicking **Choose raw** again exits Raw / postprocessing cache preview and returns to the formal review layer without deleting the cache. To replace the cache, exit and click again to select one. Parameter changes alone do not trigger replay; compute manually with Center here / Update / Full replay in Postprocess settings.

Parameter configuration and testing are in the separate **Postprocess settings** window. Before / After only prepares the range; Center here applies it and computes. Opening the window itself does not recompute. Completed intervals coexist with remaining Raw, and closing the window does not unload green range bands. Raw and results can both be explicitly edited; result changes are not written back to Raw by default. See [Postprocessing Tests](04_Detection_Postprocessing_Tests.md) for detailed Apply to Raw, Reprocess range, and Save preview workflows.

Follow progress follows detected frames. Boxes shown during detection are temporary results. During a run, the result database saves temporary postprocessed rows in batches; at completion, a transaction writes back data cleaned across the entire video. Use state in metadata to determine completeness. A rate of `0.45x` means approximately 0.45 seconds of video processed per second; paused time is excluded from active processing duration.

After normal detection completion, an empty review session may load results automatically; existing annotations still require confirmation. Load remains available for formal loading; previewing and preview edits do not mean current review data has been replaced.

## 3.5 Dual-Confidence Procedure

**Conf floor** in Inference is the low threshold for retaining candidate boxes; **Conf main** is the high threshold for normal matching and identity creation. With **Dual confidence** enabled in the Postprocess settings table, observations between the low and high thresholds only support confirmed identities; when disabled, Conf main is unavailable and processing uses the single Conf floor threshold.

Main detections complete all associations first, then low-confidence observations supplement identities that remain unmatched. The current implementation requires the same raw ID, matching class, reasonable distance and dimensions, and no clear competition from neighboring bees or duplicate detections. Low-confidence boxes do not create new IDs; they are real observations rather than interpolation and retain observed coordinates and original confidence. The diagnostic path shows `low_conf_support`. Filling short gaps remains controlled by Gap recovery; backfilling estimated positions is separately controlled by interpolation switches.

**Low Conf Max Seconds** limits how long an identity can continue using only low-confidence observations after the last main detection, defaulting to 1 second. Beyond this limit, low-confidence continuation stops rather than indefinitely retaining an old ID; a main detection resets the timer. This is a conservative trial starting point, not a validated optimal threshold. Existing Low Conf Hints are only reconnection scoring hints and cannot replace Dual confidence.

Conf main can be adjusted directly for replay. Lowering Conf floor can only use candidates already present in the raw cache; boxes discarded by YOLO or its tracker cannot be recovered through replay and require rerunning inference. Replay can reproduce the corresponding stream routing using the configuration saved in an existing cache. GUI editing sessions use these switch semantics: disabled means a single threshold; after Apply, `confidence_policy=dual_stream_v1` is saved. Existing sidecars and CSV are not rewritten, and the currently selected scene preset is not replaced.

## 3.6 Classes, Model Mapping, and IDs Groups

Class configuration is read at application startup. It can also be changed through Edit and Add / Remove in Display → Others → Classes, followed by Apply to save immediately and update class controls. Restart after editing settings.ini directly. Classes in saved projects are not automatically rewritten by configuration changes. Opening CSV / SQLite compares file classes and asks whether to add classes currently missing. See [Classes and Interface Language](14_Settings_and_Performance.md#1451-classes-and-interface-language).

```ini
[classes]
0=class1
1=class2
2=class3
3=class4

[id_groups]
1=class1
2=class2, class3
3=class4
```

Each classes entry uses a nonnegative integer YOLO output class number as its key and an annotation class name as its value. Class names must be nonempty and unique; multiple is reserved for mixed interface states, and names must not contain commas, semicolons, or vertical bars. Manual Change class, Box additions, and Tracking initial-class lists use this configuration; new detection results and YOLO ROI Assist use the same numerical mapping rather than inferring classes from devices or filenames.

Numerical id_groups keys determine top-to-bottom group order. Each entry can list multiple configured classes separated by commas, without assigning a class repeatedly. In the example above, class2 and class3 share the second table. Ungrouped classes, other classes in external files, and mixed identities spanning multiple groups appear in the automatically generated Other section; original classes are not deleted.

Postprocessing replay uses the class mapping and species-role numbers recorded in the raw file to prevent the current INI from reinterpreting historical raw data. Species-specific postprocessing retains the scope defined by its presets; other class combinations should use General or disable the corresponding species rules. This configuration does not automatically convert species-specific algorithms into models for other species.

## 3.7 Single-Video Procedure

1. Select a model in Inference, inspect Training info and classes, and confirm Conf floor, Conf main, IoU, Image size, Max detections, Augment, and NMS.
2. Select the device, half, batch size, pipeline, and output directory in Control.
3. First use a short video or trial run to check target scale, classes, candidate count, and actual device status.
4. Select Raw only or Raw + Postprocess and click Start; use Pause to suspend and Stop to terminate.
5. After completion, check results and sidecars. If review data already exists, load the result through the Load confirmation procedure.
6. When tuning postprocessing, replay the same raw input to isolate upstream changes; see the postprocessing test instructions.

Actual GPU use is determined by worker device detection and runtime information. half is limited by device, model, and runtime support; batch size and pipelines affect throughput and memory, and larger values are not guaranteed to be faster. CPU Workers are not multiple independent GPUs. Cache replay does not rerun the model; changing model parameters does not recalculate existing raw data.

## 3.8 Batch

Open Batch and use Add videos to add inputs; for Replay, select the corresponding raw caches. Set a common output directory or Output beside video, specify a concurrency limit or Auto, then click Start processing. Delay moves selected pending items to the queue tail, and Pause/Stop controls selected tasks; with nothing selected, operations apply to the corresponding entire queue. Each task reads settings when it actually starts; running tasks do not switch parameters live.

Auto treats Jobs as an upper limit. It starts one unmeasured job and waits for two batches and at least two seconds of progress before admitting another. Measured peak RAM and selected-device GPU memory receive a 25% allowance plus a system reserve; each subsequent model is warmed up separately. Resource probes run in the background. Missing GPU measurements keep jobs serial rather than using another GPU's free memory. GPU OOM halves inference Batch and retries the same frames in order; later batches and new Auto jobs use the reduced limit. Batch=1 or model-loading OOM is reported as a failure; admission control cannot recover a driver reset or guarantee memory against unrelated applications.

Concurrency adds video memory, memory, and disk requirements; validate with a few videos first. A failed task must not be treated as a complete detection result; check every task's status and output directory. Removal removes an item from the list and does not delete the original video.

## 3.9 Interpreting Results

Stable IDs are postprocessing association results; raw IDs are upstream tracking identities. Equal values do not guarantee that IDs in different trials refer to the same target. Distinguish observed positions, short-term holds, backfilled interpolation, and manual changes through source fields rather than box smoothness alone. Complete postprocessing parameters are saved in configuration snapshots for checking with identical input.

## 3.10 Control Parameters Explained

| Parameter | Purpose | Check After Adjustment |
| --- | --- | --- |
| Device | Selects the requested runtime device; auto is resolved by the backend | Actual detected device and video memory, beyond the selection text |
| half | Uses half-precision inference supported by the device/model | Correct output and improvement in video memory use and throughput |
| Batch size | Maximum frames processed by the model in one batch | Throughput, peak video memory, and per-frame wait |
| Pipeline | Selects the inference/integration pipeline | Whether the current mode supports the selected parallel parameters |
| Batch wait | Maximum wait in seconds for a partial batch; 0 waits for a full batch or video end | Small-batch latency and throughput |
| Workers | Number of parallel prediction workers in supported pipelines; process pipelines may load one model per worker | Video memory for multiple models and CPU contention |
| Follow progress | Makes the displayed image follow detection progress | Whether key intervals remain convenient to inspect |
| Output directory | Location of current detection results | Space, write permissions, and the actual newly created run directory |

The number of concurrent Batch tasks differs from Workers/Batch size within one task. Increasing both levels simultaneously may substantially increase video memory usage; “device usage is not full” should not be the sole justification.

## 3.11 Start, Pause, Stop, and Batch Selection

Start launches a task with the current settings; Pause suspends the active task while retaining its process and resources; Stop terminates the current run. Starting again after stopping generally creates a new run rather than unconditionally appending to the original cache tail.

In the batch window, Start/Pause/Stop prioritizes selected items; without a selection, it applies to the entire queue. Start can move selected pending tasks toward the front, while Delay moves them toward the back. Removing a running item stops it first; removing a queue entry does not delete disk output.

## 3.12 Complete Example: Retaining Candidates Before Tuning Association

1. Select a trusted model and configure Conf floor, NMS, and size in Inference.
2. Complete one inference run with Raw only and confirm cache coverage.
3. Load this cache with Choose raw and open Settings.
4. Keep upstream settings fixed and compare different Conf main, identity recovery, and position-generation switches.
5. Compare across Trials using the same original observations, then run Full replay when satisfied.
6. Check the complete video result before Load, proceed to manual review, and Save as.

**Numerical dual-threshold example:** Conf floor=0.10, Conf main=0.40, with Dual confidence enabled. A main observation at 0.70 can participate in normal association; a retained observation at 0.25 can only support an existing identity when constraints are met; an observation at 0.08 discarded upstream does not appear in the cache. Changing Conf main to 0.30 allows replay; recovering the 0.08 candidate requires lowering the upstream threshold and rerunning inference.

## 3.13 Acceptance Checks

Check video and cache identity, actual device, the upstream parameter snapshot, cache completeness, output location, and the distinction between raw/stable IDs. Spot-check dense targets, occlusions, rapid displacement, and class conflicts separately. Model detection confidence is not identity accuracy; longer stable IDs or smoother trajectories do not directly prove more accurate postprocessing.

## 3.14 Command-Line Detection

The main application provides a `detect` subcommand that calls the existing DetectionWorker without opening the Reviewer interface. Parameters are identical across platforms; see [Startup Commands](01_Basic_Operations.md#131-opening-videos-and-annotations-directly) for replacing the `Reviewer` entry point. Run `Reviewer detect --help` for command-line usage.

```text
Reviewer detect --video "videos/example.mp4" --model "models/model.pt" --output-dir "results" --report "batch.json"
Reviewer detect --video "a.mp4" --video "b.mp4" --report "batch.json"
Reviewer detect --input-list "videos.txt" --device cpu --mode raw-only --report "batch.json"
```

`--video` can be repeated and combined with `--input-list`; duplicate paths are processed only once. The list is UTF-8 text with one unquoted video path per line; relative paths in the list resolve against the list directory, while relative paths in the command resolve against the invocation directory.

```text
videos/a.mp4
videos/b.mp4
```

| Parameter | Behavior When Omitted |
| --- | --- |
| `--model` | Uses detection/model_path in settings.ini or the application's default model path; if the file is absent, reports an error without starting detection |
| `--output-dir` | Uses the configured detection output directory; creates a separate run directory per video without overwriting existing results |
| `--preset` | Uses the detection preset and saved postprocessing settings; loads the specified preset when explicitly supplied |
| `--device` | Uses the saved device, or auto if unset |
| `--mode` | Defaults to raw-postprocess; raw-only is also available |
| `--preview-end` | Last frame to process, with 0 meaning the entire video; defaults to 0 |
| `--report` | Specifies the batch result JSON; always specifying it is recommended for compiled packages and automated calls |

YOLO thresholds, input size, batch, pipeline, decoding, and class mapping reuse the application configuration. All input videos, the model, preset, and Worker are validated before the first task begins; missing required inputs or valid defaults cause an error without detection. Multiple videos run sequentially; if one Worker fails, the error is recorded and remaining items continue. Process exit code 0 means all succeeded; 1 means validation or task failure. The report contains `ok`, each video's input/output directory/exit code, and errors, and is also written on validation failure. This command performs detection only, without automatically opening review files or changing current interface inputs. For compiled packages without a console, inspect results in the report.
