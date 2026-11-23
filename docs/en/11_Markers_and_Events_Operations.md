# 11 Markers and Events Operations

[Return to the main contents](00_Annotation_Reviewer_User_Manual.md)

## 11.1 Purpose and Storage

Use **Edit → Markers** to record which frames a segment contributes to the analysis, the capture reference frame, the identities of key subjects, spatial reference points, and review notes. These records let another reviewer find the same frames, subjects, and positions and understand the scope and uncertainties of the analysis. Use **Events** for intervals of behavior or data quality issues such as conspecific interference or severe blur. The reviewer makes these judgments from the video. The application records and displays them and provides navigation.

SQLite and CSV annotation metadata use `info_points` for marker definitions, values, coordinate placement frames, and references. Event intervals use `info_events`, and full scale calibration uses `scale_calibration`. Marker values can be synchronized to Boutlist through field mappings. Sync → To leaves event intervals in the annotation file.

## 11.2 Set and Navigate Markers

Each column represents a marker. **Value** shows the record and **Symbol** shows its symbol or style. Click a header or Symbol cell to navigate to its frame or coordinate, select its box ID, or edit its text. Double-click a value to edit it directly. In the editor, click **Clear** to remove the value or confirm an empty entry. Use the wheel to scroll across the columns. Double-click any column divider to fit all columns to their contents.

| Type | Set action | Manual input |
| --- | --- | --- |
| Frame | Confirm the current frame | A positive frame number |
| Coordinate | Click a position in the video or expanded canvas, then click Apply | `x, y (Frame=n)`, `x, y, n`, or a coordinate reference. Omit the frame to use the current one |
| Box ID | Click an object box, then click Apply | An integer box ID |
| Text | Open the text editor | Free text |

Select a value cell, click **Set**, then pick the coordinate or box in the canvas. For a box ID, Set also accepts an already selected single ID as its initial candidate. **Apply** stays pressed and the table shows the candidate. Coordinates can lie outside the original video image. While placing Origin, the axes follow the pointer until you click a position. Click a blank area of the main window outside the canvas and Markers to empty the candidate. For a box ID, clicking the canvas where there is no box also empties it. Press Esc to cancel picking. In the Frame Set or Apply confirmation, choose **Yes** to use the candidate or **Clear** to remove the saved value. Committed changes and clears can be undone in History. When a mapped Boutlist value differs, the application asks whether to synchronize it. Declining keeps the change in the annotation.

Click the `【`, `】`, or `↑` timeline marker to navigate to an analysis boundary or Capture. On that frame, frame marker labels and any events on the same frame use the Events HUD style. Preview and demonstration export with HUD enabled use the same labels.

## 11.3 Marker Field Definitions

| Marker | Internal field | Definition |
| --- | --- | --- |
| Start | `analysis_start_frame` | First included frame of the analysis interval. Use the research criteria to mark the actual interaction onset if visible. If the interaction is already underway when the recording begins, record the first usable analysis frame and note that onset is left-censored. |
| End | `analysis_end_frame` | Last included frame of the analysis interval. Choose it for the analysis objective and check its relation to Capture. With the first End unset, the range may use Capture or, if Capture is empty, the end of the video. |
| Capture | `capture_frame` | First frame in the successful sequence when the capturing hornet makes actual contact with the honeybee and then restrains and removes it. Review the subsequent frames to distinguish this contact from unsuccessful approaches or earlier brief contact. Match can also use this frame for manual trajectory alignment. |
| Origin | `origin` | Coordinate origin for Axis, recorded in source-image pixels with its placement frame. Its position is editable with Set or manual input. Its definition is fixed and the axes indicate its location. |
| Hive | `hive` | Reference position of the hive entrance for review and comparison with experimental coordinates. It follows Origin and its placement frame by default. Set Hive separately when the positions differ. Its symbol is configurable in Types. |
| Captor | `captor_id_at_capture` | Box ID of the hornet that successfully makes the capture. Check its identity in frames around Capture, particularly where other hornets are nearby or IDs may have swapped. |
| Victim | `victim_id_at_capture` | Box ID of the honeybee captured at Capture. Follow the contact, restraint, and removal sequence to confirm the same individual. |
| Notes | `review_notes` | Facts that affect analysis or later review, such as an unobserved onset, uncertain identity after occlusion, a trajectory gap, or abnormal image quality. |

The default Hive value `${origin}` follows Origin's x, y, and placement frame. To restore this link after placing Hive separately, double-click the value and enter `${origin}`. Custom coordinates can use the same syntax with the destination's **Internal field** inside the braces. The editor reports unknown destinations and cycles. With Camera compensation enabled, a coordinate follows the same background location from frame to frame. In Expanded motion canvas, it stays fixed on that location in the stabilized background.

If the project uses the verification field `left_censored`, use false when the actual onset was fully observed and true when the interaction had already begun. Judge this from the video. The first detection, entry direction, and distance from the image edge do not establish onset. Assess whether the starting conditions qualify as an undisturbed baseline separately.

### 11.3.1 Fields, Intervals, and Styles

Use **Markers → Types** to add, remove, disable, reorder, or edit definitions. An internal field starts with a letter and can contain digits and underscores. References and Boutlist mappings use that key. Origin's internal field, name, input type, and style are fixed. Its order, Enabled setting, and Tip can be edited. Edit the Origin coordinate in the main table. The other markers use Input type to determine how Set and manual editing work. Retyping preserves old data and shows an empty cell when the stored value is incompatible with the new type. **Save settings** writes definitions to settings.ini. An opened annotation file uses its saved definitions.

**Add range** creates a numbered pair of Frame fields such as `analysis_start_frame_2` and `analysis_end_frame_2`. Enable both fields, keep their type as Frame, and set their values to include the interval. The unnumbered names form pair 1. Later pairs use a shared suffix `_N` with a decimal integer of at least 2 and no leading zero. The `start` or `end` part determines the fixed bracket. On the timeline, pair 2 displays `【2` and `2】`. There is no fixed limit on the number of pairs. Deleting one boundary removes both definitions. **Target only** and demonstration export's **From Start to End** include the union of the analysis intervals, including each endpoint and skipping gaps between intervals.

For a Coordinate or Box ID row with configurable style, click **Style** or double-click the Style cell. A coordinate symbol uses its configured outline color and a fixed width in the tables. The Style dialog's outline width applies in the canvas.

- **Coordinate** lets you set the symbol, size, fill color, outline color, and outline width. The default is a yellow triangle with a black outline.
- **Box ID** lets you set the matching box's outline color and **Box line**. Blank fields inherit the class color and global width respectively. If several markers specify a style for the same ID, the first configured style in Types applies.

| Geometric shape | Recognized single characters |
| --- | --- |
| Triangles | `▲` `▼` `◀` `▶` or `^` `v` `<` `>` |
| Filled circle, square, diamond | `●` `■` `◆` or `o` `s` `D` |
| Open circle, square, diamond | `○` `□` `◇` |

You can also enter characters and short labels such as `+`, `×`, `★`, `H`, or `Hive`. Those are drawn with the system font, so the available glyphs depend on the font. The analysis boundaries and Capture have fixed timeline symbols `【`, `】`, and `↑`, which also appear in the style preview.

## 11.4 Standard Procedure

1. **Correct key subjects' annotations.** Review the sequence, confirm the hornet and honeybee identities, and fix missing or duplicate boxes and ID switches before recording role IDs.
2. **Record the interval and Capture.** On each relevant frame, select Start, Capture, or End, click Set, and confirm. Determine Capture frame by frame, then set End to the last frame included in the analysis. For separate intervals, use **Add range** in Types and fill both boundaries of each numbered pair.
3. **Record subject IDs and spatial references.** At Capture, select Captor or Victim, click Set, select the correct box, click Apply, and confirm. Pick a frame with a recognizable background feature to place Origin. If the hive entrance is elsewhere, place Hive independently.
4. **Verify the records.** Click the column headers to check navigation, subject identities, and positions. If the camera moves, check that the coordinate markers still align with the same background feature on distant frames. When further review is needed, check both key subjects' trajectories, missed boxes or drift for low, peripheral, or isolated honeybees, and the presence and behavior of other hornets.
5. **Document, synchronize, and save.** Enter any uncertainties in Notes. Use **Verify** in Display → Others → Save for configured review questions. Confirm the Boutlist row, use **Sync → To** as needed, and save the annotation file. See [Basic Operations](01_Basic_Operations.md) for save modes and export ranges.

For example, if a hornet is already exerting pressure at the start of the clip, use the first usable analysis frame for Start and record the unobserved onset in Notes or the configured left-censoring field. Set Capture at the actual contact that leads to the successful capture.

## 11.5 Event Types

### 11.5.1 Default Research Types

The platform settings template provides the following default types; actual types are determined by settings.ini and the Types configuration table.

| Display/storage type | Annotation criterion | Insufficient grounds for annotation |
| --- | --- | --- |
| conspecific_interference | The successful hornet interrupts honeybee-directed activity to chase, avoid, or drive away other hornets | Mere presence in the same frame |
| noncaptor_engagement | A hornet other than the captor actively approaches, hovers, moves back and forth, or exerts pressure on the honeybee group | Simply flying past without relevant activity |
| bee_slip | A honeybee suddenly moves downward, creating a new low-positioned/isolated opportunity | Detection box jitter alone |
| loss_or_blur | Severe motion blur, occlusion, or collapse of group detection makes the spatial point set clearly unreliable | A few minor missed detections |

bee_slip records event timing without requiring a persistent honeybee ID. Events do not automatically assign final research categories such as induced capture; derive such conclusions in subsequent analysis using objective trajectories.

### 11.5.2 Configuring Types

1. Click Types in Edit → Events to open the nonmodal type table.
2. Use Add to create a definition and Delete to remove selected definitions; Up/Down moves selected definitions to change dropdown order. Internal key is a stable storage identifier: it must begin with a letter, contain only letters, digits, and underscores, and be unique.
3. Enabled controls whether new events of this type can be added and whether its HUD/strip is displayed; Name controls its label in the dropdown, event table, and HUD. Tip is an editable, INI-backed description shown on type choices and event cells, exactly as entered. Double-click Color to choose a color; the table stores a hexadecimal `#RRGGBB` code applied to the event table and strip.
4. Band 0 hides this type's strip; 1, 2, and 3 use the three strip rows below the progress bar respectively. Hiding a strip does not delete events or disable HUD display. Priority controls overlap order: smaller integers draw on top, defaulting to the type's sequence number. Event strips use alpha 0.7.
5. Valid changes immediately preview names, colors, and strips. Close accepts changes for the current run without writing to INI; Cancel or the window × discards changes since opening and restores the previous display. To retain changes for later runs, click Save settings, or save with Event types/All selected in Display's save scope; after a successful save, Cancel discards only subsequent unsaved changes.

Changing names and colors does not change stored event identifiers or frame intervals. Disabling or deleting type definitions does not delete existing events. Renaming Internal key does not migrate events under the old identifier; explicitly change their types in the event table. Existing events not configured on this computer are retained; type definitions in result files can supply display names and colors. Type configuration is an application setting outside annotation History; event interval changes still enter History.

**Example:** Create `camera_obstruction`, set Name to `Camera obstruction`, choose red, and set Band to 3. After saving Event types, select the type in the dropdown and record an interval. Changing Band to 0 and saving hides only the strip; clearing Enabled and saving hides both its HUD and strip, while existing intervals remain in the results.

## 11.6 Creating, Editing, and Deleting Events

### 11.6.1 Creating an Interval

1. Select a type in the event type dropdown and clear any existing event selection.
2. Navigate to the start frame and click Start; a new event is initially created with start=end and selected.
3. Navigate to the end frame and click End; the event becomes an interval including both endpoints, and selection is cleared afterward.
4. Double-click the event in the table to navigate to its interval; play around it to verify the boundaries.

With no event selected, clicking either Start or End creates a point event at the current frame. Single-frame events use start=end and share the interval structure, for example `{"type":"bee_slip","start":2301,"end":2301}`.

Conspecific interference, pressure from other hornets, and loss_or_blur intervals may overlap in time; overlap means that different facts coexist and should not be forced into one mutually exclusive category.

### 11.6.2 Editing an Existing Event

Click an event column to select it; clicking it again clears that selection without navigating. Ctrl/Shift support multiple selections. Change the type dropdown to update selected events, or navigate to a boundary frame and use Start/End. Use F2 to edit a table cell directly. With multiple events selected, boundary or type changes may affect all selected events; verify selection before proceeding.

Each event occupies one table column. Columns share a width; resizing any column resizes them all. events containing the current frame are bold. Selected cells have a yellow background and the selected event(s) are centered; moving the timeline does not recenter away from a selection. Esc or a click on a column/row header clears selection. Double-click to jump to the nearest frame within the interval. Selected events' timeline strips have a thin contrast outline. The horizontal scrollbar stays visible, and the mouse wheel scrolls horizontally. Type Priority determines strip layering. Delete removes selected event records, not trajectory boxes or the original video. Event edits record changed interval(s) in History → Frames and the new type or old → new type in Details; unchanged events are excluded from this summary.

## 11.7 Verify and Save Verification

The Verify button in Display → Others → Save and the dialog before Save / Save as record the current bout's manual review. **Not reviewed** stores an empty value; `1` means pass and `0` means needs attention. Both numeric values mean the item was checked. Text fields accept free input. A checkbox has only checked/unchecked states and cannot represent an unreviewed blank; use a dropdown when that distinction matters.

In the Verify dialog, **Confirm review** writes answers to the current Boutlist row immediately. The dialog shown before saving writes confirmed answers after the result is saved successfully. Editable fields require Sync and an existing mapped column. **Skip review** continues the save, and **Back** cancels it. The Boutlist row stores the answers. Review queue status is stored in the queue CSV.

The master **Verify review status before saving** switch in Display → Boutlist fields opens the dialog once per Save / Save as, including saving while closing a file. Turning it off preserves existing review data. The Verify button can still open the dialog.

The definition table below that switch contains settings, not the current bout's answers. Save the Boutlist fields or All settings scope to activate edits. User questions and choices are displayed as entered, independently of the interface language.

| Column | Entry and behavior |
| --- | --- |
| Internal field | A stable identifier starting with a letter, containing letters, digits, or underscores; unique and distinct from built-in Markers fields |
| Enabled | Include the field in the dialog; disabling it preserves its stored value and stops synchronization |
| Question | The question shown to the reviewer, exactly as entered |
| Boutlist field | An existing Boutlist column; leaving it blank disables Sync |
| Sync | Register this confirmed review after a successful annotation save; requires Enabled and an existing nonempty mapping |
| Input type | `dropdown`: choices plus an unreviewed blank; `text`: free input; `checkbox`: two states without a blank |
| Choices (a\|b\|c) | **Dropdown only.** Separate stored values with `\|`, such as `1\|0` or `pass\|fail`. Values are stored literally; this is neither JSON nor a value:label syntax. Not reviewed is added automatically; do not add an empty choice |
| Tip | The full review criteria, shown on hover and stored/displayed exactly as entered |
| Choice labels | Optional `\|`-separated labels aligned with Choices, such as stored `1\|0` and displayed `Pass\|Needs attention`. Blank shows the values. Counts must match and labels must be nonempty |
| Blank label | Text for the empty value, such as Not reviewed. Blank uses the standard interface translation |

Adding a review field or switching to dropdown fills empty Choices with `1|0`; edit them for other stored values. Choices must be nonempty, distinct, and free of empty segments; `1||0` is invalid. Saving an invalid draft reports an error and preserves the existing configuration. Switching to text or checkbox clears and disables Choices, Choice labels, and Blank label. Drag a header boundary to resize Question. The input-type combo displays its text once.

Deleting/disabling definitions does not clear existing result values. Renaming an internal field does not migrate old values. Unmapped or absent columns cannot be updated indirectly through Markers JSON.

### 11.7.1 Verification Recommendations

All three platform templates now provide these four fields, with concise Chinese questions and `1|0` QC choices:

| Field | Input | Meaning |
| --- | --- | --- |
| `response_qc_pass` | Dropdown: `1` pass, `0` needs attention, blank unreviewed | For stimulus trials, inspect the first 2 seconds after the stimulus segment begins, including trials for which the program counted zero (check them for missed responses). Check for missed/double counts and ensure each counted downward response belongs to one bee. For baseline trials, inspect the actual included baseline window and distinguish real downward movement from ID-switch artifacts |
| `spatial_qc_pass` | Dropdown: `1`, `0`, or blank | For stimulus trials, inspect the first 6 seconds, stopping at earlier contact or video end. For baseline trials, inspect the actual baseline window. Box counts and positions must support group depth, dispersion, and neighbor analysis. ID-label swaps alone do not prevent this spatial check from passing when box counts and positions are correct; this does not imply the response-identity check has passed |
| `reviewer` | Text, such as `WTY` | The actual reviewer's name or stable initials; the latest entry is remembered and must be changed when the reviewer changes |
| `review_date` | Text: `YYYY-MM-DD` | Defaults to today and can be edited to the actual review date |

Once either QC field is `1` or `0`, confirmation checks any enabled reviewer field is nonempty and any enabled date is a valid `YYYY-MM-DD`. Do not use `0` for an unreviewed item. A checkbox's unchecked state is an explicit negative value, not blank; keep the two QC fields as dropdowns when blank matters.

## 11.8 Synchronization and Acceptance

**Sync: From / To** reads from or writes to the current Boutlist row. Configure mappings in Display → Boutlist fields → Edit sync fields. Use the marker’s Internal field as the mapping key. A coordinate column can contain the coordinates with their placement frame or a reference. Hive also supports the existing nest coordinate and placement-frame columns. The sync dialog lists missing mappings, missing columns, and invalid values. Other available values can still be synchronized. After saving, reopen the file and verify the markers and events.

Markers synchronization with Boutlist handles only mapped fields whose columns actually exist; absent columns do not clear current identities, verification, or Camera states. Differences in numeric storage precision are not treated as conflicts; a simple `scale_px_per_cm` summary does not replace existing complete Scale calibration. See [Scale](09_Scale_Operations.md#98-single-values-ranges-and-complete-output) for full calibration source selection and [Boutlist](13_Creating_and_Using_a_Boutlist.md#135-opening-and-synchronization-procedure) for field and comparison rules.
