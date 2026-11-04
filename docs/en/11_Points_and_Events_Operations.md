# 11 Points and Events Operations

[Return to the main index](00_Annotation_Reviewer_User_Manual.md)

## 11.1 Purpose and Storage

Points records analysis boundaries, the capture reference frame, subject identities, the hive entrance, and review notes; Events records intervals for behavior or data quality events. These are manually collected information and do not automatically infer experimental conclusions from trajectories.

When saving annotation SQLite files, basic information is written to `info_points` and events to `info_events`. Basic fields can synchronize to Boutlist through mappings; Sync to does not automatically expand event intervals into individual Boutlist columns. Complete scale calibration is stored separately in `scale_calibration`.

## 11.2 Set and Goto in Points

| Button | set point | goto point |
| --- | --- | --- |
| Start | Sets the current frame as the analysis start | Navigates to the stored start frame |
| End | Sets the current frame as the analysis end | Navigates to the stored end frame |
| Capture | Sets the current frame as the capture reference | Navigates to the capture reference frame |
| Hive | Enters hive entrance position selection | Views the recorded reference position |
| Captor | Selects the successful hornet's box and records its ID | Selects that ID and, if needed, navigates to the nearest frame where it is present |
| Victim | Selects the captured honeybee's box and records its ID | Selects that ID and, if needed, navigates to the nearest frame where it is present |

`set point` and `goto point` are mutually exclusive modes. The same button acts differently in each mode; check the current mode before operating it.

In the Confirm edit dialog for Start, End, and Capture, Yes sets the current frame, Clear clears the corresponding field, and No cancels; both changes and clearing can be undone through the main History. When committing changes or clearing Start, End, Capture, Hive, Captor, or Victim, the application checks enabled Boutlist field mappings and asks whether to synchronize differences. Confirming a clear writes an empty cell; declining synchronization does not roll back the edit in the application. After clearing End, the analysis range may still use an existing Capture or the video boundary as its default endpoint; distinguish explicit records from defaults used in range calculation.

Hive, Captor, and Victim use pending selections. Click a button to enter selection mode; it remains pressed. Select Hive coordinates or the correct object box in the image, and the button text displays the candidate value. Clicking elsewhere in the main window outside the image clears the candidate and displays an empty value. Click the same button again to commit; Esc discards the candidate. Any window area other than the same commit button can clear the candidate; original data is retained until commit. Hive no longer accepts positions outside the image as coordinate input.

After entering Hive setup, the axis preview follows the mouse until the first image click; afterward it remains at the candidate origin until another selection, commit, or cancellation. This preview also works with only a video loaded and no annotations. It uses the current Axis appearance and Camera coordinate transformation without changing the Axis display toggle or writing Hive data early.

In the marker area below the progress bar, clicking directly beneath the Start or End symbol at the height of the Capture arrow also navigates to the corresponding frame. At a recorded Start, End, or Capture frame, the corresponding text appears at the lower left of the image in the Events HUD style. If several markers or events share a frame, their labels appear together. Playback previews and video exports with HUD enabled use the same labeling rules.

A Notes field records brief facts relevant to interpretation and analysis, such as uncertainty due to occlusion or unusual clip conditions.

`Save only the target segment` on the third Points row controls whether Save and Save as save only final annotations within Start–End, including both endpoints; data outside the range is not deleted from memory. This is a session-specific save range choice, not an INI setting, and resets when closing or changing files.

## 11.3 Information Field Definitions

| Field | Definition |
| --- | --- |
| analysis_start_frame | First frame included in analysis of the capture-associated interaction |
| analysis_end_frame | Last included frame; verify against the analysis objective and Capture |
| capture_frame | First frame in which the successful hornet makes actual contact with the captured honeybee, continuously leading to successful restraint and removal |
| captor_id_at_capture | Verified identity of the successful hornet |
| victim_id_at_capture | Verified identity of the captured honeybee |
| hive_x_px / hive_y_px | Hive entrance reference coordinates; verify their coordinate space in Camera mode |
| left_censored | The actual interaction onset precedes the available analysis images, preventing complete observation of the onset |
| verified_capture_pair | Identities and trajectories of the successful hornet and captured honeybee have been verified throughout the sequence |
| verified_exposed_bees | Low-positioned, peripheral, and isolated honeybees have been checked specifically for missed detections, duplicates, and drift |
| verified_other_hornets | Other hornets' frame-by-frame presence and conspecific interference events have been checked |
| review_notes | Free-text review notes |

The left-censoring flag `left_censored`, which records whether the interaction sequence is complete, is determined and set manually; use false when the interaction onset is fully visible. It is not inferred automatically from the first detection frame, hornet entry direction, or proximity to the image boundary. If the actual interaction onset can be observed, set Start and use false (unchecked); if the interaction is already underway at the start, use true (checked). The state at the analysis start is simply the state present at that moment; a fully observed interaction onset cannot automatically be described as an undisturbed "clean baseline."

## 11.4 Standard Points Procedure

1. Correct key subjects' identities and trajectories first.
2. Switch to set point, locate the interaction onset frame, and click Start.
3. Locate the successful capture sequence and determine Capture frame by frame; set End according to the analysis scope.
4. Click Captor and Victim in turn, select the correct canvas box, and click the same button again to commit.
5. Click Hive, specify the hive entrance reference position in the image, and click Hive again to commit. To clear a value, enter its selection mode, click a main-window area outside the image, then click the original button to commit.
6. Switch back to goto point and click each item to verify the records.
7. Enter Notes as needed, synchronize Boutlist, and finally save the annotation file.

**Example: the hornet is already exerting sustained pressure when the video begins.** Use the actual available analysis start for Start and select left-censored onset in the verification dialog; do not invent an onset outside the available images. Record Capture at the actual successful contact frame.

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
3. Enabled controls whether new events of this type can be added and whether its HUD/strip is displayed; Name controls its label in the dropdown, event table, and HUD. Double-click Color to choose a color; the table stores a hexadecimal `#RRGGBB` code applied to the event table and strip.
4. Band 0 hides this type's strip; 1, 2, and 3 use the three strip rows below the progress bar respectively. Hiding a strip does not delete events or disable HUD display.
5. Valid changes immediately preview names, colors, and strips. Close accepts changes for the current run without writing to INI; Cancel or the window × discards changes since opening and restores the previous display. To retain changes for later runs, click Save settings, or save with Event types/All selected in Display's save scope; after a successful save, Cancel discards only subsequent unsaved changes.

Changing names and colors does not change stored event identifiers or frame intervals. Disabling or deleting type definitions does not delete existing events. Renaming Internal key does not migrate events under the old identifier; explicitly change their types in the event table. Existing events not configured on this computer are retained; type definitions in result files can supply display names and colors. Type configuration is an application setting outside annotation History; event interval changes still enter History.

**Example:** Create `camera_obstruction`, set Name to `Camera obstruction`, choose red, and set Band to 3. After saving Event types, select the type in the dropdown and record an interval. Changing Band to 0 and saving hides only the strip; clearing Enabled and saving hides both its HUD and strip, while existing intervals remain in the results.

## 11.6 Creating, Editing, and Deleting Events

### 11.6.1 Creating an Interval

1. Select a type in the event type dropdown and clear any existing event selection.
2. Navigate to the start frame and click Start; a new event is initially created with start=end and selected.
3. Navigate to the end frame and click End; the event becomes an interval including both endpoints, and selection is cleared afterward.
4. Click the event in the table to inspect its range; play around the interval to verify its boundaries.

With no event selected, clicking either Start or End creates a point event at the current frame. Single-frame events use start=end and share the interval structure, for example `{"type":"bee_slip","start":2301,"end":2301}`.

Conspecific interference, pressure from other hornets, and loss_or_blur intervals may overlap in time; overlap means that different facts coexist and should not be forced into one mutually exclusive category.

### 11.6.2 Editing an Existing Event

Click an event column to select it, then change the type dropdown to update its type; navigate to a new boundary frame and use Start/End to update the selected event. Double-click the corresponding table content to edit the type or range. With multiple events selected, boundary or type changes may affect all selected events; verify selection before proceeding.

Each event occupies one table column; events containing the current frame are highlighted. Clicking selects and navigates; column position does not indicate event priority. Delete removes selected event records, not trajectory boxes or the original video.

## 11.7 Verify and Save Verification

The Verify button below Victim in Points and the verification dialog before Save / Save as record independent bout states. Checked items mean true; unchecked items mean false. All items need not be checked to allow saving.

Confirm commits results for displayed items and continues the corresponding workflow; Back discards this verification operation and, during saving, cancels continuation of the save. Items not displayed retain their existing values in the current bout.

The verification dialog contains no save range option. Confirm has default focus, and Space submits confirmation without triggering the Tracking Space shortcut.

Display → Boutlist fields provides the master Verify review status before saving toggle. When enabled, the dialog appears once for each Save/Save as; choosing to save while closing a file follows the same verification process without an additional closing check. Disabling the master toggle prevents automatic dialogs for Save/Save as and retains existing verification states; Verify in Points can still open the dialog manually.

Below the master toggle is a review definition table supporting additions and deletions. Its toggles are settings, not review results for the current bout.

| Column | Behavior |
| --- | --- |
| Internal field | Stable internal review status field; begins with a letter, may contain digits and underscores, and must neither duplicate another field nor use an existing Points field |
| Enabled | Enables this item; disabling it stops questions and synchronization while retaining existing result status |
| Question | English question text displayed in the verification dialog |
| Boutlist field | Corresponding Boutlist column name; blank fields do not participate in Boutlist reading or writing |
| Sync | Allows reading from or synchronizing to Boutlist; requires the item to be enabled, a nonempty column name, and an existing column |

Use Add/Delete to add or remove definitions and edit cells to change content. Save and activate drafts through the Boutlist fields or All scope of Save settings. Saving other groups does not apply changes to this group. Enabled means the item is asked in Verify; there is no separate Ask setting. If no items are enabled, Verify is empty except for Confirm/Back. Actual states confirmed in the dialog enter project History and the result SQLite; settings table changes do not enter project History. Deleting or disabling definitions does not clear existing states, and changing an internal field does not migrate the old field automatically.

**Example:** Add `identity_checked`, enable it, enter a question, and leave Sync off. The question appears in Verify and its answer is saved to the result SQLite, without a Boutlist synchronization prompt. Later, add an `identity_checked` Boutlist column, specify it in the configuration table, enable Sync, and save settings to permit synchronization. Without a Boutlist field, Sync is disabled and automatically unchecked. If the corresponding column is unconfigured or missing, Points JSON does not indirectly overwrite this item.


### 11.7.1 Verification Recommendations

- Capture pair: check the successful hornet and captured honeybee throughout the analysis range, not only at the capture frame.
- Exposed bees: focus on boxes most likely to affect statistics for low-positioned/isolated opportunities.
- Other hornets: check frame-by-frame counts and positions; unrelated individuals may have discontinuous IDs, but this does not justify overlooking many missing frames.
- Left censored: records whether the actual interaction onset is observable, which differs from whether review has been completed.

## 11.8 Synchronization and Acceptance

Sync from Boutlist / Sync to Boutlist use Boutlist field mappings configured in Display; Hive uses nest coordinate columns according to the application mapping. Verify the current row before synchronization; blank mappings are neither read nor written. After saving, reload and check Start/End/Capture, Captor/Victim, Hive, enabled review states, Notes, and event intervals.

Points synchronization with Boutlist handles only mapped fields whose columns actually exist; absent columns do not clear current identities, verification, or Camera states. Differences in numeric storage precision are not treated as conflicts; a simple `scale_px_per_cm` summary does not replace existing complete Scale calibration. See [Scale](09_Scale_Operations.md#98-single-values-ranges-and-complete-output) for full calibration source selection and [Boutlist](13_Creating_and_Using_a_Boutlist.md#135-opening-and-synchronization-procedure) for field and comparison rules.
