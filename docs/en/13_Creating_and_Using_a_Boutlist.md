# 13 Creating and Using a Boutlist

[Return to the main index](00_Annotation_Reviewer_User_Manual.md)

## 13.1 Purpose and Scope of Each Row

A Boutlist is a standard CSV table in which each row organizes one bout for review: video, automatic annotations, manual trajectories, and alignment/analysis metadata. It facilitates opening bouts individually and writing back brief information; it does not store all frame-by-frame boxes or replace annotation SQLite files.

One video may contain several analysis segments, but distinguish them with explicit bout_id values and ranges. Always verify the selected row before writing back; a video filename alone does not identify the intended row.

## 13.2 File Creation Procedure

1. Create a CSV with a UTF-8-capable spreadsheet tool or text editor, using the first row for column names.
2. Enter a bout identifier and an existing video path in each row; leave frame-by-frame annotation and manual file fields blank if unavailable.
3. Enter known Start, End, Capture, and manual alignment information in the corresponding columns.
4. Use standard CSV quoting for text containing commas, quotes, or line breaks; do not split records manually at commas.
5. After saving, configure column mappings in Display → Boutlist fields, then use Open Boutlist.
6. Test one row and inspect synchronization results before organizing the remaining records in bulk.

**Example:**

```csv
bout_id,origin_video_file,detection_file,analysis_start_frame,analysis_end_frame,capture_frame
trial01,E:/videos/clip01.MTS,E:/results/clip01_review.csv,100,1200,1185
trial02,E:/videos/clip02.MP4,,1,950,930
```

Absolute paths are easiest to verify directly. With relative paths, preserve the relationship between the Boutlist and related directories.

Relative paths are resolved first against the application directory; if unavailable there, they are searched relative to the Boutlist directory. The launching terminal's working directory is not used. When moving the application and data, preserve directory relationships and test by actually opening files; drive-letter paths from another computer are not portable paths.

## 13.3 Boutlist fields Mapping Settings

These settings are in Display between Playback and Others. Items on the left represent internal application meanings; enter actual Boutlist column names in the text fields.

- Column names match exactly, including case; leading and trailing whitespace in input is removed.
- A blank value disables reading and write-back for that item.
- Two items cannot map to the same nonempty column name; Save settings (All or Boutlist fields) rejects duplicate mappings.
- Column name fields contain drafts. Mappings are written to `settings.ini` and take effect in the current session only after selecting All or Boutlist fields as the scope and clicking Save settings. Saving other groups does not apply these drafts.
- Opening or writing back to Boutlist before saving continues to use the last saved mappings. Restoring saved values automatically clears the unsaved indicator.
- Changing a mapping does not directly rename or rewrite CSV columns.
- The Open Boutlist selection window displays original CSV column names and order, including unmapped custom columns; internal canonical fields are used only for reading and write-back and are not displayed as duplicates. `column_widths` in `setting.ini` controls column widths only, not column order.
- After changes, reopen the current Boutlist record to avoid reusing the row snapshot captured under the old mappings.
- When opening an annotation file directly, metadata lookup uses the selected Boutlist; if no record is selected, it uses the currently configured Boutlist path rather than the old startup default.

**Example:** If the video path, analysis start frame, and capture frame columns are named `Video`, `Start`, and `Capture`, enter these names in the fields for origin_video_file, analysis_start_frame, and capture_frame respectively. The application interprets them accordingly, displays the actual column names in the selection window, and updates only the newly mapped columns during write-back without adding old columns. Internal variable names and canonical field names in output annotation SQLite files remain unchanged.

## 13.4 Mappable Fields

### 13.4.1 Identifiers and Sources

| Item | Meaning |
| --- | --- |
| bout_id | Bout identifier; a stable, distinguishable value is recommended |
| trial_id | Experiment/trial identifier |
| phase | Phase information |
| origin_video_file | Video file |
| detection_file | Automatic or reviewed annotation SQLite file |
| manual_track_file | Manual trajectory file |
| trk_file | Tracker project source |

### 13.4.2 Analysis Range and Subjects

| Item | Meaning |
| --- | --- |
| analysis_start_frame / analysis_end_frame | Video analysis range including both endpoints |
| capture_frame | Successful capture reference frame |
| nest_x_px / nest_y_px | Hive entrance pixel coordinate summary corresponding to Hive information in the application |
| scale_px_per_cm | Brief representative px/cm value |
| victim_id_at_capture / captor_id_at_capture | Verified identities of the captured honeybee and successful hornet |
| left_censored | Actual interaction onset precedes the available analysis images |
| verified_capture_pair | Capture participants' trajectories have been verified |
| verified_exposed_bees | Low-positioned and peripheral honeybees have been verified |
| verified_other_hornets | Other hornets and conspecific interference have been verified |
| review_notes | Review notes |
| camera_motion | Camera-related summary flag; does not replace complete anchor observations |

### 13.4.3 Manual Trajectory Alignment and Video Properties

| Item | Meaning |
| --- | --- |
| trk_capture_frame | Corresponding reference frame on the Tracker timeline |
| trk_align_first_frame / trk_align_last_frame | Tracker frame range used |
| trk_reverse | Whether manual annotations were made during reverse playback |
| trk_fps | Frame rate of the manually annotated video |
| frame_offset | Additional video frame offset |
| x_offset / y_offset | Position offset of manual points in the original image |
| fps | Video frame rate summary |
| resolution_width / resolution_height | Resolution fields |
| video_width / video_height | Video width and height fields |

A field's presence does not establish that it is populated and valid. Frame numbers and identities should be reasonable integers; use consistent, recognizable boolean representations, and accessible file paths. Do not treat Excel's automatic date conversions, scientific notation, or floating-point display as actual ID values.

## 13.5 Opening and Synchronization Procedure

### 13.5.1 Reading

Open Boutlist → select a record → verify actual paths in File → check Points and Match parameters → play key frames. Field mappings only associate column names; they do not correct incorrectly paired videos or frame numbers.

### 13.5.2 Writing Back

1. Modify and confirm the relevant information in Points or Match.
2. Run Sync to, or inspect differences when prompted to write back.
3. Confirm the displayed target row and actual column names.
4. Reread the row afterward to verify it.

Sync from imports table contents into the corresponding metadata again. If the current session contains more accurate new values, decide whether replacement is appropriate first. Canceling write-back does not undo results already saved to annotation SQLite.

Disabled review checks, checks without Boutlist column mappings, and checks whose columns are absent from the actual Boutlist do not participate in write-back difference checks, and no columns are added automatically for them. Existing review states remain in result files.

Read conflicts, Sync from, and Sync to share numeric comparison rules: ordinary floating-point values allow storage rounding differences (relative tolerance `1e-7`, absolute tolerance `5e-7`); floating-point values in JSON use relative `1e-7` and absolute `1e-12`, and JSON key order does not affect equality. Frame numbers, identities, and other integers still require exact equality; missing or disabled mappings do not clear existing values during synchronization. When precision differences are equivalent, original annotation precision is retained without an overwrite prompt or a Boutlist rewrite solely for that difference.

`scale_px_per_cm` represents only a fixed ratio or an approximate average summary of complete calibration. If annotations already contain calibration lines, a local field, or a matrix model, a simple Boutlist scale does not prompt replacement of complete calibration, and Sync from does not convert it to a fixed scale.

When Boutlist configures and supplies a valid complete `scale_calibration`, it can be compared with the full annotation calibration; choose a source only for actual differences, with the annotation retained by default. For a fixed single-value scale only, selecting a new ratio updates both the ratio and its corresponding single-value calibration.

### 13.5.3 Window and Current Row Location

Select bout is an independent nonmodal window, selectable from the taskbar, with standard minimize, maximize, and close buttons. Keep the table open while playing, seeking, and checking annotations in the main window.

The open bout has a pale yellow background. Click a row number to select that row. Double-click a column name to sort.

Pressing Open Boutlist again activates the existing window; when the current bout can be identified reliably, its row is centered and selected automatically. Sorting the table changes neither source file row order nor current row identity.

The bottom buttons, from left to right, are Edit, ↶, ↷, Browse, and Open. Select a row and double-click or press Open to switch to the main window and open its bout. If the selected bout is already open, this only switches to the main window without reloading files. Outside editing mode, double-clicking a cell also opens its row.

After the Boutlist is first opened, file changes are monitored throughout the current application run; closing or hiding Select bout does not stop monitoring, and change colors persist when reopened. Cells synchronized from the main window use the system accent color; cells modified externally use a reddish-brown color. Refresh relocates the open bout by source row identity, retaining selection and highlighting; file sorting or changes to other rows do not change that identity. If the identity can no longer be determined uniquely, the application does not guess another row. External refresh is deferred during cell editing to avoid overwriting uncommitted input.

### 13.5.4 Cell Editing Procedure

1. Open Select bout and verify the Boutlist file and record being edited.
2. Press Edit. The button remains pressed and the table becomes editable.
3. Double-click a target cell and edit its text; Browse can also select file paths. Double-clicking during editing does not open the bout.
4. Click another cell, switch to the main window, or press Enter to commit the input. If content exactly matches the original text, no file is written and no undo record is added. Esc discards uncommitted editor input.
5. Check the modified cell. Cells differing from this file's editing baseline in the current run display text in the system accent color, retained even when selected.
6. Keep the window open for further checks. Press Edit again when finished to leave editing mode; active input is committed first.

Committing immediately writes back to the original Boutlist; neither the main window's Save settings nor saving annotation SQLite is required. Direct editing preserves raw input text without numeric formatting or column name conversion; text, leading zeros, and JSON text in other cells remain unchanged. A write failure or detected external conflict displays an error and creates no successful undo record.

Browse provides convenient, accurate path entry through visual file selection, supporting absolute and relative paths; relative paths are resolved first against the application directory, then against the Boutlist directory if unavailable there, using the same rules as opening a record. Selected files are written as paths relative to the application directory where possible, or as absolute paths across drives or when a relative path cannot be represented. A valid path in the current cell supplies the starting location; otherwise, the Boutlist directory is used. Clicking Browse first commits modified cell content under the normal cell-leaving rules. Canceling file selection does not update the cell, but also does not undo text changes committed before Browse. Selecting a path identical to the original text causes no additional file write or undo record. Existing write conflict checks still apply if an external change occurs during file selection.

**Example:** Change a row's review_notes from blank to `Capture pair checked`; after clicking the main window, the cell is saved and shown in the system accent color. Closing Select bout does not lose the change. Reopen it, enable Edit, and press ↶ to restore the blank value and write it back; returning to the baseline restores normal text color.

Editing metadata cells for the current bout updates only Boutlist and the current row location snapshot; it does not overwrite loaded Points, alignment, or calibration in the main window. Use the corresponding Sync from to read new metadata. Open on the current row does not reload files.

### 13.5.5 Drag-Filling Cells

1. Enable Edit and click the source cell.
2. Move the pointer into the cell and hold the left mouse button on the handle displayed at its lower right.
3. Drag vertically along the same column or horizontally along the same row, checking the target cells covered by the preview outline.
4. Release and choose Copy fill or Fill series; no fill is performed without a selection.
5. Check the filled content. The entire fill is saved immediately and can be undone with one ↶ or redone with one ↷.

Copy fill copies raw source text to target cells, including leading zeros, floating-point formatting, paths, and JSON strings. Fill series generates ordinary numeric sequences with a step of 1: values increase downward/rightward and decrease upward/leftward, preserving source leading-zero width and decimal places. Other text is copied without inferring dates, filename numbering, or formula patterns.

**Example: increasing identifiers.** Drag two cells down from `003` and choose Fill series to write `004` and `005`; dragging upward writes `002` and `001` in sequence. Filling two cells rightward from `1.50` produces `2.50` and `3.50`. Choose Copy fill to make every target `003`.

Filling currently uses one source cell along a row or column, leaving the source unchanged. Writes still use source file row identities after table sorting. If all targets already match, no file write or undo record is created; write failures or external file conflicts commit no partial fill and do not move the undo record. A successful fill writes the file once and creates one independent Boutlist undo record outside main-window History.

### 13.5.6 Independent Undo and File Conflicts

The bottom ↶/↷ buttons mean Undo/Redo respectively. They are enabled only when Edit is on and corresponding records exist; Ctrl + Z/Ctrl + Y follow the same rules. During text editing, shortcuts first act on the input text.

Each Boutlist file maintains separate lightweight cell records, retained when closing the window or switching bouts; switching Boutlist files uses that file's own records. Executable undo stacks are not restored after application exit. Committing a new change after undo clears that file's existing redo branch.

Disk contents are checked before writing to prevent overwriting other programs' changes using obsolete row numbers. External changes are automatically read while the window is idle; refresh is deferred during unfinished cell input. After a conflict prompt, finish current input and inspect refreshed content, or reopen Select bout to refresh explicitly. Reading external changes clears obsolete undo records. If undo/redo writes fail, records remain in place rather than skipping the failed operation.

## 13.6 Write Boundaries and Text Preservation

Write-back updates only corresponding mapped fields, leaving other columns and unmodified cell text unchanged; for example, updating Capture should not reformat identifier `001` or a custom column value `1.2300` throughout the table.

Complete `scale_calibration` JSON is always written to output annotation SQLite. Boutlist fields allows independent column names for `scale_px_per_cm` and `scale_calibration`, both of which can be enabled together. JSON columns for `info_points`, `info_events`, and `camera_anchor_keyframes` can also be enabled. Clearing a field only grays out its item label; the input remains editable. After Save settings (All or Boutlist fields), reading and writing stop for that item without clearing existing table content. Default mappings enable same-named columns present in the current Boutlist and leave other items blank; saved custom mappings take precedence. If Points JSON and separate scalar fields coexist, nonempty separate scalar fields take precedence. Loading annotation SQLite still uses the existing source-selection dialog for metadata conflicts.

Configure review fields in the Boutlist fields review definition table. Enabled shows the question in Verify. Sync and an existing mapped column make the answer editable. Review answers are stored in the corresponding Boutlist row. Activate configuration through Save settings with the Boutlist fields or All scope.

Events, frame-by-frame positions, template images, and complete History are not stored individually in this table. When multiple people or instances edit the same CSV, avoid overwriting the same records and rely on pre-write difference checks.

## 13.7 Automatically Opening Corresponding Files

Auto open corresponding file in Boutlist fields controls bidirectional association: opening a video searches for corresponding annotations, and opening annotations searches for the corresponding video. Video lookup uses annotation source fields, source information in info_video, detection sidecars, and saved Boutlist mappings; valid source paths take precedence. Without a valid path, it searches by source filename or a video name matching the annotation filename after removing the detection result suffix.

Search is limited to the annotation directory, its parent, the project directory, and the last video directory; it does not scan the entire disk recursively. A single candidate opens automatically; multiple candidates prompt for selection, and cancellation does not switch videos. If none is found, the current state is retained with a status bar message. Automatically opening a video does not reopen annotations, preventing loops or replacement of newly loaded annotations.

When this option is off, opening annotations does not switch videos automatically. Appending annotations to the current review still requires sources from the same video and does not switch videos based on the appended file.

## 13.8 Typical Checks

- Wrong video opens: check mapped columns, current row, and paths before adjusting annotation coordinates.
- An item is not read: check for a blank mapping, spelling and case, column existence, and valid values.
- Write-back is unavailable immediately after changing mappings: reselect the Boutlist record to create a row snapshot under the new mappings.
- New columns appear after write-back: confirm that mappings use existing column names rather than similar alternatives.
- Precise spatial analysis is required: read full calibration from annotation SQLite rather than using only the Boutlist average scale.
