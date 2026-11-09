# 1 Basic Operations

[Return to the main contents](00_Annotation_Reviewer_User_Manual.md)

## 1.1 Scope and Input Preparation

Annotation Reviewer is used to view videos and frame-by-frame annotations, correct identities, positions, and trajectories, and record segment events and spatial calibration. Videos, automatic annotation SQLite files, manual Tracker trajectories, and raw detection caches are separate sources; opening one does not mean that the others have been matched or aligned.

When preparing files, retain the original videos and annotation files. Use separate filenames for manually reviewed results. Check the actual loaded paths in File rather than identifying a segment solely by similar filenames in the window.

| Input | Purpose | Items to Check |
| --- | --- | --- |
| Video | Provides frame-by-frame images | Recording segment, resolution, first and last images, decoded frame count |
| Annotation file (SQLite / CSV) | Stores annotation information (boxes, classes, IDs, etc.), metadata, and edit records | Frame numbers, correspondence with the video, coordinate units |
| Manual trajectory (Tracker project .trk / converted CSV) | Provides manual identity and position references for Match | Whether the original video is reversed, manual trajectory frame rate, alignment frame |
| raw SQLite cache | Replays Detection postprocessing | Original video path, committed frame range, upstream inference parameters |
| Boutlist CSV | Organizes segments and metadata in batches | Field mapping, paths, record uniqueness |

## 1.2 Starting the Application and Identifying Windows

### 1.2.1 Running from Source

Open a terminal in the project root and run `python -m app.launch` in a Python environment with the project dependencies installed. On Windows, use `start_annotation_reviewer.bat`; it changes to the project root and preferentially invokes `pythonw.exe` from PATH, falling back to `python.exe` if unavailable. Use `python` with a console when debugging startup errors.

The startup script sets the runtime cache path `PYTHONPYCACHEPREFIX`, which supports relative paths. The main process and Python Workers that inherit its environment write bytecode caches centrally to the current project's `PYTHONPYCACHEPREFIX`, currently `.pycache/` outside the directory. After moving the entire project and running the script from its new location, the cache is also generated relative to the new project location; existing `__pycache__` directories must still be deleted manually. To use the same policy when starting directly from a terminal, set this environment variable in the project root before running the application.

The source-build window title includes the process PID, for example `Annotation Reviewer GUI [12540]`, to distinguish multiple open instances. After loading a video or bout, the title also displays file/bout information; an asterisk indicates unsaved changes to the working data.

### 1.2.2 Running a Release Package

Run the main application in the release package. Detection tasks are executed by a separate DetectionWorker; retain the dependency directories, presets, media runtime, and detection subprocess rather than copying only the main EXE. The `presets_detection/` directory in the release package root is the shared preset source for the GUI and Worker.

### 1.2.3 Locating the Configuration File

The configuration file is named **settings.ini**. If it cannot be found or read at startup, or lacks a usable class configuration, the application first displays the expected path and the options **Locate settings.ini…**, **Use defaults**, and **Cancel**. The selected INI file is copied to the displayed path and takes effect before the main window reads Class and other settings; the original remains unchanged. Use defaults uses the template bundled for the current platform, and Cancel cancels startup. An existing unusable configuration is backed up before replacement.

On macOS, `settings.ini` alongside the `.app` still takes priority; if absent, `~/Library/Application Support/AnnotationReviewer/settings.ini` is used. The location dialog explicitly displays the destination used for this launch and does not write configuration inside the `.app`. The GUI and DetectionWorker share this path and the platform template inside the Bundle. After selecting a configuration from another location, relative model, cache, and output paths are still interpreted relative to the destination configuration directory.

| Run Mode | Configuration Location and Handling When Missing |
| --- | --- |
| Source, all platforms | `settings.ini` in the project root; if missing, prompts for a file and copies it to the project root |
| Windows / Linux portable package | `settings.ini` alongside the main executable; if missing, prompts for a file and copies it to the executable directory, without automatically reading Roaming or Linux user configuration directories |
| macOS compiled package | A configuration alongside the `.app` takes priority; otherwise uses the Application Support directory above, and if still missing, prompts for a file and copies it to that user directory |

The DetectionWorker subdirectory is not a separate configuration location. Use defaults adopts the class definitions in the platform template; locate the original configuration to retain the original project's classes and groups. When the configuration is missing, a file must be located, defaults selected, or startup canceled; the application does not silently adopt another project's configuration.

## 1.3 Opening Files

### 1.3.1 Opening Videos and Annotations Directly

1. Open a video using the Open menu at the bottom.
2. Check the first frame, last frame, and current total frame count; monitor status messages while the index is being built.
3. Open the corresponding annotation SQLite file. If import processing options appear, check the source and import method before proceeding.
4. Check the paths of the video and each annotation source in File, and compare box positions with the image in Current frame.
5. Check image–annotation correspondence at least at the beginning, middle, and end.

`Auto open corresponding file` attempts to find corresponding files in the same folder and Boutlist, and prompts for a selection when multiple related files are found. In addition to confirming that the required file or file version is selected, check the source list and box colors/IDs when loading multiple sources.

File paths can also be appended directly to the startup command to open them in **normal mode**, without enabling the verification panel or using an automatically discovered `review_queue.csv`. All platforms use the same parameters; `Reviewer` below is a placeholder for the startup entry point and should be replaced according to the run mode:

| Run Mode | Replace `Reviewer` With |
| --- | --- |
| Source, all platforms | `python -m app.launch`, executed in the project root |
| Windows compiled package | `./AnnotationReviewer.exe` or the full executable path |
| Linux compiled package | `./AnnotationReviewer` or the full executable path |
| macOS compiled package | `./AnnotationReviewer.app/Contents/MacOS/AnnotationReviewer` or its full executable path |

```text
Reviewer "data/annotations.sqlite" "data/video.mp4"
Reviewer --annotation "data/annotations.sqlite" --video "data/video.mp4" --manual-track "data/manual.trk"
```

Annotations, video, and `.trk` files may appear in any order, and any one type may be supplied on its own. When both annotations and video are explicitly specified, they are used directly without requiring Boutlist or using it to locate or replace files. When only one file is supplied, the normal corresponding-file settings still determine whether a corresponding file is found automatically. Relative arguments are resolved against the working directory at invocation; quote paths containing spaces. The general Windows startup script `start_annotation_reviewer.bat` remains available and accepts exactly the same parameters.

Use `--manual-track` (alias `--trk`) for manual trajectories; the `.trk` and manual trajectory CSV / TXT / TSV formats available through the normal opening interface are supported. Manual trajectory CSV and annotation CSV share the same extension, so their roles must be specified explicitly using parameters. Opening follows the normal manual trajectory metadata confirmation dialog: check frame rate, reversal, alignment, and spatial settings rather than automatically assuming they match the video. `--raw-cache` mounts a raw detection SQLite file and uses its video matching checks; a raw cache is not treated as a manually reviewed result.

```text
Reviewer --video "data/video.mp4" --manual-track "data/manual.csv"
Reviewer --annotation "data/annotations.sqlite" --video "data/video.mp4" --raw-cache "data/raw.sqlite"
```

On macOS, the system `open` command can also be used with the same parameter names; absolute paths are recommended: `open -n "/path/AnnotationReviewer.app" --args --review-queue "/data/review_queue.csv"`.

### 1.3.2 Opening from Boutlist

1. Configure column name mappings in Display → Boutlist fields first.
2. Click Open Boutlist and select a record.
3. Check the video, detection file, and manual trajectory paths; unavailable sources may remain empty.
4. Check Start, End, Capture, manual trajectory alignment, and the scale summary.
5. If multiple candidate records refer to the same file, explicitly select the current bout; do not synchronize metadata from another row to the current segment.

See [Creating and Using Boutlist](13_Creating_and_Using_a_Boutlist.md) for field formats, example tables, and synchronization procedures.

### 1.3.3 Closing or Replacing Source Files

The file selector in File specifies the source to operate on. Select replaces a file, while Close removes the corresponding source data from the current session; it does not delete the original file on disk. Closing a raw cache only detaches the cache association. Closing the video or using Close at the bottom, after handling unsaved-change prompts, clears this video's data, selected identities, input ranges, endpoints, events, templates, Camera anchors, staged drafts, and previews; parameter thresholds, rendering mode, and other application settings are retained. Before replacing a video or closing a session, finish uncommitted edits and handle the unsaved-result prompt.

### 1.3.4 Video Indexing and Image Identity

When opening a video, the application builds or reads a video index in the background and numbers actual decoded images sequentially. Starting the indexing task does not mean that it completes immediately; initial indexing time depends on image count, encoding, storage speed, and processor load. An existing index cache can be reused directly when the source is unchanged and the cache remains applicable.

Existing annotations use frame numbers in decoding order; not every row needs to store a temporary image reference. Temporary references record the actual images associated with edits before index reconciliation is complete; an empty reference does not indicate that the frame has not been indexed. When the video contains timestamp gaps, the application reconciles relevant edits through image identity rather than inserting fictitious frames according to gap duration.

Save / Save as waits for unfinished indexing and edit reconciliation. Saving continues after completion; if indexing fails or image identity cannot be uniquely confirmed, edits are retained and the reason is reported. If the annotation file is replaced while waiting, queued save and Boutlist synchronization requests for the original file no longer apply to the new file.

Indexing uses the actual number of decodable images rather than treating the container packet count as the frame count. When timestamp-based seeking is unreliable, decoding starts from the beginning of the video and counts images. See [Undo and Recovery](12_Undo_and_Recovery.md#1253-saving-before-image-identity-verification-is-complete) for result verification and recovery procedures.

### 1.3.5 Review Queue and Navigation Interface

**Review queue** is positioned on the right of the window. Its default requested width is defined only by `DEFAULT_QUEUE_WIDTH` in `ui/review_queue.py`; it can be widened by dragging, floated, or closed. Actual width is also constrained by button text and available window space. It occupies the available width of the video area; **Right panel W** for the parameter panel is set independently in pixels and is not limited to a percentage of the main window width.

The top table lists all verification entries, showing **Bout ID, Frames, Kind, Reason, Status, Phase, IDs, Annotation file, Video file** in order. The entire current row is highlighted. Clicking another row loads files, seeks to the start frame, selects relevant IDs, sets the shared Range to the verification segment, and disables All IDs / All frames. In a narrow window, scroll horizontally to view later columns, or hover to view full contents. Detailed information about the current entry appears below the table, with buttons fixed at the bottom; drag the divider between the table and details to adjust their sizes.

Buttons, titles, column names, built-in statuses, and phases use the language selected in Display → Others → Language, which applies immediately without reopening the document; save Others or All to keep the choice for the next run. English is the default. User-entered kinds and reasons remain in their original language. CSV `status` continues to use the stable internal values `pending`, `normal`, and `corrected`, displayed in English as Pending, Normal, and Fixed, and in Chinese as “待核验”, “正常”, and “已修正”.

**Startup Methods**

For **verification of an entire list**, use `--review-queue` rather than passing the verification CSV directly as an annotation file. Replace `Reviewer` with the entry point described under “Opening Videos and Annotations Directly”:

```text
Reviewer --review-queue "data/review_examples.csv"
Reviewer --review-queue "data/review_examples.csv" --review-index 1
```

For example, from the current source project root, run the following to open the list in the sibling `review_examples` folder:

```text
python -m app.launch --review-queue "../review_examples/review_examples.csv"
```

A full path can also be specified, for example `--review-queue "E:\实验课题-王天一\胡蜂的诱捕行为\胡蜂蜜蜂实时距离\模型与检测程序\annotation_reviewer_gui\review_examples\review_examples.csv"`. The panel displays all entries; click rows or use Prev / Next to verify them individually. Normal / Fixed / Pending writes statuses back to this list. The removed scripts were dedicated scripts tied to specific experimental paths; the general startup script and list interface remain available. Opening an entry does not itself modify annotations.

Placing `review_queue.csv` in the source root or alongside the executable also enables it automatically at startup. Explicit arguments take priority; this window is not shown when neither a file nor arguments are present. Indices start at 0. On macOS, the default list location is the application's writable data directory.

Verification navigation **does not require Boutlist**. Without preparing a queue CSV, the annotation, video, and verification target can be specified directly:

```text
Reviewer "data/annotations.sqlite" "data/video.mp4" --review --start 100 --end 150 --ids "4,5"
Reviewer --annotation "data/annotations.sqlite" --video "data/video.mp4" --trk "data/manual.trk" --review --start-frame 100 --end-frame 150 --ids "4,5"
```

`--start` / `--start-frame`, `--end` / `--end-frame`, and `--ids` also enable verification mode. Start and end frames are 1-based; IDs can be separated by commas, semicolons, or spaces. This mode opens a verification panel with one target and sets the shared Range and IDs to the specified values. Because no queue CSV exists, Normal / Fixed / Pending statuses are retained only for the current session and no file is generated automatically. Use `--review-queue` to save these statuses. Use queue mode and direct target parameters separately to avoid conflicting inputs.

| Parameter | Function |
| --- | --- |
| `--annotation PATH` | Opens annotation SQLite / CSV |
| `--video PATH` | Opens a video |
| `--manual-track PATH` / `--trk PATH` | Opens manual trajectories |
| `--raw-cache PATH` | Mounts a raw detection cache |
| `--review-queue PATH` | Opens the complete review queue; cannot be combined with direct file arguments |
| `--review-index N` | Initial list entry, with indices starting at 0 |
| `--review` | Creates a single-target verification panel for directly specified annotations |
| `--start N` / `--start-frame N` | Start frame; defaults to 1 |
| `--end N` / `--end-frame N` | End frame; defaults to the start frame |
| `--ids TEXT` | Selects target IDs; enclose multiple IDs in the same pair of quotes |

- **Prev / Next**: Switches entries; the table can also be clicked directly.
- **Start / End**: Seeks to the current segment's start/end frame. Playback and frame stepping still use the original Reviewer controls.
- **Normal / Fixed / Pending**: Writes the verification result to the list CSV and moves to the next entry. These buttons do not automatically modify annotations. **Fixed** requires unsaved annotation edits to be saved first.
- Switching annotation files retains the normal save prompt; canceling the switch keeps the original entry selected in the table.

**CSV Format and Programmatic Calls**

The required field is `detection_file` (`annotation_file` is also supported). Common fields are:

| Field | Contents |
|---|---|
| `trial_id` or `bout_id` | Experimental segment identifier |
| `start_frame`, `end_frame` | Target frame range, starting at 1 |
| `kind`, `reason` | Chinese kind and specific reason for verification |
| `phase`, `status` | Phase and verification status |
| `track_id`, `other_track_id`, `target_ids` | IDs to select; `target_ids` accepts comma, semicolon, or space separators |
| `detection_file`, `origin_video_file` | Annotation and video paths, absolute or relative to the CSV |
| `manual_track_file` (or `trk_file`), `raw_cache` | Optional manual trajectory and raw cache paths, also resolved relative to the CSV |

CSV uses UTF-8 and supports a BOM. Extra columns are preserved when reading and writing back. The application does not automatically translate English reasons in arbitrary older lists; new lists should enter `kind` and `reason` directly in Chinese.

Call from an already running Reviewer main window (must run on the GUI thread):

```python
from app.review_launch import open_review_queue
dock = open_review_queue(window, queue_path, index=0)
```

This interface replaces any existing verification window while retaining normal annotation loading, saving, and undo functionality. External analysis programs can invoke it through startup parameters without copying experimental analysis code into Reviewer. The source entry point, automatically discovered lists, and compiled entry point share the same module.

To navigate directly to a target from the current application without a queue panel, call:

```python
from app.review_launch import open_review_target
opened = open_review_target(window, {
    "detection_file": "data/annotations.sqlite",
    "origin_video_file": "data/video.mp4",
    "start_frame": 100,
    "end_frame": 150,
    "target_ids": "4, 5",
})
```

An `opened` value of False indicates that the normal save / tracking completion prompt was canceled; this Python interface raises an exception for invalid files or parameters. IDs absent from the annotations are not selected, and entry details show the IDs actually selected. Explicitly providing `origin_video_file` in the list is recommended; otherwise, Reviewer's automatic corresponding-video settings and lookup procedure are used.

The Python API for normal opening is `open_documents(window, annotation=annotation_path, video=video_path, manual_track=manual_path, raw_cache=cache_path)`, also imported from `app.review_launch`. It does not enable verification mode; provide only the source arguments that need to be opened.

Source locations: `app/review_launch.py` handles startup parameters and the public Python API; `core/review_queue.py` handles CSV and target validation; `ui/review_queue.py` handles the panel and navigation. The panel's default width is set only by `DEFAULT_QUEUE_WIDTH` in the latter file and is independent of the parameter panel's Right panel W in Display. Changing the source default requires recompilation; the panel boundary can also be dragged directly at runtime.

## 1.4 Seeking, Playback, and View Operations

| Operation | Effect | Impact on Annotations |
| --- | --- | --- |
| Enter a frame number and execute Goto | Seeks to the specified image number | Does not modify positions |
| Previous/next frame | Examines individual frames after pausing | Does not generate intermediate annotations |
| Alt + ← / → | Returns to the previous browsing position / restores the next browsing position | Does not modify annotations |
| Shift + ← / → | Seeks backward or forward by 5 seconds, stepping by round(5 × FPS) frames | Does not modify annotations |
| Mouse wheel / Shift + mouse wheel | Moves backward or forward by 1 / 10 frames per action, respectively | Wheel magnitude does not increase the step per action; rapid actions accumulate the target and cancel obsolete decoding |
| First/last buttons, `,` / `.` | With IDs selected, seeks to the first/last frame of their occurrence range; otherwise, seeks to the start/end of the video | Identical to clicking the first/last buttons at the bottom; does not change analysis Start/End |
| `[` / `]` | With an automatic ID selected, seeks to the start/end of a continuous segment; when already at that endpoint, can continue to the corresponding endpoint of an adjacent segment | Identical to the segment start/end buttons on the Selected ID page |
| Play/pause | Displays continuously or stops | Does not commit edits |
| Reverse, keyboard R | Enables/disables reverse playback | Set separately from Tracking Reverse |
| Loop | Loops at the effective playback range boundaries | Does not duplicate trajectories |
| Speed | Sets the playback speed multiplier; also the speed limit for Auto Tracking | Does not change video FPS or CSV frame numbers |
| Click or drag the progress bar | Seeks to the frame specified by the horizontal click position | Pauses ongoing Auto Tracking and retains points pending commitment |
| Click a band or symbol marker below the progress bar | Seeks to a frame in the visible range or the corresponding marker frame | May snap to nearby endpoints; distant blank areas do not change the frame |
| Ctrl + mouse wheel | Zooms around a point near the pointer | Does not change original-image coordinates |
| Middle-button drag | Pans the view; wheel-based frame stepping is disabled while the middle button is held | Does not translate annotation data |
| Zoom − / + / R | Zooms out, zooms in, resets the view | Changes only the view |

Hovering over the progress bar or trajectories can display seeking hints; hovering alone should not be taken as evidence that the frame has changed. Check the current frame number on the image.

**Seek preview** in Display → Others → Accessibility controls video thumbnail previews. Once the file and index are loaded, the application preloads up to 256 base images while idle and retains them for the current video. Moving the mouse along the progress bar immediately displays the nearest cached image; slow movement or a pause of approximately 90 ms supplies a more accurate frame. Previews contain no annotations, do not switch the main image, and do not change the current selection. Width px sets the display width, defaulting to 240 with an allowed range of 80–640; cached images never exceed 240×135 and are displayed proportionally. Approximate images can still be requested before indexing is complete. The preview is hidden when the mouse leaves, dragging ends, the video changes, or the main window loses its active state; when operating other windows such as Select bout, passing over the progress bar does not display a preview or activate the main window.

Hold Ctrl while moving over the progress bar to preview the visible image region after the player's current zoom and pan. Regional images are generated on demand and are not included in base-image preloading; after changing the view region, the cache for that region is used. Thumbnails whose image identity has been verified display `Frame N`; base samples and unverified images continue to show an approximate hint.

Reverse playback decodes forward in memory blocks and presents them in reverse order without generating a complete reversed video; entering reverse playback for the first time or seeking to an uncached position requires preparation of an image block. Both `cpu_frames` and `mpv_gl` support Reverse. `mpv_gl` retains the selected rendering mode and displays these decoded frames through the GPU. Consecutive normal wheel events accumulate their target over short intervals while retaining reusable decoding pipelines.

Free dragging of the progress bar must begin within the progress bar area; after pressing, dragging can continue outside that area. The marker area below the progress bar supports clicking only: the target is determined on press and seeking completes on release; dragging cannot begin in the blank area below. See [Progress Bar, Bands, and Hovering](02_Interface_and_Segment-by-Segment_Review.md#25-progress-bar-bands-and-hovering) for the complete snapping rules.

### 1.4.1 Timestamp Gaps and Image Numbers

Detection and annotation use consecutive numbers in actual decoding order, with the first image numbered frame 1. A jump in container timestamps between adjacent images does not insert nonexistent annotation frames. For example, if adjacent image timestamps differ by 0.756 seconds, they still have adjacent numbers as long as the decoded images are consecutive.

The image index is built asynchronously. If a target image has not yet been confirmed during paused seeking, the confirmed image is retained to prevent old images from being paired with new annotations. `Frame mapping pending` means image identity still awaits verification; estimated time cannot replace formal image identity in the final save. Existing CSV files are not renumbered by guesswork merely because they are opened.

mpv_gl maps between the player's time origin and the image index. Container seconds, player seconds, and consecutive image numbers are different concepts; multiplying an arbitrary time value by FPS cannot directly infer another. If subsequent analysis uses frame difference/FPS, explicitly state that it uses consecutive-image time rather than acquisition duration including timestamp gaps.

### 1.4.2 Going Back and Forward Through Browsing Positions and Object Selections

Browse Back / Browse Forward returns to review positions rather than undoing or redoing annotation changes. The application maintains separate histories for frame positions and object selections; neither is written to the result database.

| Operation | Shortcut | Effect |
| --- | --- | --- |
| Position back | Alt + ←, Backspace, mouse back button | Returns to the previous browsing position |
| Position forward | Alt + →, mouse forward button | Restores the next browsing position |
| Selection back | Ctrl + Alt + ←, Ctrl + Backspace, Ctrl + mouse back button | Restores the previous object selection and its frame number |
| Selection forward | Ctrl + Alt + →, Ctrl + mouse forward button | Restores the next object selection and its frame number |

Position history includes progress-bar seeking, frame-number entry, seeking from tables and trajectory points, and jumps to segment endpoints. A single drag records only its start and end positions; consecutive frame-stepping actions no more than 500 ms apart are merged into one entry. Playback, automatic tracking, and automatic next-frame operations do not add an entry for every frame. When going back after playback, the current playback position can become the return point for forward navigation.

Selection restoration applies to IDs, specific boxes, and manual trajectory selections, including the active object. Deleted rows or trajectory points are not restored, and data is not recreated. Restoration synchronizes the image, table highlighting, and progress-bar bands; browsing restoration pauses playback and automatic tracking while retaining uncommitted edits.

**Operation example:** After inspecting a target at frame 100, seek to frame 800 and then frame 1200. Press Backspace to return to frame 800, and again to return to frame 100; use the mouse forward button to move forward again. After returning to frame 800, seeking separately to frame 900 creates a new position branch; the previous forward branch to frame 1200 is no longer retained.

**Selection example:** Select ID 12 at frame 200, then ID 19 at frame 650. Ctrl + Alt + ← restores frame 200 and the selection of ID 12; it does not modify the annotations of either ID.

Each history retains up to 500 entries and is cleared when the application exits. Switching videos rebuilds both histories; reloading annotations for the same video rebuilds selection history. When an input editor has focus, Backspace retains its text-deletion behavior. Alt + left/right arrows accesses position browsing history; holding Ctrl as well accesses object selection history.

Main-window buttons, checkboxes, and noneditable drop-downs do not consume the space bar; clicking the video or an empty area of the main window returns keyboard focus to playback. Text fields and separate dialogs retain their own keyboard operations. X / C decreases/increases speed through the Speed presets, and Z switches between 1× and the most recent non-1× speed; speed memory lasts only for the current run. Class cycling uses Alt + C. Keyboard shortcut R controls Reverse (the R button in Zoom resets the view, while the R button in the shared area of the Edit tab opens the staging window). These seeking shortcuts do not intercept normal input in text fields or dialogs.

## 1.5 Saving Annotations and Exporting Data Tables

### 1.5.1 Committing Versus Saving

Finish in Tracking, Apply in Trajectory, and Apply in Scale commit the current operation to working data; they do not directly complete a SQLite save. History records committed operations; recovery snapshots support recovery after interruption and likewise do not replace formal output.

### 1.5.2 Saving Procedure

1. Complete the current edit: use Finish/Cancel in Tracking, Apply/Discard in Trajectory, and Apply or cancel in Scale; end Continuous editing.
2. Check keyframes, both trajectory ends, identity transitions, and metadata.
3. Click Save (Ctrl + S) to write back to the current SQLite file, retaining its filename without appending a date and time. When formally saving an old CSV for the first time, select a SQLite destination; the default filename contains no date and time.
4. Use Save as (Ctrl + Shift + S) to retain an intermediate version or export a legacy format. The default filename has a `YYYYMMDD_HHMMSS` suffix. Choose SQLite result or Legacy CSV. In Edit → Points, enable `Target only` to save final annotations within Start–End. With the option cleared, both save commands include all working annotations. This option is independent of the save verification switch.
5. When save verification is enabled, record the actual verification status of each item in the window; only questions enabled in Display → Boutlist fields are shown. Incomplete items may remain unchecked; do not falsely claim verification merely to save. After Confirm, wait for the background success message; Back cancels saving. CSV is provided only for compatibility export; see 1.5.5.
6. If prompted to write back to Boutlist, check the record and fields before choosing; this is separate from writing the annotation SQLite file.
7. Reopen the output and spot-check keyframes and metadata.

### 1.5.3 SQLite Output Scope and Contents

A full save outputs working annotations and their metadata. Output limited to Start–End includes both endpoints and preserves original video frame numbers; for example, output for 1000–1200 still starts at frame=1000. Working data outside the range is not removed from the session as a result.

With segment output selected, Save synchronizes the current result database's final annotations to the specified range; Save as outputs the segment to a separate file without overwriting the current full database. Original raw detections and provenance history retain the original source coverage, so the maximum frame number in raw tables or history cannot be used to determine the final annotation output range. After reopening, `reviewed_detections` contains only annotations within this save range, while the video itself can still be sought outside the range.

**Example:** With Start=1, End=112, and a 248-frame video, selecting this option and clicking Save retains only frame=1–112 in the current database's final annotations; annotations for frames 113–248 remain in the current in-memory session. Unchecking the option and saving again before closing saves the complete current in-memory working table. After reopening the segment database, unchecking the option cannot restore unloaded annotations outside the range. Original detections and row-level save history provide provenance and are not automatically injected into working annotations.

The data-area table is a viewing and selection interface. Save / Save as saves the current working annotations rather than exporting the currently highlighted table cells. The working table and original raw data are saved in separate tables; raw rows are not mixed into working annotations. A loaded project or the detection cache for the same current video is included in the result database when saving SQLite; explicitly Load result in Detection first when postprocessed results are required.

`info_points`, `info_events`, `scale_calibration`, and similar fields store analysis metadata. The complete Scale JSON is saved in the annotation file; Boutlist can write back both a short scale summary and the complete JSON according to field mappings. Do not retain only x/y while deleting identity and source fields and then treat the file as a complete reviewed project.

### 1.5.4 Result Databases and Incremental Saving

Each video uses one SQLite result file containing final working annotations, metadata, and operation records; original raw detections, when available, are embedded in the same file. Working annotations can be fully saved and edited without raw data, but Detection postprocessing cannot be rerun from them. When raw data is already embedded in the project, saving as or moving the result does not require an external raw cache, result JSON, or `_edit_log.txt`.

| Table | Saved Contents |
| --- | --- |
| `frames` / `raw_detections` | All raw frames in decoding order (including empty frames) and upstream detections, unaffected by manual changes |
| `raw_metadata` | Upstream model parameters, video fingerprint, classes, and raw completion status |
| `reviewed_detections` | Current frame-by-frame working annotations, source fields, and stable row UIDs; directly queryable through SQL |
| `raw_sources` | Source identifiers and source metadata for raw data inside the database, independent of external cache files |
| `manual_edits` | Before/after contents and transaction numbers for rows added, modified, or deleted at each save |
| `save_transactions` | Save time, transaction type, and counts of additions, deletions, and modifications |
| `events` | Ordered event records |
| `metadata` | Video information, Points, complete Scale, Camera, parameters, and source information |
| `history` | Displayable operation history |
| `history_commands` | Legacy command archive, cleared by GUI saves |
| `history_undo` | Replay state for full saves, tied to the committed revision |

The in-memory DataFrame and edit/undo behavior remain unchanged. Save / Save as freezes the data required for this save and synchronizes the database transactionally in a background thread; edits not yet saved are not written prematurely to the formal result. The database does not generate an additional `_edit_log.txt` or result metadata sidecar. Temporary `-wal` and `-shm` files may exist during SQLite writes and are managed by SQLite; copying only the main file during writing does not provide a complete backup.

When saving ordinary edits to the current file again, only added/modified rows and deleted UIDs are frozen by stable UID; the complete working table is not deep-copied or staged. Events, metadata, operation history, and working rows are committed in one transaction and rolled back on failure. Edits made during saving remain unsaved. Initial conversion, saving as a new database, segment export, and some batch modifications/undo operations may still require full snapshots and comparison. If another instance has updated the file, overwriting its new version is refused.

On the first save or Save as, the application builds and commits a temporary database in the destination directory, then publishes it under the selected filename after success. Selecting an existing file in Save as and confirming overwrite replaces the destination completely without retaining unrelated old working annotations or metadata; segment output can also overwrite the current file after confirmation. Failure preserves the original destination and current in-memory edits. Normal Save continues to use SQLite transactions and version checks; if another application modifies the destination during saving, overwriting stops and a recheck is requested.

Saving prioritizes raw data already embedded in the project. If an associated raw file is unavailable, three choices appear before saving: **Locate raw...** specifies the original cache or a result database embedding the same raw data and checks the recorded source identity; **Save without raw** saves only working annotations, metadata, and operation history; **Cancel** cancels this save and retains unsaved edits. Canceling the file dialog after choosing to locate a file also cancels this save. Projects with no previous raw association save directly without repeated prompts; after explicitly discarding raw data and saving successfully, subsequent saves no longer require recovery of that external file.

The `.sqlite-wal` transaction log and `.sqlite-shm` shared index may appear during writing. After saving annotations, the application attempts to merge committed logs into the main database and return to ordinary journal mode; when no other connections are using the database, only the result file remains. WAL is retained when Detection or another connection is still using the database to support concurrent reads and writes. Do not manually delete these auxiliary files while they are in use.

On normal exit, the application also attempts this safe finalization for open result databases. Auxiliary files are retained when another instance is still using the database, the directory is not writable, or the database is unavailable; they are not forcibly deleted. Their presence does not mean the entire result is exclusively locked; ordinary journal mode also retains SQLite transactions and file locking.

If the result file is moved or deleted while open, the in-memory working annotations are not cleared. If the exit check finds the saved file missing, the current data is treated as requiring another save and a save prompt appears. Canceling exit allows continued work; the in-memory session is discarded only after explicitly choosing to abandon it and exit. When saving again, restore the source or save annotations only according to raw source availability.

Deleting a recovery snapshot deletes only the selected snapshot. Directory cleanup is allowed only for recovery session directories managed by the application; annotations, videos, and other files beside external manual snapshots are excluded from cleanup. A recovery directory containing SQLite or other non-recovery files is retained.

**Compact save** in Edit → Points cycles through three SQLite save modes.

| State | Saved data |
| --- | --- |
| Unchecked (default) | Complete result, concise log, row-level audit, and the Undo/Redo state for reopening the project. Reopening a valid undo archive selects this mode again. |
| Partly checked | Result, concise log, and row-level audit. Saved history appears in gray after reopening. |
| Checked | Current annotations and required metadata, including Points, Events, Scale, Camera, and saved manual trajectory data. |

All three modes retain the current in-memory Undo/Redo stack and follow the existing Raw choice. With **Target only**, the unchecked and partly checked states save the segment with logs and audits. CSV always uses compact export. Compact SQLite saving builds and vacuums a temporary database before replacing the destination. A failure preserves the original file.

Legacy CSV can be opened, appended, or used to replace a source. After importing, save as `.sqlite` to complete conversion; the original CSV is retained. To retain both a full database and a segment, use Save as to output a separate database; segments always retain original frame numbers.

### 1.5.5 Legacy CSV Compatibility Export

Legacy CSV in Save as outputs a UTF-8 BOM frame-by-frame result table with annotation fields and required metadata. Video information and Points, Events, Scale, and Camera JSON are written to the first row and to a same-name `.metadata.json` file. Keep that sidecar with the CSV, including for empty tables. Range export includes both endpoints and preserves original frame numbers.

CSV is a compact interchange format for results. Use SQLite to keep raw detections, audit records, and cross-session Undo/Redo. Exporting preserves the current working file path and unsaved state. CSV reimport reads complex objects in unknown extra columns as JSON text, and type inference may change leading zeros or null values.

## 1.6 Exporting Annotated Video

### 1.6.1 Parameters

| Setting | Meaning |
| --- | --- |
| Export Range | Inclusive frame range; supports `1-2990`, `-2990`, and `1-` |
| From Start to End | Uses the analysis boundaries in Points; unchecking restores the manual range |
| Picture range | Left X is the selection's left-edge horizontal coordinate and Top Y its top-edge vertical coordinate, both in pixels relative to the top-left corner of the complete output canvas; W/H is the selection width/height. Defaults to the full image; uses expanded-canvas coordinates when Expanded motion canvas is enabled |
| Select area | Draws and adjusts the export region on the main image; click again to finish. The dark masked area is excluded from output |
| FFmpeg / Browse | Specifies an FFmpeg executable with the required encoders |
| Encoder | Video encoder, such as libx264 or an available hardware encoder |
| Preset | Speed versus compression-efficiency tradeoff for the selected encoder |
| Quality | Quality parameter for the selected encoder; not detection confidence, and values should not be compared directly across encoders |
| Render workers | CPU worker parallelism for exporting Overlay, not inference parallelism for Detection |

### 1.6.2 Export Procedure and Checks

1. Save working annotations and configure the boxes, IDs, trail, Axis, Scale/grid, and Camera compensation to display.
2. Click Export in File, then confirm the time range, image region, and encoding parameters in the nonmodal Export settings window; Settings can also be used to adjust them separately. This window does not lock the main interface or actively take focus when displayed; click an input field to edit normally.
3. For cropping, click Select area and drag on the image to create a selection; drag edge or corner handles to resize, or drag inside the selection to move it. Click Select area again to finish. The File page shows a selection preview, and a red band below the progress bar marks the export time range. After confirming Export, select an output file and view completion or failure information in the separate progress window.
4. Check output resolution, frame order, colors, trail direction, text, and the compensated canvas.
5. Export the complete range only after confirmation.

The time range and image selection belong only to the current video session and are not written to settings.ini. Closing Export settings or pressing Cancel retains the entered range without starting export; reopening restores the current input. While the File page is in the foreground, the image selection mask and red range band below the progress bar remain visible; switching videos clears the range. Video export follows Display's Overlay renderer: Qt raster uses Qt drawing without creating an OpenGL context, while OpenGL uses retained rendering. Annotation elements use the current display settings in Display; cropping occurs after canvas composition, and the HUD is rearranged within the final image. YUV 4:2:0 encoding requires even dimensions; an odd width or height is padded by one pixel on the right or bottom.

Canceling export does not undo annotation edits, but intermediate output from a canceled export must not be treated as a successful file. The video encoder and Overlay rendering backend operate separately: using a hardware encoder does not imply that boxes and trajectories are rendered by the GPU.

## 1.7 Check Order for Common Problems

- **Boxes appear misaligned with the image:** First check image identity frame by frame, video–CSV pairing, and index status, then inspect the Camera coordinate transform; do not begin by translating all boxes globally.
- **No boxes after opening:** Check whether the current frame has data, the source is loaded, and display/class filtering and the experimental layer View are correct.
- **Frame numbers do not start at 1 after Save as:** Partial output preserves original video frame numbers; this is expected.
- **Export is slower than playback:** Export requires decoding, rendering, and encoding; the player's real-time behavior does not guarantee export speed. Check rendering and encoding configurations separately using a short segment.
