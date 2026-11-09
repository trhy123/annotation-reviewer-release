# 5 Edit Operations

[Return to the main contents](00_Annotation_Reviewer_User_Manual.md)

## 5.1 Scope and shared inputs

This volume covers Box, ID, Interpolate, and Swap. Trajectory, Scale, and Points/Events have separate volumes. ID, Range, and x/y/w/h at the top of Edit are operation inputs. They relate to the current selection in the image, but entering values does not immediately modify annotations.

Enter an identity in ID; All IDs extends the scope to all identities. Range uses video frame numbers and supports a single frame, an inclusive interval, or multiple comma-separated intervals, such as `120-150,180,200-230`; All frames includes all valid frames. Check both switches before a batch operation to avoid applying a correction intended for one frame to the entire video.

x/y specifies the bounding box center and w/h its dimensions, in original-image pixels. Changing only the display zoom or pan does not modify these values. Link selection controls how ordinary selections are linked to the associated identities/ranges. After entering values explicitly, check the operation scope against the final displayed ID/Range.

When confirmation is enabled and All frames is off, the range confirmation dialog offers **Apply on all** to apply the operation to all frames. When All frames is on, it offers **Apply on Range** to turn All frames off and apply this operation only to the range displayed in the shared Range field. Yes retains the original scope; No cancels. Deletion, class changes, ID changes, merging, and box addition retain their respective confirmation switches; no additional confirmation is introduced when confirmation is disabled. Change position still modifies only the current frame and does not copy one frame's coordinates to the entire trajectory.

## 5.2 Box: selection by spatial region

### 5.2.1 Selection rules

| Setting | Rule |
| --- | --- |
| Center | Select a box when its center lies inside the rubber-band rectangle |
| Contained | Select a box when the entire annotation box lies inside the rubber-band rectangle |
| Intersects | Select a box when it intersects the rubber-band rectangle |
| Accumulate | Add new results to the existing selection instead of replacing it |
| Over time | Find annotations entering this spatial region over a time range, rather than checking only the current frame |

Click Select, then drag a rectangle on the canvas. Region selection filters objects and frames without modifying box coordinates. For dense targets, use a small region first and check the results table. Targets appearing in a region at different times are not necessarily the same individual.

**In Over time selection, identity and time restrictions are evaluated independently. The process has two stages: determine where to search, then determine which records to select.**

Clicking Select records the search scope for this operation. Subsequent rectangle selections with Accumulate reuse that scope; changes to ID/Range caused by previous selection results do not automatically narrow the search. When Over time is unchecked, only the current frame is checked. The following cross-frame rules apply only to Over time mode.

**Stage 1: search restrictions.** Identity and time are evaluated separately. Only records meeting both restrictions undergo spatial matching; deleted annotations are excluded.

| Input | Records searched |
| --- | --- |
| All IDs on, or no identity specified/selected | No identity restriction |
| All IDs off, with identities specified/selected | Only these automatic IDs or manual trajectories |
| All frames on | No frame restriction |
| All frames off, with Range empty, containing one frame, or listing only isolated frames | Search all frames; single-frame inputs do not restrict a cross-frame search |
| All frames off, with Range containing at least one continuous interval, such as `100-120,150` | Search only the union of the listed intervals and individual frames |

For example, Range=`100` searches across all frames, rather than only frame 100; Range=`100-120` searches only these 21 frames. This is how the tool distinguishes a current-frame input from a cross-frame interval. After entering rectangle-selection mode, the status bar displays the actual search scope; check it before drawing the rectangle.

**Stage 2: selection results and subsequent editing.**

- All frames off: retain only the annotation records for each ID that actually meet the rectangle condition. The shared Range displays the union of these frame intervals, and the yellow strip shows the same local scope. An entire ID is not selected merely because it enters the rectangle in one frame. Immediately following deletion, class changes, ID changes, or geometry changes operate on these records.
- All frames on: the rectangle identifies identities, and subsequent operations cover all frames of those identities. The local restriction to frames entering the rectangle is not retained.
- With Accumulate on, dragging adds matches to the selection. Hold Shift while releasing the rectangle to subtract matching rows or identities, according to the frame scope. With Accumulate off, dragging replaces the selection.

Exiting Choose range does not change All frames. Other selections or inputs may change the scope of subsequent editing. When performing several changes in succession, repeat the rectangle selection and check ID/Range. For the data layers in Raw/postprocessing previews, see the [Detection volume](04_Detection_Postprocessing_Tests.md); these layers must not be confused with the main review table.

A quick rectangle drag is evaluated at the mouse-release position. If the rectangle is too small, its coordinates are invalid, or no objects match, the status bar explains the reason and retains the existing selection. A failed operation is not reported as successfully selecting zero IDs.

### 5.2.2 Example: a stationary honeybee reappears with a different ID

1. Locate the last frame containing the honeybee and confirm its position.
2. In Box, choose Center, enable Over time, and enable All IDs or clear the previous ID restriction. Draw a small region at that position; restrict Range to the period around the disappearance if necessary.
3. In IDs/Selected ID, inspect the selected old and new identities and their continuous segments.
4. Go to the last frame of the old identity and the first frame of the new identity to check that they represent the same individual.
5. Open ID, set the old identity as Target and the new identity as Source, and confirm before clicking Merge.
6. If the missing interval needs filling, enable Interpolate between, then inspect the intermediate region frame by frame for plausibility.

## 5.3 Box: Change position

### 5.3.1 Four geometry modes

| Mode | Interaction | Preserved quantities |
| --- | --- | --- |
| X/Y | Specify a new center or move the position | W/H |
| W/H | Adjust box dimensions | Center position |
| X/Y/W/H | Drag the center/edges for combined adjustment | Unmodified components follow the interaction constraints |
| Draw | Redraw the target box on the canvas | The new rectangle determines the center and dimensions |

Select ID and Range, then click Change to enter the relevant mode. Check the interactive box on the canvas and the geometry inputs at the top, then apply the new position with Apply. Box centers use original-image coordinates; the Camera-stabilized view converts between display and original-image coordinates.

### 5.3.2 Continuous, Auto next, and exiting

When Continuous is unchecked, editing mode ends after one successful modification; when checked, modifications can continue. Auto next is available only with Continuous enabled and moves to the next frame after an operation is successfully staged, following the overall playback direction. Committing with Apply or Enter retains the current frame without an additional Auto next step.

In editing mode, clicking Apply before specifying the required position exits without creating an empty geometry change. ESC exits the interaction. Changing the Continuous checkbox during editing also ends the current editing mode. On exit, check which points have actually been applied; exiting an interaction must not be treated as undoing completed operations.

A Continuous session uses lightweight local undo to step back through position specifications in that session. After the session ends, History manages operations according to the session's commit boundary. When a text field is being edited, Ctrl + Z applies to text editing first and should not be used to infer the trajectory undo state.

After a position is specified, the trail immediately reflects the pending coordinates. Modifying an existing point recalculates only the affected neighboring curves and retains the geometry cache for other segments. Adding or deleting points changes the continuous-segment structure and rebuilds the affected target's cache. Frame navigation still displays the relevant portion according to Before / After; local undo and redo restore or update the trajectory accordingly.

While Continuous editing remains active, right-clicking the canvas still commits the position specification for the current frame, regardless of the main tab or Edit subtab currently displayed. Added frames immediately enter the selected ID's yellow occurrence range, and ranges added in this session appear as a green strip; moving an existing box does not add a green range. Local undo, redo, and session commit refresh the strips together. In single-edit mode, green marks the most recent addition; other data edits do not retain an old marker.

### 5.3.3 Confirm and class changes

Confirm is a three-state control governing whether a confirmation dialog appears before Change position, Change class, and Delete. Checked requires confirmation for all three; the intermediate state requires it only for Change class and Delete; unchecked disables confirmation for all three. It does not set the annotation row's manual confirmation status.

Choose a class for Change class and click the adjacent Change button to apply it to the target scope. Delete removes annotations within its scope. It does not delete the video or original disk files, and does not delete an entire uncommitted Tracking interval.

The Change class drop-down lists only classes configured in the INI file. The control itself summarizes the classes of the selected identities in the working table: it displays the class when all share one class, or multiple when two or more classes occur. This indicator is not added to the list as a selectable class. Statistics are cached by identity and data revision; playback and opening the list do not rescan the operation Range. Actual changes still follow the selected ID, Range, and All frames.

When the relevant Confirm policy is enabled and All frames is unchecked, the Change class and Delete confirmation dialogs display `Current Range is not All frames.`. Yes applies only to the current Range; Apply on all operates on all frames of the current identities without changing the displayed shared Range or All frames state; No or closing the dialog leaves data unchanged. With Confirm disabled, the operation proceeds directly within the original scope without an additional prompt. Alt + C cycles the selected targets through the class list, following the same scope and confirmation rules.

The D button in the shared Edit area is fully equivalent to Delete in Box, using the same ID, Range, All frames, confirmation settings, and undo rules. Its scope differs from the endpoint-interval Delete in Interpolate.

When operation details in Confirm edit are long, they appear in a scrollable, read-only text area whose contents can be selected and copied. `Current Range is not All frames.` and `Apply this command?` remain outside that area, and the bottom buttons do not scroll with the text. When asking `Current Range is not All frames.`, the dialog initially focuses Apply on all; other confirmation dialogs initially focus Yes. Closing the dialog or selecting No cancels the operation.

## 5.4 ID: merging and renumbering

### 5.4.1 Merge ID

Target is the identity to retain; Source is the identity to merge into it. Click Source to exchange the Target and Source inputs. Select chooses the identity pair in the image; Clear clears Source; Clear all clears this group of identity inputs. The blue and green timeline strips represent Target and Source respectively; red indicates frames in which both occur.

Source accepts multiple IDs; Target requires one ID. Double-click the Source field to open a scrollable miniature ID input table below it. The original field still supports normal text selection, copying, and pasting. The miniature table supports Ctrl/Shift multiselection and Ctrl + A to select all; clicking a row selects its identity and navigates to its nearest occurrence, synchronizing the shared ID, image, and table highlighting. Delete in this table removes the selected IDs only from the Source input, without deleting annotations; Esc hides the table. When the ID subtab is active, Target boxes have a thick blue outline and Source boxes a thick green outline, updated immediately when inputs are entered or removed. These outlines are editing indicators for this page only and do not change saved annotations or display styles on other pages.

The **M** keyboard shortcut adds the active automatic ID to these inputs: it fills Target first if empty, otherwise appends to Source; pressing it again does not remove the ID. The **N** shortcut removes the active ID from Source, provided it is still selected and exists in the current frame. M/N do not merge anything; inputs and strips update immediately. Normal text entry remains available in text fields.

Merge primarily unifies identities. It does not automatically determine which of two boxes in the same frame corresponds to the real target, and must not be used to conceal two distinct individuals present simultaneously. Inspect conflicting frames first; narrow the range, delete duplicate boxes, or use Swap as necessary.

Interpolate between fills gaps between the relevant identity segments. When checked, it finds and interpolates gaps using the complete occurrence segments of the listed Target/Source identities. Interpolation is not restricted by the shared Range, although the ID merge itself still follows the current Range or All frames. For example, if Target occurs in frames 100–120, Source in 140–160, and Range is 140–160, merging Source also fills frames 121–139.

#### Automatically finding continuable fragments

1. Select the box to continue in the current frame, usually near a break. Existing Target/Source inputs can remain; searching does not require Target to occur in the current frame and also works with an empty Target.
2. Click **Find** to open **Merge fragment candidates**. The window does not take focus when opened. Click a threshold field to enter numbers directly; after a button or candidate-row action, focus returns to playback, where Space toggles playback/pause and R controls reverse playback.
3. Select **Continuity** mode. Direction follows Reverse: off means **Forward** (later frames), on means **Backward** (earlier frames). Changing Reverse while the window is open updates Direction immediately; direction can also be selected manually. Each **Search** starts from the actual frame number and xywh of the currently selected box and appends new candidates; it does not use Target's historical position. Duplicate candidates are not added again, and Batch continues increasing. The window displays Searching…, then reports new and total counts, explicitly indicating when no new results were found.
4. Click a candidate row to select its ID and navigate to the position in that fragment nearest the current frame, synchronizing the shared ID, image highlight, and trail. Ctrl/Shift supports multiselection; Shift selects consecutive rows in the current table order. Double-click a column header to sort; the default is ascending Range.
5. Searching follows a unique continuation chain and stops at the first position with multiple possible continuations. Candidates on the unique chain have **Use** checked by default; branching candidates are unchecked and have red text except in the ID column. Retain one branch start, delete the other branch rows with **Remove**, then click **Continue** to proceed from the retained fragment's endpoint. Results append to the existing list, with Batch distinguishing search batches. Continue is also available at a chain end that requires no branch choice.
6. **Use/Unuse/Remove** affect only selected rows. **All rows** selects all table rows and these IDs in the main window without changing Use states. Use determines which IDs **Fill candidates** appends to Source. Remove deletes candidate rows only, without deleting annotations or changing IDs already entered in Source. **Select all candidates** selects all candidate IDs in the main window and displays highlights and trails, but does not select every candidate-table row. After a selection change in the main image, the checkbox reflects the actual selected IDs.
7. Return to the main window, check the shared Range/All frames, then click **Merge**. Searching, continuing, sorting, navigation, checking, and filling inputs do not modify annotations.

Searching starts from the currently selected box's position in the specified temporal direction. When following a known continuous segment with the same ID, it uses that segment's actual endpoint. After finding a unique continuation candidate, it continues from the new fragment's endpoint. It does not reuse the initial position indefinitely or restart from a distant historical Target/Source segment. Small gaps within an ID can be traversed when both time and distance are sufficiently close.

Each Search also lists the selected ID's reference fragment, with Use enabled by default; hover to identify the reference row. Continuity lists the segment extending from the current frame in the search direction; Duplicates lists the actual reference fragment within Direction and Range. Continue appends continuation results without duplicating reference rows.

| Parameter/column | Meaning |
| --- | --- |
| Max gap frames | Allowed missing frames between adjacent fragments; default **5 frames**, independent of video FPS. 0 accepts only adjacent fragments with no missing frames |
| Distance (× diagonals) | Distance between adjacent endpoint box **centers**, divided by the mean of their diagonal lengths; default **0.4 times**. For two 30×40-pixel boxes with 50-pixel diagonals, the allowed center distance is at most 20 pixels. The Distance column shows the same ratio, unaffected by display zoom |
| Overlap frames | Small number of overlapping frames permitted; default 5. A candidate must still extend in the selected direction |
| Frames | Number of frames in the continuous fragment, including both endpoints |
| Gap | Positive for missing frames, 0 for immediate adjacency, negative for overlapping frames |
| IoU | Mean box intersection area/union area in Duplicates mode; closer to 1 indicates greater overlap. Not used by Continuity |
| From ID | Identity fragment from which this candidate continues |
| Batch | Search batch within this window; increments for Search and Continue. Repeated candidates retain their original batch |

Continuity searches only fragments of the same Class. The ID column is to the left of Use, with bold numbers in each identity's assigned color. Row backgrounds and strips use a cycling palette; all fragments of one Continuity candidate ID share a color. Continuity strips show that ID's complete actual frame segments, including portions before the search start, while table Range still describes the search hit. Duplicates strips show only matched frames. Numbers beside strips are candidate IDs, displayed in the ID's color. The row containing the current frame is centered, with its index cell yellow; when no candidate covers the current frame, a thin yellow line marks its temporal position. Clicking a row also centers it precisely, allowing repeated clicks on the preceding/following row at the same relative position. Frame changes always retain manual single or multiple selections. Yellow positioning and Use checkboxes are independent; they do not automatically check candidates or merge them. Closing the window restores the ordinary Merge strips.

**Example:** ID 1 ends at frame 100 and ID 2 appears near the original position at frame 102, leaving one missing frame; searching forward from frame 100 can find ID 2. If ID 2 then moves elsewhere and ends at frame 130, the next step uses its frame-130 position to find a continuation ID, rather than the frame-100 position. Results are suggestions only; another nearby target of the same class can still appear as a candidate.

Fill candidates fills candidate IDs only. The final Merge still follows the shared Range/All frames. If an ID also has records at other times, check the scope carefully to avoid merging every period together.

#### Finding duplicate boxes in the same frame

In the same Find window, switch to **Duplicates**. Using the selected ID's actual boxes within the shared Range/All frames as references, it checks other IDs frame by frame. Direction can be Forward, searching the current and later frames, or Backward, searching the current and earlier frames; Range always limits the search. This mode does not use the temporal gap or allowed overlap-frame count for fragment continuation.

The search region is a rectangle that moves with the reference box frame by frame. **Area W/H (× diagonal)** specifies its full width and height, each multiplied by the reference box's diagonal in that frame; both default to 1.2. A candidate is included only when its center lies in the rectangle. The two integer **x/y offset** fields position the rectangle's center relative to the reference box center in pixels; right/down are positive, and both default to 0. For a 30×40 px reference box with a 50 px diagonal, W=2 and H=1 define a 100×50 px search rectangle.

Duplicates uses rectangle width and height rather than the Continuity Distance threshold; no additional circular distance limit applies. Distance in the Duplicates table is the candidate center's distance from the offset search center divided by the reference box's diagonal in that frame, and is provided only for comparison.

**IoU ≥** is an optional additional condition, enabled by default at 0.30. It uses the original boxes' intersection/union and can be combined with X/Y offsets; disable it when finding separated boxes, otherwise nonoverlapping boxes are excluded. **Same class** is enabled by default; disabling it also searches other classes. For example, to find a false-positive box on a stick about 30 px to the right of a hornet, disable IoU, set X=30 and Y=0, then adjust W/H and Same class. Matching frames are split into continuous fragments; candidates still require manual assessment.

Use is off by default for other duplicate-box candidates. Select candidate rows, or check Use, then click **Use matched frames**. Their respective matched frames become a local selection: shared ID contains candidate identities, Range is the union of their frame intervals, Target receives the reference ID, Source receives candidate IDs, and Interpolate between is turned off. Reference rows are always excluded from this cleanup scope, even when selected with other rows, so the reference itself is not deleted. Delete then removes only matched candidate records, and Merge merges only each Source's own matched frames. Same-frame conflicts still require choosing which box to retain; boxes are not moved and Raw ID is not modified.

Multiple search batches can be appended to one list. When using matched ranges, select duplicate candidates for one reference ID at a time; check the reference identity in From ID. Subsequent changes to shared identities, Range, All frames, or data invalidate the local selection; use Use matched frames again. Explicitly choosing All frames/Apply on all instead operates on entire identities.

Double-click the shared **ID**, shared **Range**, or Merge **Source** field to expand its miniature table; double-click the same field again or press Esc to collapse it. The original field still supports copying and pasting. ID/Source tables support click-to-navigate and Ctrl/Shift multiselection. The Range table lists input frame intervals row by row; selected rows can refill the shared Range and turn off All frames, while a click navigates to the clicked interval. Frame changes do not reparse or shrink the list. Delete in the Source table removes input items only, without deleting annotations. The shared ID/Range tables do not bind Delete, to avoid accidental deletion.

#### Confirming scope and handling overlaps

After Merge is clicked, **confirm the scope first, then resolve conflicts**. When All frames is unchecked, Yes uses the current range; Apply on all uses all frames of the listed identities without changing the shared Range or All frames controls. After that choice, the range confirmation is not repeated, nor does expanding the scope trigger repeated questions for a previously handled set of conflicts.

Conflicts include overlaps between Target and Source and between different Sources. The **IDs overlap** window displays the current index/total and frame interval, with five buttons:

| Button | Action |
| --- | --- |
| Goto range | Navigate to the first frame of this conflict interval; keep the window open without changing the confirmed merge scope |
| Keep ID xxx | Retain this original ID's box records in the conflict interval and delete the other side's overlapping records; the merged identity is still named Target |
| Keep ID yyy | Retain the other side's box records under the same rules |
| Skip range | Retain all original IDs and annotations in this conflict interval, skip it, and continue with later conflicts; closing the window or pressing Esc also skips it. Earlier choices within this interval are not applied |
| Cancel merge | Cancel the entire merge; earlier conflict choices are not partially written |

The window does not take focus from the main window, allowing frame navigation for preview. The red strip covers all these conflict types. With three or more IDs in one interval, the retained identity must be chosen step by step, so the same frame interval may prompt for multiple identity pairs; the index/total reflects the actual number of required choices. Once all conflict choices are complete, merging, conflict deletion, and optional interpolation are committed together and can be undone as a whole.

### 5.4.2 Change entire and Change range

Enter the destination number in Change ID. Change entire renumbers the entire selected identity; Change range renumbers only the specified range, allowing a segment to be split from its original identity. Resolve overlap conflicts when the destination ID already exists; successful entry does not imply a unique identity in every frame.

Multiple selected automatic IDs can be changed to the same number in one operation. Unselected identities are unaffected, and the entire renumbering can be undone in one step. Before execution, same-frame duplicates are checked between the destination and each source, and between different sources. A destination ID occurring only in other, nonoverlapping frames does not trigger a duplicate warning. If multiple boxes would actually share a frame, the conflicting frames are listed and confirmation is requested; canceling applies no part of the operation.

Find under Duplicate ID checks duplicate rows with the same ID in the same frame. Locate duplicate frames first, then use the image to decide which box to retain. The same ID appearing in different frames is a normal trajectory, not a duplicate conflict.

**Example: the latter half of ID 25 switches to another individual.** Set Range from the first incorrect-identity frame to the end, split that segment with Change range, then check its actual identity. If two trajectories exchange identities at the same time, Swap is more direct.

## 5.5 Interpolate: endpoint geometry and interpolation

Linear interpolation segments update when anchors are corrected. After a box in an interpolated segment is modified, that frame becomes a new anchor. Existing interpolated boxes between it and the preceding/following retained anchors have x/y/w/h recalculated, rather than following the old line through the previous position. Repeated corrections progressively divide the path into multiple straight segments. Original detection boxes and other manual anchors stay fixed; no frames are added and no extrapolation crosses missing-frame breaks. This applies to ordinary position changes, Continue previews, and manual Tracking corrections; undo, redo, and editing after saving retain the same rules.

With Continue enabled and Change in editing mode, dragging the pending box or changing x/y previews the neighboring interpolated trail before placing the point. Rapid consecutive inputs are coalesced, using only the latest position. The preceding/following anchor caches for the same placement are reused and only affected segments are recalculated; other IDs and segments remain unchanged. The annotation table itself is unchanged at this stage; clearing pending edits, changing frames, or exiting restores the original display. After each placement, neighboring interpolated boxes immediately enter the staged continuous-edit result, without waiting for the final Apply. Neighboring frames can be browsed, and local undo/redo includes this interpolation update. The final Apply commits continuous editing as one formal operation.


### 5.5.1 Controls and calculation

A/B each contains frame, id, x, y, w, and h. Selected as A/B copies the selected box's geometry and frame number to the relevant endpoint; the fields can also be edited. A/B may be entered in reverse chronological order; execution sorts them by actual frame number.

Click A: or B: at the start of a row to navigate to that endpoint. A valid frame enables precise navigation; an existing id selects the automatic identity or entire manual trajectory. The two are evaluated independently; missing, malformed, or nonexistent items are silently skipped without an error dialog. If the identity is absent at the target frame, it can remain selected while navigation goes to the entered frame, rather than automatically jumping to its nearest occurrence. For example, with frame=400 and id=7, if ID 7 appears only before frame 390 and after frame 410, clicking still goes to 400 to inspect the gap. Entering only id retains the current frame; entering only frame retains the current selection.

With one automatic ID, All frames off, and more than one frame in the shared Range, either Selected as A/B button captures the exact frame ranges. A/B display the outer endpoints. Choose range → Over time can supply this selection. Interpolate interval first fills bounded gaps within the selection. When there are no gaps, you can confirm linear replacement for each selected segment, with nearby observations used for isolated frames. Delete includes the selected endpoints by default. Editing an A/B frame or ID returns to the regular endpoint workflow.

The C button at the lower left clears all inputs in both A/B rows, cached endpoint geometry, and the associated progress-bar markers.

Endpoint entry does not require all information at once. With no box or manual point selected, the current frame is still recorded; if only an ID is selected, its identity is also recorded. Coordinates and dimensions can be completed later. Changing the frame or identity does not reuse old geometry from another endpoint observation. Required information is checked for completeness only when Interpolate interval is executed. On the Interpolate page, A/B letters below the progress bar mark entered endpoint frames and support click-to-navigate; the markers are hidden on other pages.

Within a segment, the center and dimensions are linearly interpolated by relative frame position. For example, if the center is (100, 50) at frame 100 and (120, 70) at frame 110, frame 105 is estimated at (110, 60). This model assumes linear change over time between endpoints; it does not guarantee that the actual trajectory is straight.

### 5.5.2 Actual execution scope

1. If endpoint IDs differ, a prompt first asks whether to merge B's identity into A; declining stops interpolation.
2. If internal gaps exist, existing geometry is used to fill them in segments, rather than flattening all reliable observations into one A/B line.
3. If the selected range extends beyond the known first/last observations, the nearest geometry and explicit endpoint fields construct the outer boundaries. Extrapolated points require manual inspection.
4. If the interval is already complete with no gaps to fill, a prompt asks whether to replace it using A/B; this reconstructs the interval rather than merely filling missing observations.
5. Interpolation cannot be completed without usable geometry or at least two valid endpoints.

If the A/B frame fields are incomplete and the two id fields contain only one automatic ID, or both contain the same automatic ID, Interpolate interval fills all gaps in that ID's entire trajectory that have valid observations on both sides. It uses neither the shared Range nor a single entered frame to limit its scope. Existing observations remain unchanged, with no extension beyond the trajectory's first/last observations. If no gaps exist, data remains unchanged and no prompt asks to overwrite the complete trajectory. For example, if ID 7 occurs in frames 100–120 and 130–150, entering only id=7 fills frames 121–129. When both A/B frame fields are filled, the interval rules below still apply.

### 5.5.3 Example 1: a short missed-detection interval

The target exists in frames 200–220, is missing in 221–225, and reappears at 226 with its identity confirmed.

1. Navigate to 220 from Selected ID and choose Selected as A.
2. Navigate to 226 and choose Selected as B.
3. Check the class, dimensions, and any intermediate occlusion/sharp turn.
4. Click Interpolate interval and inspect frames 221–225.
5. The results originate from interpolation; do not count these five frames as successful model detections.

### 5.5.4 Example 2: an entirely unannotated interval

1. Assign a new ID to the target.
2. Use the Change position addition procedure or Tracking to specify boxes at key frames such as 100, 110, and 125.
3. Confirm that all key frames use the same ID.
4. Set A/B to cover the target interval and interpolate, using existing key frames as segment boundaries.
5. Add key frames around rapid turns and occlusions, then inspect again; do not assume a straight line across a long occlusion that cannot be assessed.

### 5.5.5 Example 3: incorrect positions with a box in every frame

Select two reliable endpoints around the incorrect segment and confirm interval replacement during interpolation. This can remove a sequence of incorrect positions but also overwrites the original movement detail within that interval. For curved paths, prefer Trajectory Edit/Draw.

### 5.5.6 Deleting an incorrect segment inside A/B

1. Record reliable preceding/following frames in A/B and check the target identity; endpoint order may be reversed.
2. Click Delete beside Interpolate interval and check the A–B range in the dialog.
3. If endpoint identities match or only one endpoint has an identity, that target is filled automatically. If they differ or are both empty, select or enter the target ID/existing manual trajectory name for this operation.
4. Endpoints are retained by default and only internal frames are deleted. Check Include endpoints to delete them as well.
5. Click Delete and inspect the result; undo this operation if restoration is required.

With regular A/B endpoints, Delete uses those endpoints and the target in the dialog. Endpoint geometry may be left blank. For example, A=100, B=110, and target ID 7 deletes frames 101–109 of that ID by default. The entire deletion is one undo operation for the corresponding data source.

## 5.6 Swap: identity exchange and position-based correction

### 5.6.1 Inputs, preview, and commit

The mode drop-down offers **Exchange** and **Position**. Begin/End each has a frame field and an ID-list field. Enter at least two identities, such as `001,002` or `001,002,003,004`. Both rows must contain the same set; identity order and frame order may be reversed. Exchange permits exactly two IDs; Position permits two or more.

**Selected as Begin/End** supports incremental entry: with no selection it records the current frame first; with one selection it adds that identity; with multiple selections it fills that set. Completeness is checked only before execution. Click **Swap Begin:/Swap End:** at the start of a row to navigate to a valid frame and select existing identities; missing, invalid, or nonexistent items are skipped independently without a dialog. **Clear** at the lower left clears these rows, temporary endpoints, and intermediate anchors without changing annotations or other tools' inputs.

**Preview** toggles an identity-correction preview. When pressed, the button stays down while computation runs in the background; pressing again cancels. Changing mode, endpoints, IDs, range, or other inputs invalidates the existing preview and requires a new one. The preview displays proposed results only: boxes do not move, orange labels show original ID → resulting ID, and purple `ID ?` indicates uncertainty. Orange Changed and purple Uncertain timeline strips locate the respective intervals.

**Swap A ↔ B** is the final commit button. Exchange can be committed directly or after Preview. Position requires a preview with modifiable items before commit. Committing exits the preview; the entire change can be undone. Uncertain frames are skipped by default rather than forcibly exchanged.

### 5.6.2 Exchange: swapping two IDs throughout an interval

Begin and End bound the actual exchange interval, including both endpoints; identical endpoint frames allow a one-frame exchange. Exchange uses the interval in these two rows, not the shared Range as a substitute or Position's intermediate anchors.

1. Locate the first frame with exchanged identities, select both targets, and choose Selected as Begin.
2. Locate the last frame requiring exchange and choose Selected as End.
3. Check that both rows contain the same ID pair; use Preview to inspect labels and the orange strip if required.
4. Click Swap A ↔ B, confirm, and inspect transitions at both ends.

**For example, if two targets have reversed IDs throughout frames 1000–1040:** use Exchange for the entire interval. If only scattered frames are wrong, do not exchange all the correct frames too; use Position.

### 5.6.3 Position: correcting intermittent, repeated, or multiple-target identity switches

This mode computes a one-to-one identity assignment for each frame using the two-dimensional relative structure at reliable first/last frames and short-term intermediate motion continuity, requiring agreement between results inferred from both ends. It does not sort by global horizontal position or replace intermediate trajectories with straight lines between endpoint positions.

1. In the shared ID field, select the two or more targets to correct and specify the range to inspect.
2. Before the incorrect range, find a frame in which **all target identities are correct and each ID has exactly one box**, then set Begin.
3. After the incorrect range, find another correctly identified frame and set End; enter the same ID set in both rows.
4. Choose Position, click Preview, and inspect images and result labels along the orange and purple strips.
5. For additional constraints, click **Anchors**, then **Add current frame** on Intermediate anchors to add a verified correct intermediate frame. Frame numbers and identity lists can be edited directly, or removed with Remove. Run Preview again after changes.
6. On Anchors → Preview details, inspect Changed/Uncertain intervals and reasons; double-click an interval to go to its first frame.
7. After verification, click Swap A ↔ B to commit only clearly determined mismatches. Frames judged correct remain unchanged, and uncertain frames are skipped.

First, last, and intermediate anchor frames remain unchanged. If All frames is unchecked and the shared Range contains continuous intervals, that range further limits the frames to correct. If Range contains only one frame or no continuous interval, the range between the first/last anchors is used. All frames does not extend Position beyond anchor boundaries or to other, unlisted IDs.

Missing targets, multiple boxes for one ID, nearly coincident boxes, paths crossing between frames, abrupt motion changes, contradictory endpoint structures, or inconsistent bidirectional assignments are marked Uncertain. For actual crossings, occlusions, or substantial rotation, add intermediate anchors or inspect shorter intervals separately. Geometry alone cannot confirm the true identity of an occluded individual.

**For example, A and B have correct IDs 001 and 002 but repeatedly switch in frames 101, 103, 105, 108–112, and 115:** use correctly identified frames 100 and 116 as anchors, set Range to `101-115`, and enter `001,002` at both ends. Position attempts to correct only clearly mismatched frames while retaining other correct frames. For cascading identity switches among four neighboring targets, enter all four IDs and use the same preview procedure; unlisted targets do not participate.

Position modifies result identities only. It does not move, add, or delete boxes, or change Class or Raw ID. It operates on the currently loaded review annotations. For Detection Raw/temporary postprocessing previews, use Load result first to avoid treating another data layer as the main table.

## 5.7 Operation stash

### 5.7.1 Creating and viewing drafts

The R button at the lower right of the shared Edit area opens the nonmodal **Operation stash**, containing manual drafts and automatic operation-input records. Records are separated by video path and stored in the `operation_stash` subdirectory of the current recovery directory. They remain available after closing the window, closing the video, or restarting. They are not written to annotation SQLite or settings.ini and do not enter annotation History.

Automatic recording captures complete relevant input groups: shared ID/Range, Merge, Change ID, Change position, Change class, Interpolate, Swap, Trajectory endpoints, Tracking identity, Match binding, and Notes. Contents are retained when input is completed or before execution/clearing. Consecutive typing is coalesced and recorded after about 0.8 seconds or a focus change; keystrokes are not saved individually. Display/Decoder parameters are not recorded, nor are automatic Range updates during playback. Each video retains at most 1000 automatic records; manual records are not automatically discarded.

Source / name defaults to a readable source plus sequence number, such as `Merge ID #0012`. Time shows when recording was triggered, and Type distinguishes Manual/Automatic. Top controls filter by type, source, text, and From/To time range; time fields accept direct entry, with time before date and no calendar popup. Double-click headers to sort; newest first is the default. **Restore inputs** restores the record's entire original input group, including unfinished text, without executing annotation operations. Automatic records cannot be edited directly; use Store to create a manual draft for additions or organization.

| Action | Saved content |
| --- | --- |
| New | Create and select a draft at the current frame using the current shared identity; do not read shared Range as the starting point |
| Connect | Connect the current frame to the selected draft's last recorded point as an inclusive interval, merging overlapping and adjacent ranges; retain that draft's original target |
| Add point | Append only the current frame as a point, without filling the gap from the last recorded point; this becomes the starting point for the next Connect |
| Store: Range | Store the current shared identity, Range, and All IDs/All frames states in the selected draft; a single interval for one target can include existing endpoint geometry |
| Store: Endpoints | Store the current Interpolate A/B or Swap Begin/End in the selected draft; both frame numbers must be valid, but other fields can be incomplete |
| Store: Segment | Store the continuous segment of the active identity containing the current frame; prompt for repositioning if the frame is outside an available segment |

The source drop-down defaults to **Focused inputs**, reading the entire group associated with the last operation input focused in the main window. For example, after using an Interpolate x field, Store records the frame numbers, IDs, positions, and dimensions of both A/B; after using a Swap field, it records the entire Begin/End group. One-sided or incomplete Interpolate/Swap inputs can first be saved as drafts. With no valid frame number, the current frame provides a stash navigation position without replacing the original input. The drop-down also allows an explicit source, including Tracking, Match binding, and Notes.

**Store** replaces the selected manual draft; **Append** adds the source's identities and intervals to it, merging adjacent or overlapping intervals without filling gaps between separated ones. Both create a record if no manual draft is selected. Appending endpoint groups retains the earliest and latest valid endpoints while Range retains every interval. Existing dedicated parameters are retained during append; new sources can supply previously missing parameters. New always creates a separate record. Custom names remain when recording subsequent points, using Store, or using Append. A selected manual row remains the editing target for Connect/Add point; dragging the main progress bar or changing the shared ID does not automatically switch that target.

**Procedure example:** Select ID 7 at frame 100 and click New. Go to frame 120 and click Connect to obtain 100–120. Go to frame 200 and click Add point to obtain `100-120, 200`; then go to 210 and click Connect to obtain `100-120, 200-210`. These actions organize operation ranges only and do not generate intermediate annotation points. Afterwards, use Use range or Send, then execute the relevant editing tool.

**Inputs** is partitioned by input position: shared ID is one part; Merge Target/Source are two parts; the endpoint IDs of Interpolate and Swap are also stored separately. Parts are separated with `|`, such as `112 | 123,125-126`; hover to view each part's name and full contents. Append adds to the corresponding parts separately, without mixing Target into Source.

Double-click Source / name, Inputs, or Range in a manual record to edit its name, inputs, or frame range. Inputs parts accept automatic IDs, ID lists, and manual trajectory names. Range uses shared-range expressions, such as `100-140, 200-220`. Changing identities clears the draft's previous All IDs state; changing the range clears its previous All frames state. Invalid ranges do not replace saved values.

The selected row is yellow. Column widths can be dragged and are written to `tables/operation_stash/column_widths` in `settings.ini` when the window closes, then restored on reopening or the next launch. After sorting, editing and point recording still use the draft's stable identity rather than its displayed row number. If filtering hides the selected record, operations do not continue on that hidden record.

Changing Inputs or Range clears previous endpoint geometry and Merge-specific fields, rebuilding endpoint image references to prevent old coordinates being carried into a new target or frame. When subsequently sending to an endpoint tool, recheck and complete the positions. Drafts can still be restored or sent if the target no longer exists, without a blocking dialog; the target can be specified again in the receiving tool.

× or Delete in the list removes selected stash entries only, not annotations. During cell text editing, Delete retains its text-deletion behavior. A selected entry previews its range on the progress bar as a black strip with opacity 0.3, without automatically rewriting shared ID/Range or executing edits. The ↗ navigation column on the left directly selects the record and jumps to its first frame; Start and End navigate to its first and last boundaries. The main progress bar can then be dragged for comparison.

### 5.7.2 Restoring ranges and sending endpoints

Use range restores the draft to shared ID, Range, and the relevant All switches, and clears Filter's exact-record editing scope. The Send drop-down defaults to **Focused outputs**, using the operation-input group last focused in the main window, corresponding to Store's Focused inputs; a receiving tool can also be chosen explicitly. If the receiver has fewer positions than the stash has parts, a prompt asks which part to fill; canceling leaves inputs unchanged. Multiple parts are not combined into one ID list.

| Destination | Filled content and subsequent operation |
| --- | --- |
| Range | Restore shared ID, Range, and All switches |
| Interpolate / Swap | Fill existing endpoints; an ordinary range supplies first/last frames and determinable identities, with missing geometry to be completed |
| Trajectory | Select one existing target and fill the editing interval, then choose a trajectory operation and preview |
| Delete | Restore shared identities and range and switch to Box; check before clicking Delete |
| Merge ID | Restore shared range and switch to ID; fill Target/Source from the two respective parts; a single part is still split into the first automatic ID and remaining IDs |
| Change position | Restore shared identities and range and switch to Box; clear old position inputs and specify the required position again |
| Change class | Restore shared identities and range and switch to Box, then choose the required class |
| Change ID | Restore shared identities and range and switch to ID, then check the new ID and entire-identity/range operation |
| Choose range | Restore shared identities and range and switch to Box, then click Select to start canvas region selection |
| Tracking / Match binding / Notes | Restore the corresponding operation inputs without tracking, binding, or saving |

Merge Target/Source can be edited further on the destination page; this feature does not infer automatic IDs for manual trajectories. Interpolate, Swap, and Trajectory use one endpoint interval, so sending a multi-interval draft uses the two outermost endpoints. Store independent, discontinuous editing intervals separately where appropriate.

Restore and Send do not execute deletion, interpolation, exchange, or curve application. Check geometry and identities in the receiving tool before execution. A nonexistent target does not prevent draft restoration; actual execution checks the receiving tool's requirements. If image references cannot be reconciled, specify the draft again. The program does not guess another nearby trajectory or automatically create a new identity.

After video indexing completes, stashed endpoints reconcile frame numbers by image identity, and All frames drafts update to the final valid total frame count. Multiple drafts retain their own targets and ranges rather than automatically expanding into all IDs × all intervals as a batch operation.

**Example: comparing two suspect segments.** Store range for ID 7, frames 100–140, named “takeoff segment”; then save ID 12, frames 800–850, as “crossing segment”. To inspect, select a draft and navigate with Start/End. To delete the first segment, explicitly use Use range, check ID 7 and its range, then execute Delete. The second segment is not deleted with it.

## 5.8 Saving edits during a postprocessing preview

In Raw cache or a postprocessing preview, click a box to establish its source before using these inputs. Editing Raw writes to Raw cache; editing a postprocessed box modifies only the result copy, without automatically changing Raw cache or the original review annotations. To write back, use Apply to Raw in Postprocess settings, then manually run Reprocess range. Use Save preview to retain results. Canceling the parameter window does not undo box edits; use Undo/Redo. See [Preview editing and range reprocessing](04_Detection_Postprocessing_Tests.md#451-editing-raw-and-results).

## 5.9 Acceptance checks and saving

Check identity uniqueness, operation scope, positions/dimensions, transitions at both ends, and source markers in order. Undo incorrect committed operations with History, then use Save as when finished. Interpolation, merging, renumbering, and exchange serve different purposes; choose according to the error type, and do not use final curve smoothness as the sole acceptance criterion.
