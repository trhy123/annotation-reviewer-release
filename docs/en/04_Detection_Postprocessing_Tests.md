# 4 Detection Postprocessing Tests

[Return to the main contents](00_Annotation_Reviewer_User_Manual.md)

## 4.1 Input and State Boundaries

The input is a raw cache for the same video; local trials replay candidates and rebuild identity states without rerunning YOLO. The image, tables, selection highlighting, yellow bands, and Trail use the same browsing data source, without mixing in same-number IDs from the original review file. The settings window can be operated alongside the player and uses a separate taskbar window, with a default size of 840×810 (system scaling affects actual pixel dimensions).

Browsing and computation do not modify original review data. **Explicit Raw edits write to the selected cache**; edits to postprocessed boxes affect only a result copy and are not automatically written back to Raw. Back up the cache before editing Raw. See 4.5 and 4.8 for saving changes and replay rules.

## 4.2 Standard Test Procedure

1. Open the video, click **Choose raw** in Control, and select a cache for the same video; Raw appears immediately without automatic postprocessing computation.
2. Pause the player at the time to inspect and click **Settings**.
3. Enter the seconds to inspect before/after the current anchor in **Before (s)** / **After (s)**. These inputs only prepare the range, without clearing or recomputing the image; click **Center here** to apply the range around the current frame and compute. Choosing raw again does not restore an old absolute frame range; opening the settings window itself does not seek or compute.
4. Editing the table's **Current** column neither starts computation nor switches away from the current Raw / result image. When ready, click **Center here** to apply the before/after seconds around the current player position and compute; **Update** computes the already established interval. Other parameter changes, Use reference, and Apply / Close do not compute automatically. **Stop** in the Preview range row stops computation and retains results completed earlier.
5. **Updating preview…** at the top of the player indicates an update in progress. Calculated intervals may display temporary results before final cleanup, while uncalculated intervals continue showing original Raw / completed results. A new request cancels the old one; canceled, failed, or late results do not replace completed layers.
6. Completion automatically switches to Mixed without requiring Load. Processed intervals display postprocessed boxes, while the rest of the cache range still displays Raw; processed frames with no boxes remain empty rather than falling back to Raw. Recalculation of overlapping intervals replaces only the overlap and retains other results.
7. Click **Apply / Close** to save parameters when satisfied; run **Full replay** first when a formal result is required.

Preview computation has latency: dense targets, long intervals, or initial decoding may still require waiting. Use Showing and completion status to confirm which parameters correspond to the displayed image. Failure or stopping retains old results and explains the status in the window's status bar.

## 4.3 Table and Staged Trials

The table has four columns:

- **Parameter**: Parameter item; hover to see its function.
- **Current**: Editable current draft; preview buttons compute using this column.
- **Reference**: Editable reference copy; values differing from Current are pale yellow and do not rewrite their source file or Trial.
- **Showing**: Read-only configuration of the result currently displayed; values differing from Current are pale red. When computation retains an old image, this column still shows the old result parameters. Raw / Off has no postprocessing configuration and displays dashes.

Read-only Boolean values use √ / blank. Redundant trailing zeros are removed from numbers; selected cells have no emphasized border.

The Preset / Trial drop-down selects a preset file or staged Trial and copies it to Reference. **Selecting a source or editing Reference does not modify Current**; only **Use reference** copies it to Current, without starting computation. Selecting another source resets the temporary Reference copy. To retain a configuration's effect, use Use reference first, complete its preview with Center here / Update, then Keep trial. Parameters in the complete configuration that are not exposed in the table are retained rather than lost when editing visible parameters.

**View** controls what the player displays:

- **Mixed**: Uses the corresponding results for completed intervals and Raw elsewhere; different intervals may use different configurations, with Showing and HUD reflecting the actual current frame.
- **Trial 1…5**: Results and parameters saved by Keep trial. Switching Trials also displays their parameters in Reference without overwriting Current.
- **Raw**: Upstream boxes and raw IDs, not postprocessed stable IDs.
- **Changes**: Highlights differences in mixed results. ID renumbering alone does not count as a change; observations with unchanged box coordinates and classes are faded to 30%, while Raw boxes discarded by postprocessing are black and retain their IDs. Newly added estimated boxes are blue. Raw / Mixed buttons quickly return to Raw for comparison.
- **Off**: Disables the experimental layer and returns to the original review layer without unloading raw data.

**Keep trial** stages only completed, nonobsolete candidates, up to five sets; a sixth displaces the oldest. Editing a staged result creates a copy without rewriting the original Trial. Trial switching is retained only in the current video session and is not a long-term project archive; before switching videos, use **Save JSON** for parameters and **Save preview** for annotations to retain.

**Open JSON** copies a complete parameter snapshot to the draft; **Save JSON** exports current complete parameters without running the algorithm or loading/overwriting annotations. Saving a file is explicit, and clicking Cancel afterward does not delete it.

## 4.4 Apply and Closing the Window

- **Apply / Close**: Commits Current, before/after seconds, and other parameters while retaining the preview.
- **Cancel / close window / Esc**: Discards this parameter draft and cancels unfinished requests; retains completed results and green bands. It does not undo box edits, Apply to Raw, or saving already performed; use Undo / Redo for box edits.
- Independent files explicitly generated by Full replay/Save JSON are not deleted by canceling.
- Only formal **Load result** loads results into review data; unsaved-annotation protections remain effective.

The settings window is nonmodal and can remain open while playing and seeking in the video. Preview computation does not modify the reviewed SQLite file. With a cache mounted, click **Choose raw** again to exit cache preview and return to the review layer without deleting the cache file; another click afterward allows selection of another cache.

Both **Loop** controls use the same player state; closing or canceling the parameter window does not roll Loop back. Mixed / Trial loops within the current processed continuous interval without crossing boundaries between different runs; manually dragging into a Raw interval cancels looping to prevent playback from jumping back to the original interval. Pure Raw view loops over the cache's valid range.

## 4.5 Single-Individual Inspection, Recovery Markers, and Events

Single-click a box or table row to select a target and display highlighting, top information, Edit ID / Range / xywh, yellow range bands, and trajectories; a single click does not hide other individuals. Double-click a box to enter single-individual filtering; double-click blank space or click **Clear focus** to exit. HUD indicates the current state. Raw IDs, including those of discarded boxes, are consistently italicized; Raw and Preview table sources and IDs are distinguished in blue/green, and the Current frame suffix switches according to the current frame's source.

To inspect motion polylines, enable Trail Before / After in Display and select one or more IDs, using the existing trajectory length, style, and range controls. Both CPU and OpenGL previews use trajectories from the current source rather than inheriting old review identities; lines are not forced across missing frames, Raw / postprocessing boundaries, or different results. Dense back-and-forth polylines may suggest an ID switch for inspection, but cannot establish an error by themselves.

After selecting a box in the experimental layer:

- A brief English summary displays the stable ID, raw ID, observed/estimated status, detection index, and recorded association/rejection reasons.
- The corresponding upstream observation `(frame, det_index)` is followed; double-click filtering changes only display, while the backend still computes all targets without changing competition through single-individual input.
- Switching Trials finds the corresponding trajectory again through that observation rather than treating equal stable ID values in different configurations as the same individual.
- **Previous event / Next event** jumps to preceding/following association events recorded for the focused trajectory; **Clear focus** restores all boxes.

If a configuration suppresses the anchor observation, no corresponding trajectory may exist; use Clear focus and select a box again. Estimated boxes have no reliable original-observation anchor.

Label **R** marks the frame where recovery across missing frames occurs; **~** indicates an estimated position rather than a real detection. R indicates only that recovery was performed and does not guarantee correctness. Ordinary adjacent-frame association does not need a special marker on every frame. The Raw layer still displays raw IDs; clicking may also show Current diagnostics for the same original detection, explicitly labeled Candidate diagnostics and stale status rather than treating the raw ID as a stable ID.

When a local image has no boxes, first confirm that the current frame lies within the window's displayed Frames range, then check whether focus is enabled rather than immediately assuming a missed detection.

### 4.5.1 Editing Raw and Results

Select boxes to identify the source first, then specify ID, Range, class, or xywh in the existing Edit panel and execute the operation. Same-number Raw IDs and stable IDs in different results are not merged into one identity; editing affects only visible records of the current source. Black boxes in Changes still belong to Raw.

Ctrl / Shift adds selections, and rectangular selection in Box also uses current browsing data. Multiple-selection highlighting, yellow range bands, and Trail distinguish sources. Same-number IDs can be inspected side by side, but selections spanning Raw / different runs cannot be batch-edited directly as one numerical ID; select a single source first to avoid changing unrelated data. Merging retains the existing options for which side to keep on overlap and whether to interpolate.

- Edit Raw: Writes detection rows to the cache while retaining original detection indices; added detections receive new indices to prevent old result provenance from pointing to new boxes. The corresponding cache can be edited only after inference stops.
- Edit Preview: The first change creates a result copy and modifies only postprocessed results. Manually added positions are blue estimated boxes.
- **Apply to Raw**: Explicitly applies manual coordinate/class changes, deletions, and added positions from the current result to Raw; stable ID renumbering is not treated as a Raw ID change, and all algorithm output is not automatically copied over Raw.
- **Undo / Redo**: Undoes/redoes preview edits in the current session, without affecting original review history. Canceling the settings window does not undo box edits.
- **Save preview**: Saves as ordinary annotation SQLite; afterward, Load result allows normal reviewing, editing, and export.

Interpolation and swap operations also respect selected-source boundaries; do not treat same-number IDs in Raw and different results as endpoints. Temporary layers under computation cannot be edited directly: Stop first, then reselect a completed result or Raw.

### 4.5.2 Range Bands and Manual Recalculation

Blue indicates the Raw range, green loaded postprocessed ranges, and pale green computation progress; yellow independently indicates visible records of currently selected identities. Trajectories do not force connections across missing frames or Raw / different-result boundaries.

After modifying Raw, a brown-red pending-update band is added beneath **directly modified frames** only in loaded results. Green remains, and both bands can coexist. Brown-red uses the Merge Source band's position and width, while green uses Merge Target styling; closing the settings window does not hide completed ranges.

After completing continuous editing, click **Reprocess range** to recalculate affected result intervals using each interval's saved configuration with preceding context, rather than automatically computing after each edit. Success clears the corresponding brown-red markers; failure or cancellation retains them. Unaffected intervals are not replaced. A prompt appears before replacing manually edited result copies; use Save preview or Apply to Raw first if needed.

Brown-red marks only directly changed positions and does not imply that later associations are entirely unaffected. Recalculation operates on the corresponding loaded result interval; final whole-video consistency still requires Full replay.

## 4.6 Identity Continuity and Geometric Position Controls

Changes in box coordinates and ID switches are separate problems.

| Parameter | Effect and Tradeoff |
| --- | --- |
| Preserve observed boxes | Keeps upstream coordinates for real observed boxes and disables compatibility adjustments that move/resize them; cannot eliminate YOLO's own jitter |
| Gap recovery | Master switch for all identity recovery across missing frames; disabling retains adjacent-frame association but increases track breaks |
| Position hold | Whether to output placeholder boxes briefly during absence; separate from identity memory |
| Gap interpolation | Whether to backfill estimated boxes after recovery; separate from recovering identity |
| Clear raw aliases | Releases old mappings after raw ID changes to prevent residual ownership from competing later |
| Guard missing owners | Prevents missing targets from suppressing new observations solely through old boxes |
| Guard raw continuation | Checks geometry and identity competition even when raw ID is unchanged; stricter checks may break tracks |
| Guard gap assignment | Checks ambiguity during recovery from absence without further tightening ordinary adjacent-frame matching |
| Conservative assignment | Applies strict checks to all associations and may increase track breaks; not a required master switch for the preceding four protections |
| Overlap ID reuse | Allows identity reuse based solely on overlap paths, with a risk of ID switches |

General relink is only one recovery path. After disabling it, raw ID continuation, short-interval matching, drop, static, occlusion, and global paths may still recover identities. Use Gap recovery to prohibit all recovery across missing frames.

DORMANT_STATIC_SECONDS and HORNET_IDENTITY_MEMORY_SECONDS control memory duration; MAX_LOST_SECONDS and HORNET_POSITION_HOLD_SECONDS control placeholder duration. Interpolation limits are separately controlled by MAX_INTERP_SECONDS, MAX_DROP_INTERP_SECONDS, and related switches.

First fix upstream and other parameters and compare only Preserve observed boxes, then inspect the effects of recovery switches and ambiguity checks separately. Do not tighten all thresholds simultaneously; when incorrect continuations decrease, also inspect track breaks and lost recovery of real falls. Preserving original coordinates does not resolve identity swaps by itself.

## 4.7 Presets and Complete Parameter Snapshots

- **General.json / General**: General basic association, with wall-scene species rules and position-filling operations disabled, without assuming that all targets are honeybees/hornets; class names come from model or raw metadata.
- **bee_hornet_revised.json / Bee / Hornet wall**: Retains original wall-scene class protections and recovery rules, preserves observed coordinates, releases old ownership, and adds independent protections; retains short position holds and disables post-recovery backfill interpolation by default.

These are experimental starting points, not guarantees of optimal parameters for every video.

The application reads JSON preset fields in the root presets_detection folder as names and reads default flags; scene names are not fixed in code. The old Default identifier is recognized through compatibility aliases within files. Saved complete older parameter snapshots restore their recorded values rather than silently changing algorithms when a same-name preset file is updated. To adopt a file preset, select the source in Preset / Trial, then click Use reference and Apply / Close.

settings.ini saves parameters and selections, not Python algorithms. Presets are data files and do not execute arbitrary Python code.

## 4.8 Local Trials, Whole-Video Results, and File Safety

Local trials include at least 15 seconds of preceding context, increased if identity memory is longer, plus 2 seconds at the end. Only the selected interval is displayed. Finite context cannot guarantee stable ID numbering and final cleanup identical to whole-video processing.

**Full replay** computes from the cache start through the last committed frame, performs final cleanup, displays the result automatically, and generates an independent result SQLite file. An incomplete cache limits processing to the existing range; missing frames are not fabricated and YOLO is not automatically rerun.

When `实验5/csv` is selected as the output directory, trial results are written to the sibling `实验5/postprocess_lab`. Local trials save a temporary preview.sqlite; whole-video results save a self-contained SQLite project containing raw, final, preview, and diagnostic tables, with configuration and provenance in metadata. features.sqlite is a rebuildable working cache.

**Save preview** saves current browsing data to a new annotation SQLite file and writes a `.postprocess.json` provenance description. If different sources happen to use the same ID, saving assigns nonconflicting numbers while retaining original IDs and source fields. Black comparison boxes in Changes are not saved as additional postprocessed results. Saved local trials mixed with Raw are not exact whole-video postprocessing; source intervals, configurations, and pending-update frames are recorded in metadata.

Save preview saves the preview layer rather than the formal review layer active before previewing. With unsaved review changes, **Load result** offers Save (saves the formal review layer), Discard (abandons that layer's unsaved changes and loads), or Cancel (does not load). If asynchronous saving is unfinished, wait before clicking Load result again; saving the preview does not clear the formal review layer's unsaved marker.

Previewing does not rewrite the original video, Boutlist, or original reviewed annotations. Raw changes only through explicit Raw edits or Apply to Raw; result edits use copies. Stopping/canceling the parameter window does not delete explicitly saved files.

The persistent replay process reuses raw input and image features independent of association parameters. Every trial resets identity state rather than reusing trajectories computed with old parameters. The decode cache has limited capacity and cannot guarantee immediate completion of long windows.

Before final review or export, use Full replay and inspect identity continuity yourself. Smooth boxes or a reduced total ID count alone do not prove correct association.


## 4.9 Parameter Groups and Validation

Both General and bee_hornet_revised presets enable **Conservative Assignment** by default. It checks geometric plausibility and neighboring identity competition during adjacent-frame association as well as reconnection after absence; competition checks are not relaxed merely because another detection in the current frame already occupies a neighboring identity. This switch cannot guarantee correct handling of every crossing or occlusion and may trade a moderate number of track breaks for fewer incorrect connections. Position placeholders and gap interpolation need not be reenabled to obtain these constraints. Complete parameter snapshots already saved in settings are not silently overwritten by preset files; use Use reference followed by Apply / Close when needed.

The model's Conf floor determines the lower candidate threshold in raw data. Conf main and Dual confidence determine how replay uses existing candidates; Low Conf Max Seconds limits continuous support using low-confidence observations alone. Lowering the former generally requires new inference, while the latter can be replayed directly when the cache contains corresponding observations.

The table displays module switches and main parameters. English parameter explanations are read from the current preset JSON's `tips` dictionary. Empty, missing, malformed, or unreadable entries display `--`; reopen the parameter window after modifying a preset file to reread it. Input-control hovering still shows only the current value. Undisplayed configuration items remain in complete parameter snapshots. Record Current before changing parameters; retain completed results with Keep trial and compare different trials through the same original observation.

**Example: a stationary honeybee is briefly occluded.** Fix the raw input and first compare Gap recovery on/off. Identity recovery is separate from placeholder generation: to retain identity without guessing position, keep recovery and identity memory enabled while disabling Position hold and Gap interpolation. Inspect the R marker and source observation at recovery to confirm that the trajectory has not connected to a neighboring honeybee.

**Example: a low-confidence tail.** With Dual confidence enabled, high-threshold detections establish identity, while observations between thresholds only support confirmed identities. Enabling Low conf geometry fallback removes the same-raw-ID requirement but still requires class, size, prediction residual, bidirectional competition, and unique-ownership checks to pass; uncertain matches are rejected and no new trajectory is created. Disabling it retains the older same-raw-ID restriction. Continuation stops after Low Conf Max Seconds, with the timer reset when a main detection appears. This mechanism draws on ByteTrack's second association round without adding position interpolation; detections not saved upstream cannot be recovered through replay.

**Example: boxes remain but identities repeatedly break.** Retain unconfirmed observations separates identity confirmation from detection retention: if a new identity is unmatched again before reaching its confirmation count, real observations already output are retained rather than removed solely for that reason. ID changes are permitted, but nonexistent empty segments are not created and genuinely missing frames are not filled. Confidence filtering, explicit duplicate suppression, and Ghost rollback can still remove candidates; retaining short observations may also increase visible false detections and requires checking. General and bee_hornet_revised enable this by default while disabling Position hold and Gap interpolation.

**Example: blurred, densely neighboring honeybees.** Fixed postprocess NMS uses a fixed Custom NMS IoU without strengthening suppression in response to full-frame blur or calculating full-frame blur for this rule. It does not change upstream YOLO NMS. Lower Custom NMS IoU strengthens overlap suppression; do not lower it in an attempt to reduce missing boxes. Boxes removed at this step record custom_nms as the diagnostic reason. Disabling the switch reproduces the older blur-adaptive rule.

New options are supplied by preset files; older complete configuration snapshots missing them use compatibility behavior rather than silently changing how older results are reproduced. After importing an older snapshot, explicitly enable the options above to use the new mechanisms. Saving, replay, and sidecars all record effective switches. The current Windows settings enable these three options and disable Position hold; older running processes need to reload configuration to avoid overwriting the file with old in-memory settings on exit.

ID numbers in local windows must not be used as whole-video identity numbers. Final parameters require Full replay and whole-video verification before formal Load result, review, and saving.

## 4.10 Additional Module Switch Descriptions

| Switch | Function and Explanation |
| --- | --- |
| Dual confidence | Separates main and low-confidence observation streams; low-confidence observations do not independently establish new identities |
| Low conf geometry fallback | With dual streams enabled, permits raw ID changes and supports confirmed identities after strict geometry and bidirectional competition checks |
| Retain unconfirmed observations | Retains measured rows when an unconfirmed identity becomes unmatched; does not fill missing frames |
| Fixed postprocess NMS | Keeps the postprocessing NMS threshold independent of full-frame blur |
| Species rules | Applies scene rules for honeybees/hornets; verify class meanings in general scenes |
| Drop relink | Recovery path based on falling-motion cues |
| General relink | Ordinary reappearance association path; disabling does not disable other recovery paths |
| Duplicate suppression | Suppresses duplicate candidates; check for incorrect suppression of real neighboring individuals |
| Hornet occlusion | Hornet occlusion protection and recovery rules |
| Dormant static relink | Reconnects briefly missing targets using long-term stationary history |
| Capped interpolation | Limits estimated spans using interpolation time caps |
| Separate identity memory | Distinguishes identity recoverability duration from position-placeholder output duration |
| ROI similarity | Uses local image similarity to assist identity association, increasing image-processing work |
| Low conf hints | Assists scoring with low-confidence cues, distinct from Dual confidence's direct support path |
| Global relink | Performs global competitive matching for multiple targets awaiting recovery |
| Post ignore | Executes corresponding postprocessing exclusion rules |
| Ghost rollback | Rolls back brief suspected ghost trajectories highly overlapping their host; check real short trajectories |

See “Identity Continuity and Geometric Position Controls” in this chapter for other protection, position-hold, interpolation, and observation-preservation switches. Switches have prerequisites: when overall recovery is disabled, enabling an individual recovery path does not allow continuation across missing frames.

## 4.11 Main Visible Numerical Parameters

| Parameter | Units / Controlled Behavior | Main Effect of Increasing |
| --- | --- | --- |
| MAIN_DET_CONF_THRESHOLD | 0–1 main detection threshold | Fewer main observations; potentially a higher proportion of low-confidence support |
| LOW_DET_CONF_THRESHOLD | 0–1 usable low threshold, which must not exceed the main threshold | Excludes more low-scoring candidates |
| LOW_CONF_MAX_SECONDS | Seconds, maximum support by low confidence alone | Allows longer low-score continuation |
| MAX_LOST_SECONDS | Seconds, ordinary loss/placeholder-related window | Longer retention; check for lingering boxes |
| RETRIEVAL_WINDOW_SECONDS | Seconds, reappearance candidate retrieval window | More historical candidates and opportunities for incorrect continuation |
| DORMANT_STATIC_SECONDS | Seconds, stationary identity memory | Longer retention, without necessarily outputting a box every frame |
| HORNET_IDENTITY_MEMORY_SECONDS | Seconds, hornet identity memory | Association remains possible after longer absences |
| HORNET_POSITION_HOLD_SECONDS | Seconds, hornet position hold | More estimated placeholders, without increasing image measurements |
| MAX_INTERP_SECONDS | Seconds, maximum ordinary interpolation span | Longer gaps can generate estimated rows |
| MAX_DROP_INTERP_SECONDS | Seconds, maximum falling interpolation span | Allows longer bridges during falls |
| STATIC_MAX_DISPLACEMENT_FACTOR | Stationarity criterion relative to target scale | More permissive classification as stationary history |
| STATIC_RELINK_DIST_FACTOR | Stationary reconnection distance relative to scale | Broader candidate range and greater neighboring-bee ambiguity |
| STABLE_MATCH_DIST_FACTOR | Stable association distance relative to scale | Accepts larger displacements |
| STABLE_MATCH_IOU_MIN | Minimum overlap constraint | Stricter overlap requirements; fast targets may develop track breaks |
| MATCH_COST_GATE | Association cost threshold | Broadens acceptance according to the current cost definition |
| ASSIGNMENT_AMBIGUITY_MARGIN | Required difference between competing candidates | More strictly rejects unclear correspondences |
| ADJACENT_RESIDUAL_FACTOR | Allowed geometric residual ratio for adjacent association | Permits larger residuals; check for ID switches |

Time parameters are converted to frame-related windows using the current video FPS; actual boundaries are also limited by module switches, other geometry/class thresholds, and confirmed status. No single parameter is a master “missed-detection tolerance” control.

Complete JSON includes additional advanced parameters not exposed in the table. Editing visible items does not discard them; retain a complete snapshot when changing advanced values and validate through the same local-preview and whole-video replay procedure.

## 4.12 Comparative Test Examples

### 4.12.1 Distinguishing Geometric Jitter from Identity Jumps

First fix all association thresholds and compare only Preserve observed boxes. If jitter still follows raw boxes, the issue mainly originates in upstream geometry; tightening reconnection thresholds cannot repair pixel positions. If positions are stable but IDs swap, inspect competition and missing-target recovery diagnostics.

### 4.12.2 Another Bee Passes a Stationary Bee

Keep one Current configuration as a Trial; compare Guard missing owners, Clear raw aliases, and Guard gap assignment separately. Click the same original observation to follow the target and check whether the original stationary identity suppresses new observations at its old position, old raw mappings persist, or recovery R markers connect incorrectly. After comparison, validate the whole video with Full replay.

### 4.12.3 Empty Cache Tail

If raw data has been committed only through frame 8000, Full replay can process only the available range. No boxes beyond the tail in a preview window does not mean the model missed every target in the latter part; first check cache completion status, then decide whether to rerun inference or analyze only the completed segment.

## 4.13 Algorithm Pipelines in Presets

Each preset JSON's `pipeline` describes three execution sequences:

| Sequence | Default Order | Function |
| --- | --- | --- |
| frame | prepare → camera_motion → association → low_confidence → observed_rows → lost_tracks → publish | Per-frame candidate preparation, motion estimation, identity association, low-confidence continuation, result rows, lost-track maintenance, and publication |
| relink | hornet_resume → general_relink → drop_relink → static_relink | Recovery-strategy priority for unassigned candidates; the first successful strategy ends this search |
| finalize | trim_terminal → ghost_rollback → post_ignore → dedupe → first_last → sort | End-of-segment tail cleanup, rollback, postprocessing, deduplication, first/last flags, and sorting |

frame and finalize have data dependencies and cannot be reordered arbitrarily; missing, duplicate, unknown, or dependency-violating stages cause configuration loading errors. relink strategy order can be adjusted but remains constrained by corresponding module switches and score/geometry thresholds. All algorithms share the current video's identity memory.

**Example:** If both general_relink and drop_relink can propose candidates, placing the former first prioritizes it; swapping their order may change identity recovery results. Perform comparative tests on the same raw cache, inspect actual output, then select a configuration. Existing presets retain the original computation order.
