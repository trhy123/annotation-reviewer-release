# 8 Tracking Instructions

[Return to the main contents](00_Annotation_Reviewer_User_Manual.md)

## 8.1 Purpose and Functional Scope

Tracking creates, extends, or corrects frame-by-frame position records for a specified target. The target identity is specified by `Track ID`; automatic tracking searches for the target appearance under that identity and does not reassign identities among multiple individuals.

| Function | Input basis | Output | Applicable tasks |
| --- | --- | --- | --- |
| Manual marking | A manually specified position and box dimensions in the current frame | A single-frame box for the current ID | Filling missed detections, correcting occluded segments, and establishing sparse key positions |
| Automatic template tracking | One or more image templates, a search region, and scoring criteria | Target boxes and matching information accepted frame by frame | Tracking targets whose appearance remains distinguishable |
| `Mouse guided` | Image templates and a continuously moving mouse-controlled search center | Target boxes that pass the same scoring criteria | Fast-moving targets with unstable predictions but distinguishable appearances |
| `Assist` | An initial box generated manually or automatically, and a local image | A box refinement result subject to boundary constraints | Improving box dimensions and local center positions |
| `Edit → Trajectory` | An existing target trajectory and a selected frame interval | Trajectory coordinates committed after preview | Local curve correction, redrawing, smoothing, point redistribution, and overall transformation |
| Camera Anchor tracking | A selected background anchor and its image template | Frame-by-frame observations of a Camera anchor | Providing position observations for existing camera motion compensation |

Tracking, Detection, and Match serve different purposes: Detection detects targets in video and generates detection trajectories; Tracking supplements or corrects positions under a specified ID; Match handles alignment, matching, and binding between imported manual trajectories and detection trajectories. Tracking `Overwrite` does not merge IDs or combine trajectories with different identities.

These instructions cover all Tracking entry points and the directly related shared Trajectory functions, Camera Anchor tracking, trajectory display, and saving behavior. Complete procedures for Scale calibration, Match identity integration, and Points/Events recording are provided in the respective module instructions.

## 8.2 Coordinates, Frame Numbers, and Data States

### 8.2.1 Coordinate Definitions

Annotations use pixel coordinates in the original video image: the coordinate origin is at the upper left, `x` increases to the right, and `y` increases downward. `x/y` represents the box center, and `w/h` represents the width and height of the axis-aligned box, all in original video pixels.

Display zoom, panning, Camera compensation, and Expanded motion canvas only change the mapping between displayed images and interaction coordinates. Mouse clicks are mapped back to original video coordinates before annotations are generated; automatic matching always reads the original video image. Blank areas of an expanded canvas without original video image content cannot be used to add marks or capture templates.

Boxes must remain within the original image. Near an edge, the program adjusts the center or limits the dimensions to fit the image boundary. The final box center near an edge may therefore differ slightly from the clicked position. Camera Anchor stores point positions constrained by the source image boundary, independently of object box dimensions.

**Example:** The original video is 1920 px wide, and the display window scales the image to half size. A movement of 10 px on screen corresponds to approximately 20 px in the original video; `Offset X = 10` still means 10 px in the original video, rather than 10 px on screen.

### 8.2.2 Sequential Decoded Frame Numbers

`frame` starts at 1 and numbers actual decoded images consecutively in decoding order. Gaps in container timestamps do not cause virtual images to be inserted according to “timestamp difference × FPS”, or images to be duplicated to fill the gap.

Random seeking uses the video image index to locate a decoding starting point and verifies the decoded result. When timestamps cannot be used reliably, sequential decoding and counting from the beginning provide a fallback. The index may need to be built during the first seek; while waiting, the last confirmed image remains displayed, and an unconfirmed image is not used to represent the requested frame.

**Example:** If the timestamps of decoded images 1000 and 1001 differ by 0.8 s, they are still labeled `frame = 1000` and `frame = 1001`. Tracking operates between the two actual images without generating additional duplicate records.

Sequential frame numbers provide a consistent image reference for recognition, annotation, and seeking, but do not prove that no actual images were lost during recording. Durations calculated using the following formula rely on a time model based on sequential images and the nominal frame rate:

$$
\frac{\mathrm{frame}_2 - \mathrm{frame}_1}{\mathrm{FPS}}
$$

For analyses involving actual recording time, independently confirm whether timestamp gaps result solely from container issues. Loaded legacy CSV files retain their original frame numbers; the program neither guesses renumbering from gaps nor automatically verifies their coordinates. Before indexing is complete, new edits in the current session record the identity of the corresponding image; after indexing, the program maps these edits, templates, previews, and associated undo records to verified sequential frame numbers. If an image cannot be identified uniquely, edits are retained, final output is suspended, and `Frame mapping pending` is displayed.

### 8.2.3 Four Data States

| State | Meaning | Entered in formal History | Merged into the result data table |
| --- | --- | --- | --- |
| Match candidate | A position found by the current algorithm that may not pass the thresholds | No | No |
| Pending Tracking points | Manual marks, accepted automatic points, or pending deletions | Not yet committed as a complete segment command | The session must be committed before saving |
| Trajectory preview | A candidate trajectory produced by curve editing, fitting, or transformation | No | `Apply` or `Discard` is required first |
| Committed working data | Edit results for which `Finish` or `Apply` has been executed | Yes | Written when saved |

`Finish` commits changes to the current working data and History; it does not save them to disk. `Cancel` only discards an uncommitted session and cannot cancel changes already committed to History; use History Undo for committed changes.

On first entering a new manual or automatic Tracking session, the program displays the `Start tracking` dialog. Check or modify `Track ID`, `Class`, `Box W/H`, and `Assist`, then press `Start`; `New` to the right of the ID fills in a currently unused ID. If no identity is selected and no previous tracking identity is retained, the ID is initially blank in both the panel and the dialog; pressing Start with this field blank automatically assigns an unused ID when tracking begins. Overwrite and pause rules for existing IDs are displayed in the dialog; selecting an existing ID means continuing to correct that identity. Manual takeover, pausing, and resuming within the same session do not display this dialog again. Cancel creates no session, does not pause video playback, and does not commit other pending edits. Trajectory and Camera Anchor have their own entry procedures.

## 8.3 Interface and Controls

Tracking contains a shared top area and four tabs: `Track Motion`, `Templates`, `Weights`, and `Advanced`. The shared area remains visible when switching tabs; the shared buttons on the right are `Cancel`, `Finish`, and a state-dependent `Start / Run Auto / Pause / Resume` button. The main control area uses a consistent fixed height; Advanced content scrolls vertically instead of increasing the height of the entire panel to accommodate settings.

The initial values below are the values used when the controls or tracking controller are first created. Loaded software preferences, selected target boxes, previously adjusted regions, and the current session state may change the displayed values. Numeric inputs are edited as text; numeric fields and drop-down lists do not change in response to the mouse wheel.

### 8.3.1 Shared Top Area

| Control | Input or initial value | Behavior and purpose |
| --- | --- | --- |
| `Track ID` | Nonnegative integer | Specifies the target identity to add or correct; press Enter or `Use ID` after entry to validate |
| `Use ID` | Button | Validates the ID; continuing with an existing ID requires confirmation; does not add trajectory points by itself |
| `New` | Button | Fills in the largest numeric ID in the current working data plus 1; does not write a record by itself |
| `Class` | Initial class list comes from INI classes; a name can be entered | Class of points written in this session; when using YOLO Assist, it must agree with the configured model class mapping |
| `Assist` | `None` | `None / Edge / YOLO`; shared by manual and automatic marking |
| Box size mode | `Fixed box` | `Fixed box / Previous box`; determines initial box dimensions for manual points |
| `Box W/H` | 9 / 9 px; permitted range 1–65535 | Initial manual box width and height; may be filled automatically when an existing box is selected or Auto is taken over manually |
| `Auto next` | Selected | Advances one frame in the tracking direction after a manual point is completed; does not control frame-by-frame Auto execution |
| `Overwrite` | Cleared | Whether Auto may replace existing positions with the same ID without confirmation |
| Status line | Single line of text | Displays the current action, failure reason, and `Pending` count; hover to view the full content |
| `Cancel` | Available during a session | Discards the entire pending session and exits |
| `Finish` | Available during a session | Commits the entire session as one History edit and exits |
| State button | `Start`, etc. | Starts or pauses manual marking when no templates exist; runs or pauses Auto when templates exist |

### 8.3.2 Track Motion

| Control | Input or initial value | Behavior and purpose |
| --- | --- | --- |
| `Add Template` | Toggle button | Enters template selection mode; click the video to sample; click the button again to cancel selection mode |
| `Template area` | Visual editing button | Moves or resizes the cyan template box in XYWH form; samples the template again from the current frame when dragging ends |
| `Search area` | Visual editing button | Adjusts the yellow search region and its center offset; does not change the template image |
| `Mark offset` | Point selection button | Specifies the final annotation center offset relative to the recognized feature center |
| `Search` | `Predict` | `Predict / Follow / Fixed / Cursor` |
| `Reverse` | Cleared | Tracks toward lower frame numbers when selected; switching pauses Auto |
| `Mouse guided` | Cleared | Linked to `Cursor` search; hold the left mouse button to provide the search center, and release to pause |
| `Rate` | Updated after running | Recent actual frame advance rate expressed as a multiple of normal playback speed; hover to view decoding waits and matching time |
| `Score` and adjacent `≥%` | Threshold 72%; range 0–100 | Most recent best match score and its minimum acceptance value |
| `Margin` and adjacent `≥%` | Threshold 6%; range 0–100 | Score difference between the best and competing positions, and its minimum acceptance value |
| `Stop due to` | `Poor match` | `Poor match / No match / Never`; determines whether to pause after a match is rejected |
| `Show trail` | Follows Display settings | Synchronized with `Display → Trail before`; does not create a separate set of trajectory display settings |
| `Evolution %` | 5; range 0–100 | Proportion of the new appearance blended into the winning template after an accepted match |
| `Tether %` | 10; range 0–100 | Proportion of the original template blended back in after template evolution |
| `Delete` | Button | Opens a nonmodal frame-range deletion window |

### 8.3.3 Templates

| Control | Behavior |
| --- | --- |
| Template list checkboxes | Determine whether each template participates in matching; disabled templates incur no template matching computation |
| Template list row | Displays a thumbnail, source frame `F…`, width, and height; click to view the original template preview |
| Template list double-click | Selects the template as the current template and jumps to its source frame |
| `Remove selected` | Deletes one or more selected templates; retains existing annotation points |
| `Use selected only` | Enables only the selected templates and disables all others |
| `Enable all` | Enables the entire template library |
| Image preview | Ctrl + mouse wheel zooms around the cursor; middle-button dragging pans; double-click restores fit-to-window |

Templates are retained in memory separately for each current video data session and target ID. Pausing, changing frames, manual corrections, `Finish`, saving, and canceling pending annotations do not automatically delete templates; returning to the same ID within the same data session allows their continued use. Different IDs and Camera Anchor do not share templates. Use `Remove selected` to remove templates, or clear their checkboxes to disable them temporarily. This in-memory library is not retained after switching videos, creating a new data session, or closing the program; saving an annotation file does not save template images.

### 8.3.4 Weights

| Control | Initial value and range | Purpose |
| --- | --- | --- |
| `Luma %` | 35; 0–100 | Weight of normalized correlation of luminance patterns |
| `Gradient %` | 30; 0–100 | Weight of correlation of gradient magnitude patterns |
| `Color %` | 15; 0–100 | Weight of color similarity between the template and candidate region; the comparison method is determined by Color in Advanced |
| `Edge %` | 15; 0–100 | Weight of edge overlap |
| `Motion %` | 5; 0–100 | Prior weight favoring candidate positions near the current search center |
| `Weights` | Calibrated by default | Fixed uses fixed input proportions; Calibrated retains calibrated weights; Adaptive updates slowly using only reliable matches |
| `Recalculate` | Enabled when templates exist and the target can be confirmed in the current frame | Pauses and recalibrates shared weights without rewriting accepted points |
| `Background` | Automatic surrounding background by default | Click and drag a background/interference region in the image; right-click this button to clear that region and restore automatic background |
| `Rotate ±°` | Enabled with a default range value of 90; permitted range 0–180° | Searches positive and negative rotations relative to the template reference appearance; ±180° covers all orientations |
| `Scale ±%` | Disabled with a default range value of 20; permitted range 0–75% | Searches reduced and enlarged sizes relative to the template reference dimensions |
| `Offset X / Offset Y` | 0 / 0 px; permitted range −65535–65535 | Mark offset of the active template, expressed in that template's reference coordinates |
| `Decode ahead` | Enabled by default; preference can be saved | Decodes the next frame in advance, overlapping decoding with matching of the current frame |
| `Match workers` | 4 by default; permitted range 1–16; preference can be saved | Number of CPU worker threads evaluating independent templates in parallel; 1 is serial execution |

The initial template box is 19 × 19 px, and the initial search box is 90 × 90 px; both are primarily adjusted in the image. These are separate parameters from manual `Box W/H`.

### 8.3.5 When Parameters Take Effect

| Change type | Effect |
| --- | --- |
| Manual W/H, Auto next | Applies to subsequent manual points and their frame advancement; does not rewrite all previous points |
| Score, Margin, Evolution, Tether, Stop, matching weights | Used by subsequent matching requests; changing values does not reevaluate accepted points |
| Search, Mouse guided, Reverse, Rotate/Scale toggles and ranges | Pauses on modification; inspect before running again |
| Template/Search visual regions | Resamples the template region; the search region changes only search configuration; clicking while running pauses before adjustment, then Resume continues |
| Offset X/Y, Mark offset | Pauses and updates the active template offset; updates the current frame box when conditions permit |
| Template enabling or deletion | Pauses and changes the set of templates participating in subsequent matching |
| Show trail, display style | Changes only the display without recalculating matches or rewriting positions |

An in-progress matching request retains the parameters in effect when it was issued. Some numeric changes do not automatically interrupt a request that has already started; for strict comparisons between settings, Pause first, then adjust and run. Score/Margin colors may immediately reevaluate the latest displayed values against new thresholds, but this does not withdraw previously accepted records.

### 8.3.6 Advanced

| Control | Default and range | Behavior |
| --- | --- | --- |
| Candidates | Combined | Combined proposes candidates using the existing average luminance/gradient response; Multi-channel allows enabled appearance channels to propose candidates separately, then removes duplicate positions near the same spatial peak |
| Budget | 12; permitted range 1–128 | Maximum spatial candidates per template and search pose; increasing it requires evaluation of more candidates, with rotation/scaling further increasing the cost |
| Color | Mean | Mean compares average BGR; HSV histogram compares coarse hue/saturation distributions, still using the original Color weight |
| Guard template updates | Disabled by default | Separates position acceptance from template learning; when disabled, templates continue to update after every accepted result |
| Score ≥% | 85; permitted range 0–100 | Learning score threshold under Guard template updates; does not replace the position acceptance threshold in Track Motion |
| Margin ≥% | 10; permitted range 0–100 | Learning competition margin threshold under Guard template updates, expressed in percentage points |
| Reliable matches | 3; permitted range 1–100 | Permits an update after the same template wins the specified number of consecutive reliable matches; does not delay recording accepted positions |

Changing Advanced parameters pauses Auto, invalidates old in-flight results, and retains templates and pending points. Changing the candidate strategy, budget, or color method rebuilds the basis for weight calibration; recalibration is requested automatically when the current frame agrees with the confirmed target position. Otherwise, use Recalculate or Add Template at a reliable target position. Changing numeric thresholds does not rewrite previously accepted points. Parameter preferences are saved under `tracking/` keys in `settings.ini`.

**Comparison procedure:** Keep the video interval, templates, and position acceptance thresholds fixed. Use Combined/12/Mean as the baseline, then compare Multi-channel/24. Record incorrect targets, pauses, and actual recognition rate to establish the benefit of additional candidates; then compare HSV histogram separately. Color distributions may help distinguish targets from backgrounds with similar average colors, but small templates or changing appearances may also introduce noise; higher scores alone do not establish better performance.

**Template protection example:** The position acceptance thresholds are Score 72% and Margin 6%, the learning thresholds are 85% and 10%, and Reliable matches=3. A position with Score 80% and Margin 8% can be recorded while the template appearance remains unchanged; Evolution/Tether runs only after the same template reaches the learning thresholds three consecutive times. The count restarts after a result below the learning thresholds, a failed match, a manual correction, or a change in the winning template. Status messages distinguish Update allowed, Collecting evidence, Update held, and other states; hover to read the rules.

## 8.4 Standard Operating Procedures

### 8.4.1 Procedure A: Create a New Automatic Trajectory

**Prerequisites:** A video is open, the current image has finished seeking, and a separate target trajectory needs to be added.

1. Open `Tracking → Track Motion`, click `New`, and check `Track ID` and `Class`.
2. Seek to a frame in which the target is clear, its identity can be confirmed, and background interference is limited.
3. Click `Add Template`, then click the recognized feature center. Alternatively, Alt + Shift + left-click directly in the video.
4. Wait for the template status to become available. Check the captured content in `Templates`, then return to `Track Motion`.
5. Click `Template area` and adjust the cyan box to include features that can be recognized consistently. Avoid including excessive unrelated background.
6. Click `Search area` and adjust the yellow box to include likely target positions in the next frame, with room for the complete template.
7. If the final annotation position differs from the feature center, use `Mark offset` to set the target center.
8. For the first run, use `Search = Predict` and `Stop due to = Poor match`, retain the initial Score and Margin thresholds, and decide whether to enable Assist according to the target.
9. Click `Run Auto`. Check that the box covers the same individual while monitoring Score, Margin, Rate, and the status line.
10. Pause and inspect the current point, trajectory, and timeline coverage. Correct erroneous points through manual takeover or local retracking.
11. Click `Finish` to commit this tracking session as one History edit.
12. Save the annotation file using the program's saving controls and complete the checks in the saving procedure.

**Result:** A pending box is generated at the template source frame; subsequently, automatic points are generated only by matches satisfying all acceptance criteria. Passing through a frame does not automatically annotate it if recognition fails.

### 8.4.2 Procedure B: Extend an Existing ID

1. Seek to a frame with a reliable existing box for the ID, and select that box.
2. Check the ID, class, and manual box dimensions filled in automatically by Tracking.
3. You may press `Use ID` to check the identity beforehand; when starting the session, review the existing-ID rules in the `Start tracking` dialog and press `Start`.
4. Create a template from a reliable frame and adjust the search region.
5. Run toward the missing segment. Select `Reverse` when filling earlier video frames.
6. When an existing position with the same ID is encountered, retain it, pause for inspection, or allow overwriting according to the task.
7. Check the position, identity, and box dimensions at the join, then `Finish` and save.

**Result:** New points continue the same ID. Existing records remain unchanged except for frames explicitly edited in this session; no other ID is automatically renamed or merged.

### 8.4.3 Procedure C: Add a Segment Manually

1. Select an existing box to reuse its identity, or create an ID with `New`.
2. Select `Fixed box` and set `Box W/H`; select `Previous box` to reuse historical dimensions.
3. Check `Auto next` and `Reverse`. `Auto next` is usually enabled for frame-by-frame clicking and can be disabled when marking only a few keyframes.
4. With no templates, click `Start`, confirm the settings dialog, and enter continuous manual marking mode.
5. Click the target position in each frame. Confirm that the current frame is displayed before specifying the next point.
6. Correct errors using Ctrl + Z, Delete in the current frame, or another click.
7. Right-click the image or click `Finish` to commit; Enter on the Tracking tab operates Start/Pause/Resume.

**Result:** Each click writes one position for the same ID in the current frame. Manual points do not automatically create new templates or connect unmarked intermediate frames.

### 8.4.4 Procedure D: Make a Temporary Correction During Other Work

1. Select the target box to correct and check the current frame and target identity.
2. Hold Alt and left-click the correct position in the video; if there is no session, confirm the settings dialog, after which the program processes this click. Pressing `Cancel` leaves this click unmarked.
3. To correct consecutive frames, keep holding Alt and click frame by frame with `Auto next`.
4. Release Alt.

**Result:** If no Tracking session existed before this operation, a continuous manual session is created while the main function tab stays in place. Releasing Alt retains the Track ID and pending points; the same identity continues without creating another session. An existing Auto session resumes or remains paused according to the manual takeover rules. Use Finish or right-click to commit everything when done; Enter on the Tracking tab operates Start/Pause/Resume, while Enter on other tabs retains its commit behavior. Use Cancel or Esc to discard the pending session.

## 8.5 Identity, Class, and Session Management

### 8.5.1 Track ID Confirmation Rules

`Track ID` accepts nonnegative decimal integers. Negative values, letters, and inputs containing decimal points are invalid IDs; the maximum is 9007199254740991. `001` and `1` represent the same numeric identity; display padding does not create a new identity.

Press Enter or click `Use ID` after entering a value to validate it. If this separate check finds an existing ID:

- Choose Yes to continue using that identity. Manual marking may replace positions in overlapping frames; Auto follows the Overwrite rules.
- Choose No to clear the `Track ID` field and enter another ID.

After identity selection is cleared, the last ID that was merely selected is not retained as the default tracking target. If no object tracking has been completed, Track ID returns to blank; otherwise, the most recently completed object ID may be retained. An ID explicitly entered or specified with New is retained, and an ongoing Tracking session does not change IDs when ordinary selection changes.

When starting a manual or automatic session, the `Start tracking` dialog jointly verifies the ID, class, and initial box settings. Selecting an existing ID displays the applicable rules; pressing `Start` means continuing with that identity, without a repeated Yes/No prompt. Pausing and resuming within the same session do not repeat verification.

This confirmation only establishes which identity to use; it does not unconditionally authorize Auto to overwrite all existing positions for that identity. Existing-ID confirmation and Auto overwrite confirmation are separate operations.

### 8.5.2 Selection Linkage and Class

Without an active session, selecting an existing box in the current frame fills in its ID, Class, and W/H. Once a session starts, ID and class controls are locked; clicking another object within the session does not automatically change the tracked identity to another ID.

`Class` accepts custom names; leading and trailing whitespace is removed and the name is converted to lowercase when written. The class applies to records written in this session; continuing to track the same ID does not automatically rewrite the class of all unedited frames for that ID.

**Example:** Existing data for ID 123 has class `hornet`. Selecting ID 123 on the correct box and extending it creates new points with `hornet`. If Class is manually changed for this session, only points written or replaced in this session use the new class; this operation does not change the class of the entire trajectory.

### 8.5.3 Session Boundaries

| Operation | Effect on the session |
| --- | --- |
| `Pause`, dragging the progress bar, or jumping frames | Pauses, retains pending points and templates, and invalidates old background requests |
| Switching the four Tracking tabs | Pauses and exits current template selection or manual clicking mode, retaining the session |
| Switching to the main `Edit` panel | Pauses and retains the session, allowing further use of shared trajectory tools |
| Returning to `Camera` during a Camera Anchor session | Pauses and retains the anchor session |
| Switching to another main panel that commits on leaving | Commits the session first; unresolved curve previews prevent commitment |
| Starting playback | Pauses tracking and retains the session, identity, templates, and pending points |
| Saving or performing another edit requiring commitment | Commits Tracking first; curve previews require `Apply / Discard` first |
| `Finish` | Commits the entire session, retains in-memory templates for the current video and target ID, and unlocks identity controls |
| `Cancel` | Discards the pending session, retains in-memory templates for the current video and target ID, and restores the pre-session selection |

Use `Finish` or `Cancel` explicitly when deciding whether to retain or discard a segment; do not rely on indirect panel-switching behavior. Recovery snapshots and normal SQLite saving are different mechanisms; waiting for a recovery snapshot does not replace saving results.

### 8.5.4 State Button

| Button text | Current meaning | Clicking again |
| --- | --- | --- |
| `Start` | No templates; manual marking has not started or is paused | Starts manual marking |
| `Pause` | Manual marking or Auto is running; the button is selected | Pauses the current operating mode |
| `Run Auto` | Templates are available and ready to run | Continues automatic matching from the current tracking starting point |
| `Resume` | Templates are available; Auto is waiting after a pause or manual intervention | Continues from the current corrected position |

Button text indicates the operating state, not whether data has been saved. Pending results remain present while paused.

Tracking session preparation, template sampling, weight calculation, frame-by-frame matching, Edge/YOLO Assist, and trajectory preview calculations share the loading progress bar at the lower right of the window; the corresponding indication ends when a task is canceled, fails, or is superseded. This bar indicates ongoing work, not confidence or a completion percentage. Tracking status text continues to display failure reasons and pending counts.

## 8.6 Manual Marking and Automatic Tracking Takeover

### 8.6.1 Output Box Dimensions

`Fixed box` uses Box W/H as the fixed reference width and height of the output box; these can be adjusted directly during manual marking or while Auto is running/paused. The next accepted result uses the latest values, and an uncommitted box in the current frame is updated immediately. When a new template is set, Box W/H is initialized from that template's dimensions; subsequent recognition results do not overwrite the input values. When Rotate is recognized, the output box uses the enclosing rectangle of this fixed reference size after rotation, without accumulating the previous rotated width and height. Scale can still be used for appearance matching but does not scale Fixed box output dimensions. Assist may correct position while retaining these fixed dimensions in this mode.

For manual points, `Previous box` uses the dimensions of the most recent box already passed in the tracking direction, falling back to Box W/H if none is found; Auto uses the dimensions of the matched template and pose. Adjusting output dimensions does not change template images or search regions; Template area/Search area remain independent settings.

### 8.6.2 Auto next and Direction

When `Auto next` is enabled, completing a manually specified position advances one frame in the direction determined by `Reverse`. When disabled, the current frame remains displayed for repeated correction; Finish or right-click only commits the session and cancels unaccepted tracking requests, without advancing an extra frame.

During a manual retry after a low-score failure, enabled Auto next requests the next frame whether the retry succeeds or fails, except at the video boundaries. If the retry still fails, the next frame remains paused; if that frame contains the same ID and overwriting has not been allowed, the corresponding conflict pause remains and overwrite confirmation is not bypassed.

After a manual point automatically advances the frame, if the displayed frame has no new point and is adjacent to the predictor state, Resume processes the current frame first to avoid skipping it.

### 8.6.3 Temporary Takeover with Alt

Alt must be combined with a left-click inside the video. Pressing Alt alone does not enter marking mode, switch function tabs, or generate a box following the cursor.

| State before takeover | Alt + left-click | Releasing Alt |
| --- | --- | --- |
| No Tracking session | Starts a continuous manual session and immediately corrects the clicked frame | Retains manual marking mode, identity, and pending points |
| Existing manual session | Corrects the current frame within the original session | Retains the original session without committing the segment |
| Auto running | Invalidates in-flight results and takes over manually, retaining templates and existing points | Resumes Auto if no unresolved failure exists; otherwise remains paused |
| Auto paused, including low-score pauses | Corrects within the original session and retries as applicable | Resumes after manual position verification passes in two consecutive frames; otherwise stays paused, or `Resume` can be pressed explicitly |
| Camera Anchor session | Pauses and prompts the use of `Correct` | Does not write the click as an object trajectory |
| Active Trajectory preview | Requires the preview to be resolved first | Object manual takeover is available only after `Apply / Discard` |

Manual takeover of running Auto prioritizes the current template box dimensions rather than shared Box W/H or adjacent old box dimensions; purely manual sessions still generate initial boxes according to Fixed box/Previous box settings. Manual correction updates the recognition center and motion prediction starting point, preventing continued movement along the previous incorrect prediction.

If Auto next decoding or a manual retry is still processing when Alt is released, resumption waits for that operation to finish. Losing window focus ends temporary takeover but does not automatically resume Auto. Dragging the progress bar, seeking frame by frame, and clicking Play only pause tracking; they do not invoke Finish or delete templates or pending points.

Once manual marking mode is active, holding Ctrl + Alt continuously specifies the target at the mouse position within the video and advances to the next frame, without individual clicks. The submission rate does not exceed the bottom Speed setting, and direction follows Reverse; releasing either key immediately pauses continuous specification while retaining the session. Pressing this combination before entering manual marking mode does not start adding points. Image clicks during manual marking, automatic tracking, and Change position Continuous do not trigger trajectory point selection or ordinary box selection.

Manual mode displays a green dashed box following the cursor, with dimensions determined by the current session's manual box rules; Auto takeover uses template dimensions. The pending box in the current frame is also green and dashed, with two diagonals of equal thickness identifying the center; changing frames does not leave the previous frame's pending box displayed.

Pressing Esc during temporary Alt takeover withdraws only changes made during that takeover; previously pending trajectories are retained. If there was no existing session, Esc discards this temporary session. In an ordinary, non-temporary session, Esc executes Cancel.

### 8.6.4 Manual Correction and Retry in a Failed Frame

On a low-score pause, the image displays the candidate template box and search box from that attempt. The candidate box indicates only the position attempted by the algorithm, not that recognition passed in that frame.

After a position is manually specified, the program records the manual point first, retains the template library, and retries the same frame. Verification uses the automatic prediction state retained before the click, without first resetting the prediction center to the clicked position; subsequent tracking still corrects its prediction starting point using the manual point. A retry candidate must satisfy:

1. Score reaches its threshold.
2. Margin reaches its threshold.
3. The horizontal difference between the final candidate center and manual center does not exceed `max(3 px, manual box width / 2)`.
4. The vertical difference does not exceed `max(3 px, manual box height / 2)`.

The manually specified position is retained regardless of whether verification passes. On success, candidate scores and recognition positions are recorded within the original manual operation's local undo step; no additional mark is created.

**Example:** For a 10 × 8 px manual box, the permitted center differences are 5 px horizontally and 4 px vertically. A candidate with a high score but a horizontal distance of 20 px is not accepted as the manually corrected target, preventing a jump to a neighboring individual after the target is clicked.

Auto resumes after these conditions pass in two consecutive frames along the current tracking direction; repeated clicks in the same frame do not accumulate, and frame jumps, low scores, or excessively distant candidates interrupt consecutive confirmation. Manual mode remains active after the first confirmation; Auto next advances according to its existing setting. If the second confirmation occurs during Alt takeover, resumption waits until Alt is released and any in-flight frame change is complete; Mouse guided still requires a guiding position. Explicitly pressing Resume continues the existing workflow for manually confirming candidates, without waiting for two verifications.

### 8.6.5 Manual Marking versus Adding Templates

An ordinary manual left-click or Alt + left-click only specifies a position and retains existing templates without adding an appearance sample. To adapt automatic matching to a new appearance, use `Add Template` or Alt + Shift + left-click.

## 8.7 Template Creation and Library Management

### 8.7.1 Template Creation Actions

`Add Template` enters template selection mode, and the next click in the video immediately captures a template; this frame also receives a pending box with source `manual_box`. Releasing the mouse after adjusting `Template area` also captures a new template from the current frame and updates its pending box.

Alt + Shift + left-click performs the same sampling in the video and switches to `Tracking → Track Motion`. Pressing Alt + Shift alone or clicking outside the video does not enter template selection. After creation, `Run Auto` must be clicked manually; the key combination does not start continuous recognition by itself.

There is no fixed prerequisite template count: one valid template is sufficient to run. Templates from different frames are added to the library; resampling the same frame replaces that source frame's template rather than retaining multiple templates from one frame.

### 8.7.2 Sampling Principles

A template should contain distinguishable target texture or contours that remain consistent across subsequent frames. A template that is too small may lack information distinguishing different positions; one that is too large may introduce substantial changing background into the similarity calculation.

| Image condition | Sampling approach | Expected effect |
| --- | --- | --- |
| Stable head or thorax texture on the target | Sample that feature and set Mark offset if necessary | Separates the recognized feature from the final annotation center |
| Significant lighting change | Add a template under the new lighting | Competes using the new appearance without relying on frame-by-frame evolution of old samples |
| Background changes substantially with position | Reduce the background proportion and add representative samples | Reduces the likelihood of background texture dominating scores |
| Occlusion or severe blur | Sample clear frames and correct occluded segments manually | Avoids treating an occluder as the target's new appearance |
| Nearly uniform-color region | Enlarge to include structured features or choose another position | Adds localization information |

Templates with extremely low luminance variation lack useful localization evidence and may be stored in the library without producing valid match candidates. The presence of a template does not mean it is suitable for the current frame.

### 8.7.3 Multiple-Template Selection

Each enabled template evaluates candidates independently, and the program selects the best match among available results. Templates are not first averaged into a single image, nor must every template pass simultaneously.

Multiple templates matching the same spatial position do not automatically count as multiple competing targets; high-scoring results at different positions can reduce Margin. Adding templates covers different appearances but also increases computation and opportunities for false candidates.

**Example:** Template A scores highly for a target in bright conditions, while template B scores highly in dark conditions. B can win when the target enters a dark region, while A retains its sample; there is no need to change the “current ID” manually. If A simultaneously obtains a score on another insect close to B's score, Margin may be insufficient and cause a pause; inspect the templates or reduce the search region.

### 8.7.4 Preview, Enabling, and Deletion

Clicking a list row changes only the preview; it does not restrict use to that template and does not necessarily change the active template. The preview shows the original captured image rather than the evolved image after each Evolution step.

To operate on a template's source position and offset, double-click its list row: the program pauses, selects that template, and seeks to its source frame. To restrict matching to that template, also use the list checkboxes or `Use selected only`.

Template checkboxes, enable operations, and deletion operations pause Auto. Auto cannot run with all templates disabled; at least one must be enabled. Deleting all templates retains existing annotations, and the state button returns to the `Start` used for manual mode.

Disabling is appropriate for temporarily excluding samples from old lighting or poses; deletion is appropriate for samples no longer needed. Inspect the preview before deleting. Local Ctrl + Z applies to point operations and is not an undo mechanism for template library management.

**Management example:** The library contains F100, F500, and F900. Select only F500 and press Use selected only to use F500 alone in subsequent matching; press Enable all to restore all three. Remove selected removes the selected sample from the library without deleting the position record in frame 500. Confirm that a row is selected before using Use selected only; with no selection, it disables all templates.

### 8.7.5 Template Lifecycle

Templates are retained in memory separately for each target ID within the current video data session. Pausing, ordinary navigation, manual takeover, switching Tracking tabs, `Finish`, `Cancel`, and other actions ending a tracking session do not automatically clear the library; selecting the same ID again within that data session restores its templates. Changing videos, creating a new data session, or closing the application discards this cache; use `Remove selected` to delete templates explicitly.

An ordinary annotation SQLite file saves positions and related score fields, but not template images or the template library capable of continued evolution. After reopening results, capture templates again before automatic tracking.

## 8.8 Template Region, Search Region, and Search Modes

### 8.8.1 Meaning of the Two Regions

| Region | Color | Definition | Effect of changes |
| --- | --- | --- | --- |
| `Template area` | Cyan | Image region describing the target appearance | Recaptures the current frame image and affects the reference dimensions of automatic output boxes |
| `Search area` | Yellow | Local region in which the template may be sought in this frame | Changes searchable positions and computation without modifying the template image |

Both tools use XYWH: drag inside the box to move it and drag handles to resize it. Starting Auto exits region adjustment mode. Each time a template is reset, the search center offset relative to the template center is recorded in original video pixels; moving Search area moves the template reference box with that offset rather than forcing concentric boxes. Independently moving or resizing Template area and releasing resamples it and records the new relative position. Changing the search region does not rewrite existing annotation points or template pixels; actual accepted positions still come from matching results.

The search region must accommodate the entire candidate template. Image edges limit the effective search region; with rotation or scaling enabled, the transformed template's enclosing extent must also fit. An overly small search region may miss the target; an overly large one increases candidates and processing time.

**Example:** A target may move 20 px horizontally in one frame, and the template is 19 px wide. A search box only 20 px wide cannot provide a center movement range of 20 px on either side; the template's own width must also be included.

### 8.8.2 Search Center

| Search mode | Center basis | Applicable conditions | Boundary behavior |
| --- | --- | --- | --- |
| `Predict` | Constant-velocity Kalman prediction from accepted positions | Movement has some continuity | Sharp turns, stops, or prolonged rejection may cause deviation; enlarge the search region or reposition manually |
| `Follow` | Most recently accepted recognition position | Small movements with unstable speed | Does not extrapolate velocity; the target must remain within the region centered on the old position |
| `Fixed` | Fixed absolute center | Fixed activity region or nearly stationary target | Does not automatically follow a target leaving the region |
| `Cursor` | Mouse position in the video | The operator knows the target region | Linked to Mouse guided; hold the left mouse button to guide |

Predict, Follow, and Cursor obtain a reference center and then apply the search offset recorded during the latest template sampling; Fixed uses a fixed absolute center. Manual correction, pause/resume, and reverse continuation retain the offset between boxes without resetting it. During mouse guidance, the template reference box and search box move by the same displacement. For example, if the search center is 20 px right and 5 px above the template center, that relationship remains after movement. Changing the search region invalidates previous failed candidates; Resume performs recognition again instead of directly confirming the old position.

Motion prediction uses the recognized feature center. With Mark offset set, the final annotation center may differ; manual specification gives the final target position, and the program derives the recognition center from the offset.

### 8.8.3 Mouse guided Procedure

1. Create a usable template.
2. Enable `Mouse guided`; Search changes to `Cursor`.
3. Exit explicit editing tools such as Template area, Search area, or Mark offset.
4. Place the cursor near the target and hold the left mouse button.
5. Move the cursor as the image changes, keeping the target inside the yellow search region.
6. Release the left button or move outside the video to pause tracking immediately; hold it again to continue.

During normal Mouse guided execution, the mouse only guides the search region; each mouse position is not directly used as an annotation center, and Score and Margin still determine acceptance. After a pause caused by a low score or no candidate, an ordinary left-click directly specifies a manual position without Alt; explicit region editing tools still take priority for box dragging. After manual corrections pass verification in two consecutive frames, tracking waits for the left button to be held again for guidance and pauses on release; an unmarked frame already reached by Auto next is processed first. Resume or Space with the pointer inside the video also returns to automatic guidance. Alt + left-click remains available for explicit manual takeover.

Disabling Mouse guided changes Cursor search back to Predict; explicitly choosing Cursor in Search also enables Mouse guided. Clicking Run Auto without holding the left button displays a prompt waiting for mouse guidance.

### 8.8.4 Reverse Tracking

With `Reverse` selected, tracking runs from the current frame toward frame 1. Changing direction pauses and invalidates in-flight results while retaining templates and pending points. Auto next, Previous box, and existing-point conflict checks use the same direction.

**Example:** The target is clear in frame 600, while frames 500–599 are unannotated. Create a template at frame 600, select Reverse, and fill backward to frame 500. Tracking stops automatically at frame 1; Finish is still required to commit. Rate displays a positive speed multiplier, not a negative value for reverse direction.

## 8.9 Match Scores and Stop Conditions

### 8.9.1 Score Components

The program first proposes a limited number of spatial candidates according to the Advanced Candidates strategy, then calculates the following five features and combines them using Weights. Combined uses the average luminance and gradient response; Multi-channel cycles through enabled luminance, gradient, coarse average-color filtering, and edge responses, suppressing nearby duplicate peaks across channels. Color histograms are used for detailed candidate scoring; coarse color candidate filtering still uses average color. The highest-scoring position is the best candidate.

| Feature | Principle | Typical effect of changing its weight |
| --- | --- | --- |
| Luma | Normalized correlation of grayscale patterns; negative correlation is treated as 0 | A higher weight emphasizes alignment of light and dark texture |
| Gradient | Normalized correlation of gradient magnitude patterns | A higher weight emphasizes texture changes and intensity structures near contours |
| Color | Mean compares average BGR differences; HSV histogram compares normalized hue/saturation distributions, using 1 minus the Bhattacharyya distance as similarity | Histograms may distinguish different distributions with similar average colors; similar color does not establish the same individual |
| Edge | Compares the intersection and union of edge pixels | A higher weight emphasizes edge overlap; blur may weaken this feature |
| Motion | Gives a higher prior value to candidates nearer the current search center | Helps suppress distant competing positions; an incorrect prediction may also favor an incorrect region |

In Fixed mode, the five inputs are normalized as relative weights and need not sum to exactly 100. A feature set to 0 does not contribute to the final weighted score; setting all features to 0 removes the basis for valid scoring and should be avoided. Calibrated/Adaptive displays the current effective percentages, while fixed input proportions are retained separately. Combined always proposes candidates using luminance and gradient; disabled appearance channels in Multi-channel provide no additional candidates. Both strategies are limited by Budget and do not calculate all five detailed features at every position in the search region. Motion remains a positional prior; local optical flow is not currently calculated.

**Weight example:** Increasing Gradient and decreasing Color may favor candidates with similar contour structure but slightly changed overall color; increasing Color may reduce the influence of background candidates with different average colors, while nearby insects of the same color may still compete. Increasing Motion favors positions near the search center and may be detrimental when the target turns sharply away from the predicted center. Compare one weight at a time on the same frame; increasing a particular weight does not guarantee higher accuracy in all images.

Score is the program's weighted matching metric, not the probability that the target identity is correct, and not YOLO confidence. The same value may have different reliability with different templates, search regions, or weights.

### 8.9.2 Margin Definition

Let the best candidate score be `S₁` and the competing score at another spatial position be `S₂`:

$$
\mathrm{Margin} = S_1 - S_2
$$

Nearby pixels belonging to the same response peak, or different templates or poses at the same position, are not directly counted as another target in the competing score. Margin indicates whether the best position is clearly better than other positions.

Although displayed as a percentage, Margin is the difference between two scores. For example, 85% − 81% = 4 percentage points; a Margin threshold of 6% means a difference of at least 0.06, not the difference divided by 85%.

### 8.9.3 Acceptance Criteria and Colors

A matched position must satisfy both:

`Score ≥ Score threshold` and `Margin ≥ Margin threshold`.

Equality passes the threshold. Score and Margin are displayed in green or red according to their respective criteria.

| Best score | Competing score | Margin | Result at thresholds 72% / 6% | Reason |
| --- | --- | --- | --- | --- |
| 85% | 74% | 11% | Accept | Both criteria pass |
| 85% | 81% | 4% | Reject | High appearance score, but considerable ambiguity between different positions |
| 68% | 40% | 28% | Reject | Relatively distinctive position, but insufficient appearance similarity |
| 72% | 66% | 6% | Accept | Both criteria exactly reach their thresholds |

Displayed values describe the most recent matching attempt. Jumping to another frame after pausing, ordinary manual marking, or adjusting only the display does not automatically rescore the current frame; retained green values do not mean recognition has passed again in the current frame.

### 8.9.4 Stop due to

| Stop policy | Pause condition | Are automatic points written when acceptance criteria fail? |
| --- | --- | --- |
| `Poor match` | No candidate, or either Score or Margin is below threshold | No |
| `No match` | No candidate, or the best Score is no greater than 20% | No; scores above 20% but below acceptance thresholds allow attempts in subsequent frames |
| `Never` | Does not pause for ordinary match rejection | No; attempts continue in subsequent frames |

The stop policy only determines whether execution continues after rejection; it does not change acceptance criteria. `Never` does not write every frame's highest-scoring position, nor does it continue past the end of the video, decoding errors, or existing-point conflicts.

**Example:** With Score threshold 72% and Margin threshold 6%, a frame yields Score 65% and Margin 10%. Poor match pauses; No match and Never may try the next frame, but no automatic annotation is added in this frame.

### 8.9.5 Threshold Adjustment Order

For repeated rejections, check identity, the displayed frame, template content, search coverage, and candidate positions in that order before deciding to adjust thresholds. Simply lowering thresholds may admit incorrect targets.

- Low Score, high Margin: check appearance changes, template dimensions, or blur first.
- High Score, low Margin: check similar targets, background texture, an overly large search region, or obsolete templates first.
- Both low: reposition manually and inspect templates first.
- High Score and Margin with the wrong target: image similarity is insufficient to confirm identity; add manual constraints or choose another recognition feature.

### 8.9.6 Fixed, Calibrated, and Adaptive

| Mode | Weight source | Subsequent changes |
| --- | --- | --- |
| Fixed | Five relative proportions entered by the user | Changes only when the user modifies inputs |
| Calibrated | A shared weight set calibrated from existing target and background component scores when templates are set | Remains fixed during tracking; may be aggregated again after adding templates, recalibration, or changing the enabled template set |
| Adaptive | Starts from the same shared calibration | Updates slowly and infrequently using reliable matches only; freezes on low scores or manual takeover |

Calibrated is the default. To modify baseline proportions or disable a channel, switch to Fixed, adjust inputs, then select the desired mode. Returning to Fixed restores retained input proportions instead of repeatedly using automatic results as the next input. Mode and fixed proportions are saved in settings.ini; templates, background regions, and online weight state belong to the current tracking session.

Calibration compares Luma, Gradient, Color, and Edge component scores at the known correct template center against available background candidates. Each channel's discriminative power is estimated from its target component score minus background component score, weighted using a nonnegative floor and fixed baseline proportions, then normalized. Explicitly zeroed appearance channels remain disabled; when several channels are enabled, a single channel is prevented from occupying an excessive proportion. Valid statistics from multiple enabled templates are robustly aggregated into one set of appearance weights, without immediately switching proportions whenever the winning template changes.

Motion is a search-center prior rather than an image difference between template and background; shared calibration modes limit it to a weak independent proportion, usually no more than 10%. If all appearance channels are disabled, valid appearance calibration is impossible; restore at least one reliable appearance cue first.

This function only determines which weights to use. The existing luminance/gradient candidate generation, Color mean difference, Edge overlap, and Motion distance scoring methods remain the same; it does not make Color/Edge search independently outside structural candidates. Limited evidence in the calibration status means evidence is insufficient and the previous usable weights are retained; it does not establish that those proportions are optimal.

### 8.9.7 Background Selection and Recalibration Procedure

1. Set a template in a frame where the target can be confirmed, and inspect the five effective percentages and calibration status.
2. No additional selection is needed when automatic surrounding background is sufficient. For specific neighboring interference, click Background and drag a region containing the interference but not the target.
3. The region must accommodate at least the template; an undersized background region cannot provide a complete comparison window, so the program falls back to available surrounding background evidence.
4. Recalibrate when the current target position is confirmed; if you have jumped to another unlocalized frame, correct manually or set a template again before pressing Recalculate.
5. Esc or right-clicking the canvas cancels an unfinished background selection without committing the tracking session. Right-click the Background button to clear the selected background region.
6. Inspect candidate positions, Score, and Margin over the same segment before continuing Auto; calibration itself does not correct existing trajectory points.

Background saves region coordinates and reads that region in the calibration frame; it does not continuously update in every tracked frame. Later Recalculate operations or new templates read the image at those coordinates again in the corresponding calibration frame; it is neither a permanently frozen background screenshot nor a full-scene background model. Reliable-match updates in Adaptive remain independent of frame-by-frame sampling of that region.

The background rectangle uses original video coordinates and is displayed through the existing coordinate mapping under Camera stabilization and Expanded motion canvas. It provides weight evidence only: it is not an annotation box, does not constrain actual search positions, and does not change Search area. Background comparison uses luminance, gradient, color, and edge responses from a complete template window, not just average color samples. Even for uniform backgrounds, region width and height must each be at least those of the participating templates; when template dimensions differ, the region must accommodate the largest template. A compact representative region is sufficient and need not cover the whole image; undersized regions fall back to surrounding background evidence. Fixed mode retains manual weights without redistributing them from this region.

**Example:** The target and a wooden board have similar average colors but distinct texture and edges. Calibration may reduce the relative Color proportion and increase distinguishing structural cues; if a neighboring insect is also structurally very similar, Margin may remain insufficient. Reduce the search region or reposition manually rather than treating weight adjustment as an identity guarantee.

### 8.9.8 Adaptive Reliability Criteria and Freezing

Adaptive observes only positions that already pass acceptance criteria with additional Score/Margin headroom. Large jumps away from the predicted center, failures, and near-threshold results are not used for learning. After manual correction, reliable observations are accumulated again with an initial freeze over several observations, preventing old predictions or incorrect candidates from immediately determining new weights.

Weights update every 20 reliable observations, blending target weights into existing weights by only 5%, effective from subsequent matches. This update rate is independent of Evolution and Tether: those two control template image evolution and pullback toward the original template, respectively, and do not replace the weight learning rate. Canceled, expired, or unaccepted Worker results do not change the accepted online state.

The status line distinguishes calibration, evidence collection, completed updates, and freeze reasons. Compare modes using actual target positions, switches to other targets, and manual intervention counts; an increase in Score does not imply more accurate tracking.

## 8.10 Template Evolution and Original Template Constraints

### 8.10.1 Evolution and Tether

Each template contains its original sampled image and an evolved image used for subsequent matching. Only the winning template changes when the position is accepted and appearance updates are permitted; other templates do not change with that frame. Rejected candidates do not evolve templates. With Guard template updates disabled, every accepted position permits an update; when enabled, learning thresholds and consecutive reliability counts must also pass, as detailed in 8.3.6.

Let `T₀` be the original template, `T` the evolved template used for this match, `P` the image at the accepted position, `E = Evolution / 100`, and `H = Tether / 100`:

$$
\begin{aligned}
\text{Evolve first:}\quad T' &= (1-E) \times T + E \times P \\
\text{Then constrain:}\quad T_{\mathrm{next}} &= (1-H) \times T' + H \times T_0
\end{aligned}
$$

Images are blended pixel by pixel, with rounding for integer images. When rotation or scaling is enabled, the accepted image is first inverse-transformed to the template reference coordinates, then blended.

| Setting | Behavior | Interpretation |
| --- | --- | --- |
| Evolution = 0, Tether = 0 | Evolved image remains unchanged | Entirely fixed appearance |
| Evolution = 0, Tether > 0 | No new matched image is introduced; existing evolved results gradually return to the original image | Does not freeze a previously evolved template |
| Higher Evolution | Absorbs new appearances faster | Follows changes but also absorbs a single error more readily |
| Higher Tether | Retains stronger influence from the original template | Suppresses drift but may hinder adaptation to substantial lighting changes |
| Tether = 100 | Restores the original template after each update | Subsequent matching uses the original appearance |
| Evolution = 100, Tether = 0 | Replaces the evolved template with the latest accepted image | Responds quickly to continuous change and is sensitive to incorrect acceptance |

**Example:** With Evolution = 5% and Tether = 10%, the update contains approximately 85.5% old evolved template, 4.5% current matched image, and 10% original template. The 5% does not mean averaging previous and current frame positions, and is not trajectory coordinate smoothing strength.

### 8.10.2 Evolution and Multiple Templates

Evolution can adapt to gradual luminance changes; add representative templates for substantially new poses, occlusion relationships, or backgrounds. The library holds independent appearance samples, and Tether constrains each toward its own original image without mixing different templates.

When returning to a reliable position along the original tracking direction and running again, the program can restore the library's original appearances and rebuild the prediction starting point from the current reliable point, avoiding reuse of the evolved state beyond an erroneous segment. This does not restore deleted templates or replace overwriting/deleting incorrect annotations.

## 8.11 Rotation, Scaling, and Mark Offset

### 8.11.1 Rotate and Scale

Enabling `Rotate ±°` searches positive and negative rotations relative to the template reference appearance; enabling `Scale ±%` searches scales relative to the template reference dimensions. They can be enabled separately or together.

**Example:** Rotate ±30° and Scale ±20% search approximately −30° to +30° and 0.8 to 1.2 times the reference appearance. The next frame still searches relative to that template reference, rather than multiplying 1.2 cumulatively frame by frame.

The algorithm uses coarse-to-fine discrete pose candidates: coarse angular spacing is no more than approximately 10°, and coarse scale spacing no more than approximately 0.1, followed by refinement near the best pose. Output angles and scales are template matching approximations, not precise continuous pose measurements.

Invalid padding created by transformation is excluded from scoring. Pose candidates too large for the search box are skipped. Larger ranges and more simultaneously enabled variations increase computation.

Changing toggles or ranges pauses Auto. Adjust Search area before continuing. Replacing or creating a template redefines that sample's angular zero and reference dimensions.

### 8.11.2 Output Boxes and Pose

Annotations still use axis-aligned `x/y/w/h`. A rotated template is represented by its axis-aligned enclosing box, so the box may be wider than the target itself; this does not mean a rotated rectangle is saved. The corresponding match angle and scale are recorded separately as `match_rotation_deg` and `match_scale`.

Positive angles indicate counterclockwise appearance changes in the original image. This value is relative to the template, not an absolute body orientation after stabilization, and does not remove effects of actual deformation, occlusion, or camera projection.

### 8.11.3 Meaning of Mark offset

Recognition and annotation centers may differ. A template can cover a clear feature such as the head or a textured patch, while the final position lies at the body center or another agreed point.

Procedure:

1. Complete template sampling or accept a match in the current frame.
2. Click `Mark offset`.
3. Click the desired final recorded target center in the video.
4. Inspect the final box position, then run Auto.

If the displayed frame is not the frame sampled or recognized by the engine, the program requires a template to be set in that frame first, rather than calculating an offset from an unrelated old recognition position.

Offset X/Y can also be entered in Weights. Values apply to the active template; double-click the desired sample in Templates before modification if needed. Each template stores its own offset; changing one does not automatically rewrite all templates.

### 8.11.4 Offset Transformation

Let the template reference offset be `(dx, dy)`, recognized scale `s`, angle `θ`, and recognition center `(xr, yr)`. With the original image y-axis pointing downward:

$$
\begin{aligned}
\Delta x &= s \times (\cos\theta \times \mathrm{dx} + \sin\theta \times \mathrm{dy}) \\
\Delta y &= s \times (-\sin\theta \times \mathrm{dx} + \cos\theta \times \mathrm{dy}) \\
\text{Annotation center} &= (\mathrm{xr} + \Delta x,\; \mathrm{yr} + \Delta y)
\end{aligned}
$$

**Example:** The recognized feature center is `(100, 80)`, and the final body center is 12 px below it, giving offset `(0, 12)`. With no rotation and scale 1, the recorded position is approximately `(100, 92)`; at scale 1.2, the offset becomes 14.4 px; after 90° counterclockwise rotation, this reference downward offset points toward the right of the original image.

Changing an offset affects subsequent results from that template; when the engine position agrees with the current frame, it also updates the current pending box. It does not translate the entire generated trajectory. Use Trajectory Transform for whole-segment translation.

The offset changes the box center without independently defining final box dimensions. The initial Auto box still comes from the matched template's enclosing extent; use suitable template dimensions, Assist, or other box editing operations for a closer body fit.

## 8.12 Box Refinement with Assist

### 8.12.1 Shared Behavior

Assist is available for manual marks and accepted automatic marks. A position immediately creates an initial box, then refinement is attempted in the background; if refinement fails, the initial box is retained rather than deleting the point.

All refinement results must pass local boundary checks:

- Keep the initially specified position inside the box; for a manual click at an image edge, also check the actual clicked position.
- Limit horizontal center displacement to `max(2 px, initial width / 2)` and vertical displacement to `max(2 px, initial height / 2)`.
- Limit width to `max(8 px, initial width × 2)` and height to `max(8 px, initial height × 2)`.
- Require valid coordinates and positive dimensions that can be constrained within video boundaries.

**Example:** For an initial 10 × 8 px box, the permitted size limits are 20 × 16 px and the axis-wise center displacement limits are 5 px and 4 px. A nearby 60 × 40 px region detected by the model does not replace the initial box.

### 8.12.2 None

No image refinement is performed; the initial manual or template-matched box is retained. This suits tasks with fixed box definitions, blurred targets, or strict requirements on marking extent.

### 8.12.3 Edge

Analyzes similarly colored areas near the initial center and uses edge barriers to find a connected region containing the center, generating a candidate box from its bounds. The initial box is retained if the region is too small, too large, unreliable, or fails shared boundary checks.

Edge does not recognize semantic classes such as `bee` or `hornet`. Results may be rejected when target and background colors are similar, texture is broken, or edges are blurred; retaining the original box does not require repeated clicks.

### 8.12.4 YOLO

Uses the model, Device, Half, and other settings configured in Detection to perform inference on a local ROI through the external DetectionWorker. The model is loaded on demand and reused; full-video Detection does not need to be completed first.

Procedure:

1. Before starting a Tracking session, select a valid model and execution device in Detection.
2. Confirm that the target class agrees with the model class name; name comparison is case-insensitive.
3. Return to Tracking and set `Assist` to `YOLO`.
4. Mark manually or run Auto. Observe the initial box and subsequent refinement result.
5. If status messages report a missing model, missing class, device error, or inference failure, correct the configuration; the existing initial box is retained.

Local candidates are first restricted to the same class; among candidates containing the initial point, those with nearer centers are preferred. The final result must still pass shared boundary checks. ROI inference uses its own local configuration; do not assume that every full-video Detection parameter applies individually to Assist. The template matching Score threshold also does not control YOLO confidence.

YOLO supports devices available in the runtime; auto selects an available device in the detection environment and can use a GPU when CUDA is available. Half precision applies only on supported devices. Automatic template tracking itself still uses CPU/OpenCV; enabling GPU YOLO Assist does not turn template matching into a GPU algorithm.

### 8.12.5 Asynchrony and Result Validity

Refinement does not wait for the next user click and does not guarantee YOLO processing of every rapidly generated point. The queue retains one in-flight request and the latest waiting request; older waiting work may be replaced to prevent accumulating latency.

After remarking the same frame, pausing, navigating, changing Assist, Finish, or Cancel, invalid results cannot overwrite new positions or ended sessions. Accepted refinements are merged into the original point operation's local undo record without adding a separate point operation.

ROI assistance is temporarily unavailable during full-video Detection, but manual initial boxes can still be recorded; the assistance model can be prepared again after full-video detection ends. After changing the model, device, or precision, the next assistance request prepares a worker using the new configuration.

The external standalone DetectionWorker must support the ROI service interface. If an older standalone worker does not, the status line reports the issue and retains the initial box; this does not imply failure of the original manual mark.

## 8.13 Overwriting, Deletion, Undo, and Redo

### 8.13.1 Same Frame and Same ID

After a frame is edited manually or automatically, one final position for that ID remains in that frame. Repeated clicks update its position rather than adding multiple boxes for the ID. If the original data contains duplicate rows for the same ID, editing that frame consolidates them into the current position; starting a session does not globally deduplicate unedited frames.

Other IDs are not replaced. Overlap with another insect does not automatically merge identities. Undo can restore the original records in that frame, including pre-existing duplicate rows.

### 8.13.2 Two Levels of Overwrite Permission

With Overwrite cleared, Auto pauses before an existing point with the same ID in the processing direction, including both committed and session-pending points. Clicking Run Auto/Resume again asks whether overwriting is permitted for this continuous run. Choosing Yes allows the run to pass through existing positions; pausing ends this temporary permission.

With Overwrite selected, Auto may recognize again and replace existing points directly without prompting for that conflict. Overwriting performs recognition again using the current templates and prediction; it does not jump to and reuse the original incorrect coordinates.

Direct manual specification is an explicit single-frame correction and is not subject to Auto overwrite confirmation. Overwrite neither reassigns IDs nor accepts low-scoring results.

**Example:** Frames 2000–2200 have switched to a neighboring honeybee. Return to a reliable position at frame 1999, correct the starting point manually and capture templates again if necessary, then enable Overwrite and retrack. Accepted new results replace old points frame by frame. If a new match is rejected in a frame, the old erroneous point is not automatically cleared; use Delete to remove an incorrect interval.

### 8.13.3 Single-Point Deletion

During an active Tracking session, press Delete with image focus to delete the current ID's position in the current frame. This can delete a pending point or a point that existed before the session; other frames and IDs remain unchanged. Pressing Delete in an empty frame does not create a deletion record.

When a text field has focus, Delete retains its text editing function. Delete in a Trajectory Edit preview removes selected control anchors, which differs from Tracking single-frame point deletion.

### 8.13.4 Range Deletion

1. Click `Delete` in `Track Motion`.
2. Enter frames or intervals in `Frames` in the `Delete track range` window, for example `100-140, 200, 260-275`.
3. Drag the video progress bar to check start and end positions while inspecting the deletion preview bands.
4. Click `Delete` in the window to confirm.
5. Inspect the result; use Ctrl + Z to undo this range deletion if necessary.
6. Commit it with the session's other point changes using `Finish`.

Ranges include both endpoints and are limited to valid video frames; a blank field uses the current frame. `140-100` is treated as 100–140, `-140` means the first frame through 140, and `200-` means 200 through the last frame. Separate multiple ranges with ASCII commas. Invalid ranges cannot be confirmed. The window is nonmodal and allows continued navigation. Closing it without confirmation performs no deletion; the entered Tracking session still requires Finish or Cancel as appropriate.

One range deletion is undone as one local operation. It deletes records for the current target, not video images or the template library; these frames can be recognized again later.

### 8.13.5 Undo Before and After Commitment

| Stage | Effect of Ctrl + Z / Ctrl + Y | Exclusions |
| --- | --- | --- |
| Uncommitted Tracking | Undoes/redoes point operations individually; range deletion is one step; automatic points are usually one step per frame | Does not undo template enabling/deletion or other library management, or restore all UI parameters |
| Temporary Alt takeover | Point operations remain in the local stack; Esc withdraws this takeover | Does not clear the pre-takeover session |
| Trajectory preview | Undoes/redoes a drag, redraw stroke, or preview modification | Not yet written to global History |
| After Finish | The whole Tracking session is one global History edit | No longer undoes that session frame by frame |
| After Trajectory Apply | The entire curve modification is one global History edit | Does not undo individual control handles |

Local undo records deltas for affected points instead of writing a complete History entry for every frame. Undoing a point operation pauses Auto and may seek to the affected frame; inspect the current starting point before continuing tracking.

`Pending` counts positions and deletions currently held for commitment in this session, not mouse clicks or undo steps. Repeated edits in the same frame add local operations but usually still count as only one pending position.

## 8.14 Image Marks, Trajectories, and Timeline

### 8.14.1 Current Frame Boxes and Candidate Boxes

An uncommitted annotation box in the current frame contains two crossing diagonals of the same color and thickness as its outline, forming `⊠`. Their intersection identifies the box center and distinguishes pending boxes from ordinary existing boxes.

Cyan Template area and yellow Search area support sampling, adjustment, and failure diagnosis. A candidate box displayed on a low score is not an accepted annotation box. After changing frames, rely on the current frame's state and pending box rather than inferring its result from the most recent score.

### 8.14.2 Show trail and Display

`Show trail` and `Display → Trail before` are two entry points for the same switch. The current Track ID remains selected, existing and pending points are displayed together, and Display settings determine frame range, All/Simple, line style, color, opacity, and width.

Trail before gradient trajectories show the portion before the current frame by frame number; Reverse does not automatically change this to the direction just traversed. Simple can display the entire available path. The pending Tracking trajectory layer uses Trail before configuration; use Simple to inspect the complete pending segment during reverse tracking. After commitment, Trail after configuration can also show the portion after the current frame.

Display colors, gradients, widths, and trajectory appearance processing do not change CSV coordinates. Only editing operations such as Trajectory Apply change data positions. Hiding a trail does not delete annotations.

### 8.14.3 Timeline Bands

| Band | Meaning | Display scope |
| --- | --- | --- |
| Yellow | Occurrence intervals of the selected ID | Uses the existing selected-ID display |
| Green | Pending positions added or replaced in this Tracking session | Tracking main panel, on the layer corresponding to Merge Target |
| Black | Range currently specified in the Delete window | Tracking main panel, on the layer corresponding to Merge Source |
| Red | Intersection of the deletion range with actual existing/pending points | Overlap layer of the Tracking deletion preview |
| Blue | Frame interval currently selected in Trajectory | `Edit → Trajectory`, on the layer corresponding to Target |
| Hover marker | Frame number of the trajectory point hovered in the image | Linked to trajectory hovering |

After Delete is confirmed, the range window closes and the black/red previews no longer indicate an operation awaiting confirmation. Green bands indicate pending results, not successful recognition in every traversed frame.

### 8.14.4 Shared Trajectory Point Picking

`Edit → Trajectory → Pick trail` is enabled by default and works across main panels; the corresponding trajectory must be visible.

Near a trajectory point, the cursor displays a ring 10 screen pixels in diameter using that ID's color, with adjacent `class ID (frame)` text such as `hornet 123 (2301)`. Text uses the trail color at the hovered position and follows Simple or gradient settings. The progress bar also marks that frame.

A click seeks only to the point corresponding to the current hover preview and belonging to a visible continuous trail, subject also to the Before/After or All time range under Display → Trajectory picking. Points outside the range with no hover preview, hidden points, and isolated points cannot be clicked. When multiple candidates lie within 12 logical pixels of the pointer, both hover and click prioritize the point closest in time to the current frame before comparing screen distance; to select another pass precisely, first move the progress bar near that time.

Holding Ctrl temporarily suppresses trajectory hover hints and picking to prevent unintended seeking to a trail frame; after Ctrl is released, suppression continues for 3 seconds before restoring the original settings. Pressing and releasing Ctrl again restarts the timer, without changing the Pick trail switch state.

Explicit box editing, scale control points, Camera Anchor, Tracking manual marking, and Trajectory previews have their own click purposes and are not overridden by ordinary Pick trail. Alt + left-click still marks manually, and Ctrl + left-click retains existing multiple-selection behavior.

## 8.15 Execution Speed and Rendering Settings

### 8.15.1 Speed and Rate

The bottom `Speed` control limits the actual displayed frame advancement rate of Auto and Mouse guided. For a nominal 25 FPS video, Speed = 1 advances at up to approximately 25 frames per second; Speed = 2 raises the limit to approximately 50 frames per second.

Rate displays a speed multiplier from actual frame progress over approximately the last 2 s and the nominal FPS. Text such as `0.99x (limit 1x)` is appended only when results actually wait for rate limiting; no limit is shown if recognition itself remains below the cap. Short-term Rate near startup, pauses, or seeking does not represent steady throughput.

When recognition is slower than the cap, execution continues frame by frame rather than skipping images to meet the playback multiplier. Frames with failed matches are still attempted if the stop policy permits continuation, but generate no valid automatic points.

### 8.15.2 Decode ahead and Match workers

Decode ahead decodes the next image while matching the current frame. It does not accept future results early or let template evolution bypass frame order. After a pause or manual correction, stale decoded images and matching results are invalidated.

Match workers evaluates multiple enabled templates in parallel. Independent template scoring can run concurrently, but predictor updates, winning template evolution, and frame-by-frame writing must follow tracking order. With only one template, increasing this value does not independently track multiple adjacent frames simultaneously.

For performance comparisons, use the same video segment, templates, search region, and pose settings, and test 1, 2, 4, or other worker counts separately. When Rate already reaches the Speed cap, the interface multiplier does not directly reveal additional computing capacity; also inspect `Decode wait` and `match` timings in the Rate hover information.

### 8.15.3 Performance Adjustment Order

1. Check whether Speed is already limiting execution.
2. Disable obsolete or irrelevant templates.
3. Reduce the search region while retaining sufficient motion coverage.
4. Enable rotation or scale searches only for actual appearance changes, and limit their ranges.
5. Compare actual timings with Decode ahead and Match workers.
6. Use suitable Trail before/after frame windows for long trajectories; enable the OpenGL gradient shader when needed.
7. Distinguish template matching, YOLO Assist, decoding, and rendering costs rather than judging bottlenecks solely by total CPU usage.

Reverse tracking usually requires more random seeking and may be slower than forward sequential decoding. Initial video indexing may also temporarily increase seek waits.

### 8.15.4 Overlay renderer and Gradient shader

Entry point: `Display → Overlay renderer → Gradient shader`.

A shader is a rendering program executed on a graphics device. Here it calculates gradient color, opacity, and line width from the temporal relationship between trajectory points and the current frame; it does not recognize targets.

| Rendering condition | Behavior |
| --- | --- |
| OpenGL with Gradient shader enabled and available | Playback, pending Tracking trails, and OpenGL video export share the gradient rendering path |
| Gradient shader disabled | Uses the existing trajectory rendering path |
| Qt raster | Uses Qt rendering without executing this OpenGL shader |
| wave line style | Supported directly by the OpenGL shader and by Qt/CPU paths; does not change trajectory coordinates |
| Shader compilation or configuration unavailable | Displays the fallback reason and continues with an existing rendering path |

Small sets of interactive elements such as Template/Search boxes, control handles, curve previews, and hover rings retain Qt rendering. Annotation boxes and trajectories use the existing Qt/OpenGL annotation backend. Enabling Gradient shader does not require CUDA or enable GPU template matching.

Trajectory color, opacity, and width during playback and export depend on the same display configuration. Preview backends are Auto, OpenGL, and Qt raster; export backends are Auto, OpenGL, and CPU. OpenGL export can use the shader, while CPU export does not. Exported trajectory graphics do not change the original annotation SQLite file.

Fallback after Gradient shader failure differs from handling an unavailable overall OpenGL annotation backend. The former can return to existing OpenGL rendering; the latter follows the Overlay renderer backend fallback procedure and may request confirmation to use Qt raster.

## 8.16 Related Independent Tools

For trajectory curves, mouse redrawing, smoothing, redistribution, and overall transformations, see [Trajectory Instructions](06_Trajectory_Operations.md). For background anchors and stabilized canvases, see [Camera Instructions](10_Camera_Operations.md).

## 8.17 Saving, Recovery, and Data Fields

### 8.17.1 Saving Procedure

1. Pause tracking and inspect the current frame, endpoints, and key turns.
2. Resolve all Trajectory previews with Apply or Discard.
3. Click Finish and confirm that no pending session remains.
4. Check this edit's interval and identity in History.
5. Use the program's save controls to write a CSV. Complete verification and path confirmation in the save dialog.
6. To verify the file, reopen the saved result and inspect endpoints, corrected failures, and overwritten segments.

Pause alone does not complete step 3; Finish alone does not complete step 5. The save controls can commit pending Tracking first, but do not replace an explicit decision on curve previews.

Recovery snapshots support recovery from unexpected interruptions and may contain copies of pending positions; they do not write every local operation to ordinary History in advance. Do not assume that a recovery or annotation file can reconstruct the image templates and all execution states from that moment.

### 8.17.2 Position Sources

| Position source marker | Meaning |
| --- | --- |
| `manual_point` | Position generated from a manually specified point |
| `manual_box` | Box determined manually through template sampling, template region, offset, or similar operations |
| `template_track` | Template match position accepted by ordinary Auto |
| `guided_track` | Match position accepted by Mouse guided |
| `edge_assist` | Refined position accepted by Edge |
| `yolo_assist` | Refined position accepted by YOLO |
| `curve_edit` | Existing position modified by trajectory editing, smoothing, redrawing, redistribution, or transformation |
| `curve_fill` | Previously missing frame position added by a curve tool |

The source identifies the final modification type, not a complete log of all processing steps. Multiple Trajectory modes write curve_edit; if analysis requires exact algorithms and parameters, retain separate processing records and pre-edit data. A successful retry after manual failure may also retain a manual source with match scores, so one field alone cannot reconstruct all interactions.

### 8.17.3 Matching and Assistance Fields

| Field | Meaning and units |
| --- | --- |
| `frame` | Actual sequential decoded frame number, starting at 1 |
| `track_id`, `class` | Numeric target identity and class |
| `x / y / w / h` | Final box center and dimensions in source image pixels |
| `best_score` | Best template match score, saved as a 0–1 value rather than the interface percentage string |
| `second_score` | Score at the competing spatial position |
| `margin` | best_score − second_score |
| `template_frame` | Source frame of the winning template |
| `recognition_x / recognition_y` | Recognized feature center before Mark offset |
| `match_rotation_deg` | Rotation relative to the template reference, in degrees |
| `match_scale` | Scale factor relative to the template reference; 1 means no scaling |
| `assist_confidence` | YOLO assistance detection confidence, distinct from template Score |

Fields are meaningful only when corresponding operations generate that information; manual overwriting clears matching data that no longer applies. Final x/y may include Mark offset and Assist adjustments, whereas recognition_x/y describes the recognition-stage position; differences do not necessarily indicate errors.

Other existing data fields are retained according to editing rules. For Tracking position sources, consult position_source and History first; original `detected` or `confidence` fields alone cannot establish which algorithm entirely produced the current position.

## 8.18 Typical Workflows

### 8.18.1 Scenario 1: A Short Missed-Detection Segment with a Clear, Visible Identity

**Condition:** ID 123 is missing in frames 1000–1050, with the same hornet before and after the gap.

**Procedure:**

1. Select the reliable ID 123 box in frame 999 and confirm continued use of that ID.
2. Create a template from a clear feature and run forward into the missing segment.
3. If fast motion causes failure, correct with Alt + left-click and continue according to the key-release rules.
4. Without Overwrite enabled, approaching the existing position at frame 1051 causes a conflict pause.
5. Compare the end of the new segment with the existing frame 1051 position, confirm identity and continuity, then Finish.

**Effect:** Missing positions for the same ID are added while the reliable existing segment afterward is retained. Frames with failed matches and no manual marks remain empty.

### 8.18.2 Scenario 2: An Entire Unannotated Segment with Only a Few Clear Key Positions

**Condition:** The target can be confirmed manually, but most frames are blurred and cannot be recognized automatically with consistency.

**Procedure:**

1. Create an identity with New and disable Auto next.
2. Specify reliable centers manually in frames 100, 110, and 120, then commit.
3. Select that ID and range 100–120 in Edit → Trajectory.
4. Select Edit, enable Fill gaps, and Preview.
5. If the actual route curves, add or drag anchors in intermediate frames and adjust handles.
6. Inspect the preview frame by frame, then Apply and save.

**Effect and principle:** Frame-by-frame in-between positions are generated between key positions, with added frames marked curve_fill. The result is a trajectory estimated from manual positions and curve constraints, not successful template recognition in every frame. The same objective can also be achieved by combining Change position and Interpolate in Edit; this procedure uses manual Tracking key positions and Trajectory gap filling.

### 8.18.3 Scenario 3: Retracking After an Automatic Switch to a Neighboring Individual

**Condition:** The same ID incorrectly follows another insect in frames 2000–2300.

**Procedure:**

1. Pause and return to frame 1999 or an earlier reliable position.
2. Verify identity manually and correct the starting point if necessary.
3. Delete unsuitable templates or add reliable templates.
4. If no old points in the erroneous segment should remain, first Delete 2000–2300; otherwise, enable Overwrite to replace them frame by frame.
5. Run again, inspect failed frames, and add manual points.
6. Finish after confirmation.

**Effect:** Overwriting replaces only newly accepted positions; deleting first prevents old erroneous records from remaining in frames where retracking fails. Operations can be undone individually before commitment or as a complete segment afterward.

### 8.18.4 Scenario 4: Lighting Changes and Multiple Templates

**Condition:** The same target moves from bright light into shadow, and the old template's Score declines continuously.

**Procedure:** Add a new template in a shadowed frame with an unambiguous identity, retaining the bright-condition template for a return to light. Observe whether they generate competition at different positions; disable the bright sample when no longer needed. Check that both samples' Mark offsets point to the same anatomical position.

**Effect:** Different templates win for the same ID according to appearance. Adding templates neither increases the number of positions per frame nor removes all identity ambiguity.

### 8.18.5 Scenario 5: Recognize the Head and Annotate the Body Center

**Procedure:** Capture a head-feature template and click the body center with Mark offset; enable moderate Rotate/Scale ranges when pose changes require them. Assist refines using the offset box. Recheck the sample offset when adding a template from another frame.

**Effect:** Image matching uses the head while final x/y represents the agreed body position. The offset transforms with estimated pose, but a fixed offset vector cannot fully express body deformation or movement relative to the head.

### 8.18.6 Scenario 6: A Sharp Turn Incorrectly Straightened

**Procedure:** Locate the erroneous segment with Pick trail, then record reliable endpoints using A/B in Set mode. For a few local errors, drag turn anchors with Edit; for an incorrect overall route, draw the actual path with Draw. Confirm shape first, then use Redistribute if required, and Apply.

**Effect:** Intermediate frames are repositioned on the edited path. Without Fill gaps, no previously absent frame records are added; with Redistribute, speed allocation changes according to the model.

### 8.18.7 Scenario 7: Spikes in a Nearly Stationary Honeybee Trajectory

**Procedure:** First confirm frame by frame that spikes are not actual movement. Select local Smooth and initially preview Median or Savitzky-Golay with a small Window and limited Max px; adjust Keep corners if needed. For a consistent overall position offset, use Transform separately before or after smoothing.

**Effect:** Smoothing handles random local variation, while Transform handles systematic offsets. Their functions differ; excessive smoothing should not compensate for an incorrect overall position.

### 8.18.8 Scenario 8: A Stationary Individual Disappears and Reappears with a New ID

**Condition:** A honeybee barely moves, but its detection box briefly disappears and returns with a different ID.

**Processing scope:** First confirm that this is the same individual, then unify identity using the ID merging and interpolation workflow in Edit; over-time region selection and Selected ID occurrence segments can help locate preceding and following ranges. Merely entering the old ID in Tracking does not automatically merge all existing boxes of the new ID.

After identity unification, fill the missing segment forward or backward with the same ID from one endpoint; if only the endpoints can be confirmed and intermediate frames cannot be recognized, use explicit interpolation or Fill gaps and retain the estimated source information.

## 8.19 Status Messages and Corrective Actions

| Status message or symptom | Meaning | Corrective action |
| --- | --- | --- |
| `Open a video first.` | No valid video dimensions or path | Open a video and wait for the image to become available |
| `Enter a non-negative integer Track ID.` | ID is not a valid nonnegative integer | Check blanks, signs, decimals, or text; use Use ID again |
| `Class cannot be empty` | Session class is blank | Enter a class before starting |
| `Enable at least one template in Templates.` | All library templates are disabled | Enable required samples and return to running |
| `Set a template first.` | Session or template state required for automatic execution is not ready | Check the current target ID and its available templates; start a session and sample a template if needed, rather than assuming Finish/Cancel cleared the templates |
| `No match` | No usable image candidate | Inspect template texture, search region, boundaries, and pose ranges |
| Red Score, green Margin | Appearance score failed | Check template suitability for the current image instead of only enlarging the search region |
| Green Score, red Margin | Another position has a similarly high score | Inspect similar individuals, search region, and template library |
| `Candidate is outside the manual box.` | Retry result is too far from the manual correction | Retain the manual point and inspect templates and search center; do not treat a high score as identity confirmation |
| `Frame … already has this ID.` | An existing position is encountered in the automatic direction | Inspect the point and retain it, confirm overwriting for this run, enable Overwrite, or delete a range |
| `Navigation paused tracking; pending rows retained.` | Navigation paused execution without losing data | Check the current frame, then Resume or Finish |
| `Hold left mouse button near target inside video.` | Cursor/Mouse guided is waiting for guidance | Hold the left button inside the video or switch to another Search mode |
| `Start/End of video. Finish to commit.` | A video boundary has been reached | Inspect and Finish; the CSV has not been saved automatically |
| `Apply or discard the curve preview…` | A curve preview is unresolved | Apply or Discard before saving or switching to an operation requiring commitment |
| `Select a range containing at least two existing positions.` | Selected segment is insufficient to define a trajectory | Expand to include two existing points or add endpoints manually |
| `Enable Camera compensation…` | Stabilized-coordinate processing was requested but compensation is disabled | Configure Camera or clear Stabilized |
| Shader fallback text | Current rendering path or device conditions do not support the shader | Read status and hover reasons; continue with the fallback path or adjust Overlay renderer |
| Assist leaves the box unchanged | No valid refinement, or the result expired/failed boundary constraints | Inspect the initial box first; adjust Assist configuration only if needed |
| Low Rate without limit | Recognition, decoding, or display is below the Speed cap | Compare in the performance adjustment order instead of increasing Speed further |
| No template list after reopening | CSV did not save the image template library | Capture templates again in clear frames; existing annotations remain usable |

## 8.20 Acceptance Checklist and Shortcut Reference

### 8.20.1 Acceptance Checks for Each Tracking Segment

1. **Identity:** The start, end, occlusions, and individual crossings all belong to the same target; neighboring individuals have not been joined based solely on high scores.
2. **Position:** Final centers follow the prior convention; Mark offset is consistent across templates, and edge boxes have been checked.
3. **Frame coverage:** Actual timeline occurrence intervals match required coverage; traversed but rejected frames are not mistaken for existing points.
4. **Source:** Manual points, template matching, Assist, curve modifications, and filled frames can be distinguished at the corresponding level in the data.
5. **Curve processing:** Positions outside the edited interval remain correct; locked points, endpoints, missing frames, and local speed changes have been checked.
6. **Commitment:** No unresolved curve preview remains, and Tracking has been committed with Finish.
7. **Saving:** CSV has been written to the intended path, and important positions agree with the original video after reloading.

### 8.20.2 Shortcuts

| Operation | Effect | Conditions or distinctions |
| --- | --- | --- |
| Alt + left-click | Immediately marks the clicked frame manually | Only within valid video image content; releasing the key retains the session, and Finish commits it together |
| Alt + Shift + left-click | Immediately captures a template and switches to Track Motion | Does not automatically Run Auto |
| Alt / Alt + Shift alone | Does not start Tracking mode | Requires a click inside the video |
| Ctrl + left-click | Existing multiple selection | Not a Tracking manual marking shortcut |
| Holding the left button | Continuous Mouse guided guidance | Requires the mode enabled, templates available, and no other active image editing tool |
| Enter with image focus | Start/Pause/Resume on the Tracking tab; Tracking Finish on other tabs; Apply for a curve preview | A focused input field retains its own control meaning |
| Right-click the image | Tracking Finish | Does not replace Apply for an unresolved curve preview |
| Esc with image focus | Cancel for an ordinary session; Discard for a curve preview | During Alt takeover, withdraws only the current takeover |
| Ctrl + Z / Ctrl + Y | Local or global undo/redo | Determined by the presence of a pending session/preview |
| Delete with image focus | Deletes the current frame's Tracking point | Deletes selected control anchors in an Edit curve preview; edits text in text fields |
| Double-click a template list row | Selects that template and seeks to its source frame | Does not automatically enable use of only that template |
| Ctrl + mouse wheel in template preview | Image zoom | Does not change actual template pixel dimensions |
| Middle-button dragging in template preview | Preview panning | Does not change annotation coordinates |
| Double-click the template preview | Restores fit-to-window | Does not resample |
| Right-click the Set button | Selects the full frame range of the ID | Distinct from right-clicking the image to Finish |
