# 2 Interface and Segment-by-Segment Review

[Return to the main contents](00_Annotation_Reviewer_User_Manual.md)

## 2.1 Main Interface Areas

The playback canvas displays images and Overlay; the bottom controls handle frame stepping, playback, speed, and zoom; the progress bar shows frame position and range bands. The right-hand operation area performs editing, while the data area displays the current frame, identities, continuous segments, manual trajectories, display settings, and history. The upper-right information area summarizes the current segment and object information.

For a single selection or a selection of no more than 24 IDs, the upper-right information area displays details including identity, number of frames present, continuous ranges, and gaps. With more IDs selected simultaneously, it displays a count summary and the current active row. Simplifying the display does not reduce the actual selection range or change the targets of tables, bands, or edit operations.

Selected boxes is the total number of annotation rows for the selected automatic IDs in the current working table, counted across frames; it is neither the number of boxes on the current image nor the number of identities. Tracking points not yet committed with Finish are excluded from the working-table row count. Statistics are cached by data revision and selected identities; changing frames does not rescan the entire table.

The current frame, selected IDs, selected table rows, operation Range, entire trajectory, and analysis Start–End are different ranges. Before modifying data, check both ID and Range in the operation area. Display controls visibility and does not delete hidden data.

Hovering over an input field shows its current contents; after expanding a drop-down list, hovering shows the complete contents of the item, including long paths. Fields or presets with dedicated explanations append them after the contents. Operational explanations appear on the relevant label or button rather than replacing each drop-down item's tooltip with a generic explanation.

## 2.2 Current frame

This table lists annotations for the current frame. Row selection is linked to boxes on the canvas; when overlapping boxes are difficult to select directly, use the table to confirm class, ID, center, and dimensions. Ctrl + click retains its multiple-selection function; Alt + canvas click is used for Tracking and must not be treated as ordinary multiple selection.

**Procedure:** Pause the video → select the target on the canvas or in the table → check ID/class → inspect the corresponding position → switch to the required operation panel. When boxes overlap, do not identify them solely by box color.

## 2.3 IDs and Selected ID

Tables support Shift for continuous range selection, Ctrl for adding/removing individual items, and Ctrl + A for selecting all. On the IDs page, Ctrl + A selects only the class table that currently has focus, excluding other class tables; when filtering is enabled, hidden identities are not automatically included. All IDs in the shared Edit area explicitly selects all identities; input-field display width or text truncation must not limit the actual edit targets. Selecting multiple items retains the current scroll position; single-item navigation centers the row according to the current sort order. The actual data row highlighted for the current frame also serves as the table selection and starting point for Shift selection.

When adding to a selection with Ctrl or Shift click, navigation follows the identity clicked this time: if its range already includes the current frame, the frame remains unchanged; otherwise, the nearest frame where it appears is shown, retaining other selected items. Ctrl-clicking to deselect a row does not navigate to that row again. Large selections are collected in batches, with progress shown in the status bar; press Esc before completion to cancel, retain the last effective selection, and leave annotations and Tracking unchanged. If data, filtering, or sorting changes during collection, obsolete tasks are canceled to avoid selecting incorrect identities using old displayed row numbers.

IDs class groups and manual class options are defined by the INI classes and id_groups groups; see [Settings and Performance](14_Settings_and_Performance.md) for general configuration operations.

IDs provides an overview of each identity in the current data; the `x` and `y` columns are to the left of `frame`. Selected ID focuses on the selected identity and its continuous appearance segments, helping locate each segment's endpoints and gaps. Actual missing frames split continuous segments; the same numerical ID does not guarantee that the entire segment correctly represents one real target.

Row-by-row annotation tables such as Current frame and Selected ID omit repeated video-name or path columns. Video association is project-level information; loaded files can still be checked on the File page when selecting an annotation source.

The x and y columns in the IDs table display the pixel-coordinate ranges of that identity's annotation centers in the source image, in “minimum, maximum” format. For example, x=`120, 450` means the center's horizontal coordinate in the displayed records ranges from 120 to 450 pixels, excluding box width. Invalid or nonfinite coordinates are excluded from statistics; when filtering is enabled, calculations use the filtered records.

| Operation | Purpose |
| --- | --- |
| Select an ID | Displays and reviews rows and ranges for that identity |
| Segment start/end | Quickly inspects the two endpoints before and after missing data |
| Previous/next continuous segment | Checks reappearance, broken tracks, or identity changes |
| Next gap | Finds intervals requiring interpolation or retracking |
| Linked canvas and table | Confirms the source and identity currently being viewed |

**Example: a stationary honeybee is temporarily missed.** In Selected ID, seek to the last frame before disappearance and note the image position; step forward to check whether it reappears at the same position under a new ID. If necessary, use Over time spatial selection in Edit → Box to find identities that have appeared at this position, then merge them with Edit → ID.

## 2.4 Manual traj and Binding Tables

Manual trajectories use trajectory names and manually sampled points; automatic annotations use numerical IDs. Their frame coordinates are comparable only after alignment through Match.

The appearance range in Manual traj may contain resolution gaps caused by low-rate sampling; these differ from GAPs caused by actual missing manual samples. The Binding table organizes identity relationships by segment. Selecting a Binding row uses that row's actual frame set; multiple selection uses the union rather than expanding to all frames of an entire identity.

Cross-check table rows, timeline bands, and canvas diagnostic layers: the appearance of an automatic ID value in a Binding row does not mean its entire time range is bound. See [Match](07_Match_Operations.md) for the complete workflow.

## 2.5 Progress Bar, Bands, and Hovering

The current progress position is used for playback/frame stepping. Yellow identity bands indicate the appearance ranges of selected identities; gaps correspond to continuous segments in the table. Each identity's yellow band has opacity 0.6, so overlapping portions where multiple selected identities coexist appear darker.

| Type | When Enabled | Band Appearance and Purpose |
| --- | --- | --- |
| Selected ID | Global | Thin yellow bands indicating selected identities' appearance ranges, with gaps corresponding to track interruptions |
| Change position | Box page or continuous editing session | Green, indicating frame segments added/staged in this operation |
| Tracking | Tracking page | Added range in green; Delete selection range in black, portions with actual annotations pending deletion in red; original identity range remains yellow |
| Merge ID | ID page | Target blue, Source green, same-frame overlap red; Find candidates use opaque cyclic-color bands underneath, with candidate ID numbers in identity colors. When both coexist, original Merge bands are above with opacity 0.67, and red overlap bands are drawn last |
| Staged record | Staging window open with a record selected | Black at opacity 0.3, indicating that record's staged range; updates when another record is selected |
| Swap preview | Swap page | Changed orange; Position Uncertain purple; uncertain frames are skipped by default on commitment |
| Trajectory | Trajectory page | Orange, indicating the currently editable trajectory range, matching Preview colors |
| Match comparison | Match page | Automatic annotations pale blue, manual trajectories pale green, overlap pale red; compares the appearance ranges of both sources |
| Binding candidates | Single manual identity selected or binding bands set to always display | Cyclic-color bands numbered by binding segment; adjacent segments in the same group are not numbered repeatedly |
| Binding verification | Single manual identity selected or binding bands set to always display | Confirmed bright green, Confirmed · Modified dark green, Stale / Conflict red; above candidate bands |
| Events | Events page | Uses the colors and band rows configured per type in Event types; no band is drawn when Band is off |
| Video export time range | File page | Red, indicating Export Range; the current video's preview range remains after Export settings closes |
| Detection postprocessing preview | During Raw / Postprocess preview | Raw coverage blue, postprocessed result range green, manually modified frames brown-red, completed computation pale green; selected range yellow |

Merge Target / Source inputs in Edit → ID also immediately add thick blue/green outlines to the corresponding boxes, hidden after switching to another subpage. The candidate result window centers on the current frame, using yellow numbered cells or gap lines for positioning; changing frames retains the manual single or multiple selection. Row backgrounds and candidate bands use cyclic colors, while candidate ID numbers in the table and beside bands use assigned identity colors. Only checked Use boxes determine which candidates populate Source; selection or navigation does not mean a merge has occurred.

All text and point markers are drawn above all bands; text retains the relative layer ordering of its corresponding bands. Staging bands indicate only the selected draft's range; they do not automatically become the shared Range or modify data. Different purposes may occupy different heights; interpret them using the current page, numerical labels, and the table above.

### 2.5.1 Free Seeking and Marker Selection

The progress bar area supports free seeking: click to seek by horizontal coordinate or hold the left button and drag for continuous preview. Once dragging begins in the progress bar area, it continues as ordinary dragging even if the pointer moves to the marker area below or outside the control, seeking to the final position on release. One drag creates only one browsing record from its start to its endpoint.

The marker area below the progress bar selects visible bands and markers rather than supporting free dragging. Selectable items include yellow identity ranges, Merge ID, Match, Binding / Review, Tracking addition and deletion previews, Trajectory editing intervals, and event intervals. Camera Anchor “+” markers, the Capture arrow, and analysis start/end symbols can be clicked directly to seek to their marked frames. Hidden or cleared bands are not selectable.

Start and End symbols are still drawn on the progress bar, but the positions directly below them at the Capture arrow's height also accept marker selection. Clicking these corresponding positions seeks to the exact Start or End frame; hits in the area below a symbol take priority over range bands at the same position. The progress bar area continues to seek freely by horizontal coordinate.

Bands are hit-tested by row, with approximately 8 logical pixels of tolerance above and below the line. When multiple rows are nearby, the nearest row takes priority; when bands overlap at the same position, the topmost displayed band takes priority. Clicking inside a band seeks by horizontal coordinate without snapping to endpoints. Very short bands widened for visibility still restrict seeking results to their actual frame intervals.

When clicking outside a band, the horizontal snap range adjusts automatically according to spacing between nearby selectable targets: isolated endpoints or point markers allow up to 48 logical pixels; densely spaced targets reduce this to half the neighboring spacing, with a minimum of approximately 12 logical pixels. Within a short gap, the nearest boundary is selected; ties favor the boundary closer to the current frame, then the earlier frame if still tied. The hover tooltip shows the frame number that will be selected. Logical pixels are converted with system display scaling, requiring no setting adjustment.

Marker-area selection determines the target on press and commits that target on release; changing the release position does not seek outside the band. Distant blank areas neither change frames nor create browsing records; pressing in a blank area and then moving onto a track or band does not start dragging. Seeking uses the existing precise frame-stepping mechanism and retains playback intent and pending edits; manual seeking pauses Auto Tracking.

**Example: locating a broken-track boundary.** An ID appears in frames 100–200 and 220–300. Clicking inside the second segment seeks to the corresponding frame. Clicking in the short gap between segments, when a nearby boundary lies within the current snap range, seeks to frame 200 or 220, whichever is closer to the click. To inspect an unannotated frame in the middle of the gap, click the progress bar area or enter its frame number.

### 2.5.2 Hovering Over and Selecting Image Trajectories

When trajectory picking is enabled, a selectable point near the pointer shows an approximately 10 px ring and `class ID (frame)`. The ring uses the ID color, text uses the actual trail color at that point, and the progress bar marks the corresponding frame. Clicking seeks to that frame only if the hovered point belongs to a visible continuous trajectory.

Undisplayed trajectory points can still be identified by hovering but cannot be clicked to navigate. Points whose trail is disabled, filtered by display range or length, or isolated without a displayable adjacent segment provide hover feedback only. They become selectable after their corresponding segments are displayed; use the progress bar or enter a frame number to seek to a hidden point.

Hold Ctrl to temporarily suspend trajectory hovering and picking on the image and clear the rings, text, and progress-bar markers generated by trajectory hovering. After release, suspension continues for 3 seconds before restoring the original Pick trail setting; pressing and releasing Ctrl again during this interval restarts the timer. Picking that was originally disabled is not enabled as a result. This does not rewrite display settings; Ctrl + click multiple selection and Ctrl + wheel zoom continue to follow their original rules.

before/after picking and All constrain the time range for both hover preview and click navigation. Clicking accepts only the point corresponding to the current hover preview that belongs to an actually visible continuous trail; points outside the range without hover previews cannot be clicked, nor can points in a disabled trail direction or beyond its displayed length or Frame range. When multiple candidates lie within 12 logical pixels of the pointer, the point with the frame number closest to the current frame takes priority, followed by screen distance. The click target matches the hover preview; if the hovered point cannot be clicked, another nearby point is not substituted.

Pick progress bar marks the selected trajectory point under the cursor on the progress bar. It does not require the corresponding trail to be displayed and is not limited by Trail before / Trail after lengths or Frame range; its range follows picking's own Before / After or All settings. Tied candidates favor the currently active identity.

## 2.6 Box and Text Display

| Setting | Operational Effect |
| --- | --- |
| Box / Point | Presents rectangles or center points; does not change stored W/H |
| Line width, point diameter, fill, opacity | Changes display clarity; excessive values may obscure the target |
| IDs / Confidence | Displays identity or available confidence; detection confidence differs from the Tracking match Score |
| While playing | Controls whether corresponding labels remain visible during playback, balancing readability and speed |
| ID font size, weight, outline | Adapts text to light and dark backgrounds |
| ID colors, uniform color, avoidance colors | Distinguishes identities or improves contrast; color is not the identity record itself |

The pending Tracking box in the current frame has two diagonals `⊠` to distinguish it from ordinary committed boxes and show its center. Its appearance on the image does not mean Finish or saving to disk has been completed.

## 2.7 HUD Display

HUD displays information above the image. Frame, Scale, Counts, Events, and Camera control frame numbers, the scale bar, class counts, event text, and camera keyframes/motion hints, respectively. Each type occupies its own settings row and can be enabled independently, positioned, assigned a text color with Font, given a Size, assigned an outline color with Outline, and given an Outline thickness; thickness 0 disables the outline. HUD fonts are independent of target ID fonts.

The position input format is `horizontal, vertical, priority`, for example `L, B, 2`. Horizontal values are L (left), C (center), R (right); vertical values are T (top), M (middle), B (bottom). Items at the same position are ordered by ascending priority: smaller values in T/B lie closer to the top/bottom edge; smaller values in M lie closer to the image center, with subsequent items extending above and below. Equal priorities follow settings-row order. Spacing is reserved between items; Events or Camera with no content occupy no layout position. Invalid position input reverts to the last valid value when editing ends.

The default font size for Frame, Scale, Counts, and camera keyframes is 25; Events defaults to 17. Size in the Camera row controls keyframe font size; Cam beside the arrow uses 40% of that value, defaulting to 10. Scale defaults to bottom left priority 1, Frame to bottom left 2, and Events to bottom left 3; Counts defaults to bottom right 1 and Camera to bottom right 2. For example, setting Frame to `C, T, 1` displays the frame number at the top center; setting Events to `C, T, 2` displays active event text below it.

Changes are previewed immediately; the HUD or All scope in Save settings saves them to settings.ini. Video export uses the same types, font sizes, colors, and outlines. Disabling Events also hides Start, End, and Capture text on the image, without clearing actual point markers or event records.

## 2.8 Axis and Metric grid

Axis provides displayed coordinate axes; its origin can reference Hive or specified coordinates. Changing the origin does not move all objects in the CSV to a new origin.

Metric grid draws a grid with physical spacing according to Scale calibration. Grid spacing, appearance, and anchors affect presentation; the Scale type determines whether spacing is uniform or convergent in pixel space. Without sufficient two-dimensional constraints, the grid cannot be interpreted as a measured complete planar perspective relationship.

**Example: an obliquely filmed wall.** Grid intervals representing the same 1 cm may appear narrower in the distance and wider nearby. First check the model and constraints in Scale, then inspect their plausibility using the grid; do not enter unknown real angles merely to make the grid “look square”.

## 2.9 Trail before and Trail after

### 2.9.1 Length and Object Scope

before means before the current frame, and after means after it. Frames specifies the number of displayed frames; All uses the entire available range in the corresponding direction. Always trail IDs can keep specified identities displayed; Pin adds selected identities, and Clear removes the corresponding pinned items. Pinning affects only the image display.

Frame range on the line above Always trail IDs limits the actual frames allowed for that direction; blank means unrestricted. Enter a single frame, interval, or multiple comma-separated intervals, for example `100-300, 500-800`, including both endpoints. This intersects with the before/after length limit relative to the current frame, also constrains Simple trail, and does not connect trajectories across separate intervals. It applies to selected/pinned identities, manual trajectories, pending Tracking trajectories, trajectory picking, and video export, without deleting annotations. After editing, leave the field to apply the display change; Save settings saves it to the corresponding Trail before / Trail after group. Incomplete syntax does not display the entire trajectory; correct or clear it to restore display.

Far at, beside Frame range, controls the gradient scale without limiting visibility. Leave it blank for Auto: use the numeric Frames value when All is off; with All on, use the farthest frame distance across this group's displayed identities and manual trajectories within the allowed ranges. Before and After are calculated separately; every identity in one group shares its scale, so a long trajectory compresses shorter trajectories' gradients and equal frame distances remain comparable. Enter a positive integer N to reach the far color, opacity and width N frames from the current frame; beyond N the far appearance stays constant. Far at is disabled when the direction is off or Simple is enabled, and remains available in either All or Frames mode. It is saved with the other Display settings and used consistently in preview, hover and export.

### 2.9.2 Appearance Parameters

| Parameter | Meaning |
| --- | --- |
| Simple trail | Uses a uniform appearance, suitable for inspecting long-segment outlines |
| Gradient start/end colors | Control colors near the current frame and at the far end, respectively |
| Start/end alpha | Near/far opacity, with 0 transparent and 255 opaque |
| Start/end width | Displayed line width near the current frame and at the far end |
| ID colors / unique colors | Uses identity colors or one custom color |
| far HSV | Adjusts saturation and brightness of the far-end color |
| Style | Solid, dashed, dotted, and wavy lines. Trail After defaults to dotted; selecting solid displays a solid line. Styles do not change trajectory coordinates |

Gradients help identify movement direction and temporal order; they are not numerical speed maps. A connecting line does not prove that every intervening frame contains a real detection; inspect actual rows and source fields.

### 2.9.3 Example: Locating a Brief ID Switch

1. Pause, select the target, and enable before/after trails of appropriate lengths.
2. Hover along the anomalous spike, read its frame number, and click to seek.
3. Inspect images frame by frame before and after the anomaly to distinguish a position error from an identity swap.
4. Repair position errors with Tracking/Trajectory and identity swaps with Swap or Match.
5. After repair, play the transition segments on both sides and check actual boxes and trajectory sources.

## 2.10 Review Order and Acceptance

First confirm video–annotation synchronization, then check identity, then position and geometry. For each key trajectory, inspect its starting point, continuous segments, gaps, crossings/occlusions, and endpoint in order. Hidden displays, consistent colors, and smooth lines cannot replace data-correctness checks.

Finally confirm that the selected and executed ranges agree; missing segments have been explained or filled; identities are not duplicated in the same frame; interpolation and manual estimates retain their sources; and verification statuses reflect the actual checks performed.

## 2.11 Filter: Conditional Filtering and Preview in Existing Tables

### 2.11.1 Entry Point, Data Sources, and Scope

Filter is located between Edit and Tracking. Set conditions in this panel and view results in Current frame, IDs, and Selected ID, without opening a separate filter window that obscures tables.

When filtering has completed and actually removes some contents from a table, that table's column headings turn green, `RGB(0,175,0)`. Tables evaluate this independently: for example, if only honeybee records decrease, the honeybee table in IDs turns green while the unaffected hornet table retains its original color. IDs is considered affected even if identity rows remain unchanged but their appearance ranges or counts decrease. Current frame evaluates the current-frame projection, Selected ID the current active identity; manual trajectory tables follow the same rules.

| Control | Actual Behavior |
| --- | --- |
| Enable filter | Enables/disables table preview of applied conditions; does not delete data |
| Annotations | Queries annotation rows in the current formal working table, including committed manual corrections and interpolation |
| Manual points | Queries sampled points in imported manual trajectories, keeping them distinct from automatic IDs with the same number |
| Both | Queries both sources above |
| All records | Uses the complete source range |
| Current frame | Freezes the query scope at the current frame when Apply is clicked; subsequent playback does not change it |
| Selected IDs | Freezes the identity scope to automatic IDs and manual trajectory names selected when Apply is clicked |
| Kept only | Excludes records with analysis_keep=0; unchecked includes those records |
| Apply | Applies conditions in the background and accepts results consistent with the current data version |
| Clear | Disables filtering and releases the exact-record editing scope while retaining the condition draft for reuse |

An asterisk after Filter indicates that a query is enabled. The status line shows matching row count, total rows in scope, and identity count; hover to read the full text. Query results require recalculation after changes to data, manual alignment, calibration, or the camera model. While calculation is pending or a query error exists, tables show their original current views, headings retain their original colors, and Use matched rows and Select IDs are unavailable; these rows are not valid filtered results. Correct the issue indicated by the status line and Apply, or use Clear.

Current frame displays the intersection of the current frame and filtered results; IDs summarizes identities represented by matching records; Selected ID displays the intersection of the current identity and filtered results. True GAPs in Selected ID are still determined from the complete source trajectory; frames hidden by filtering must not be interpreted as actual missed detections. Filtering alone does not delete boxes on the image or original data.

### 2.11.2 Rows Conditions and All / Any Groups

The Rows Field menu includes actual public columns in the current data, Record type, and derived motion metrics; custom columns can participate directly in filtering. Internal transaction fields are not listed as ordinary table columns. If a column referenced by an existing condition is absent from a new file, Apply reports it unavailable rather than silently ignoring the condition.

The Field drop-down can expand wide enough to read complete field names. Value is an editable drop-down that lists distinct existing values from the current column when expanded; numbers, text, or set expressions can also be entered directly. With valid filtered results, suggested Rows values come from matched records, and suggested IDs values from the corresponding statistics. Derived values not yet calculated provide no suggestions but can still be entered manually. Expanding a list does not replace entered contents.

1. Click + Condition to add a condition, select Field and Operator, and enter Value.
2. between / outside also requires To; other operators do not read this field.
3. All requires the same record to satisfy every enabled condition; Any accepts any enabled condition.
4. Click + Group to create an independent All / Any group, select it, and add child conditions.
5. Uncheck Use to disable a condition or entire group; × deletes the current condition or group.
6. Click Apply to update the preview. Ordinary input changes do not immediately query or modify annotations. Ordinary conditions with all inputs required by the current operator empty are ignored as incomplete drafts, as are empty groups; an old To value unused by the current operator does not reactivate an empty condition. is missing, is not missing, is true, and is false remain valid. Clearing or deleting all conditions of an enabled query automatically redisplays unconditional results for the current source and scope. between / outside with only one boundary still requires completion; invalid numbers are not treated as zero.

The Find in table input and Find button to the right of the Rows / IDs tabs perform text searches; Enter also executes the search. Rows searches the current Current frame table or open Selected ID table; IDs searches identity summary tables. Matching uses case-insensitive substring comparison against displayed column text, selects and centers the matching row, and finds subsequent rows cyclically on repeated execution. Searching retains existing filtering limits and does not expand to frames or records absent from the current table or modify annotations.

| Operator Category | Operators and Input Rules |
| --- | --- |
| Equality and sets | equals, not equals, in, not in; sets are comma-separated, and text values containing commas require quotes |
| Text | contains, not contains, starts with, ends with; literal, case-sensitive comparison without regular expressions |
| Numeric | >, >=, <, <=, between, outside; requires finite numbers; ordinary intervals include boundaries |
| Missing values | is missing, is not missing; does not read Value |
| Boolean | is true, is false; supports common Boolean and 0 / 1 representations; missing values do not match false |

Local direction and Segment direction intervals can cross 0°. For example, between 350 and 10 means directions near rightward rather than the large 10–350° interval. Undefined values do not pass ordinary numeric comparisons; use is missing to inspect such records.

**Example: locating falling interpolation and anomalously low boxes.** In Rows, set `source equals drop_interp` and `y > 600`, with All for the root group. Only records satisfying both conditions simultaneously match; an ID with drop_interp in one frame and y>600 in another does not necessarily have a record satisfying both. Older segments already changed to interp are not inferred back to drop_interp.

### 2.11.3 IDs Statistics and Second-Stage Conditions

In the IDs data table, Frames is the number of distinct frame numbers, and Interpolated frames is the number of distinct frame numbers identified as interpolated. Duplicate boxes in the same frame do not increase either count; these counts are not last frame minus first frame plus one. Interpolation identification reads interpolation sources in source, state, and position_source, Trajectory curve_fill, and explicit interpolated, is_interpolated, and manual_input_interpolated flags, rather than treating every detected=0 record as interpolated.

Filter → IDs conditions run after Rows conditions. Frames, Interpolated frames, Interpolation %, Maximum speed, and Median speed are all calculated from rows matched in the previous stage, then determine which identities to retain. Identities from the two sources are summarized separately.

**Example: inspecting only IDs with longer falling interpolation segments.** Set Rows to `source equals drop_interp` and IDs to `Frames >= 10`. This means at least 10 distinct frames satisfy the Rows condition; it does not mean the ID's complete trajectory is at least 10 frames long. Adding `frame between 1000 and 2000` first restricts statistics to matched records within that range.

### 2.11.4 Motion Measurement Settings and Definitions

Metrics… sets the measurement window, units, coordinate space, and whether interpolated points are included, then applies the query after confirmation. Window (frames)=1 uses original coordinates; larger values apply a centered moving average to coordinates within the same continuous segment for measurement only, without rewriting the actual trajectory. The window is determined by video frame span and does not mistake manual sampling intervals for one frame.

Source uses original-image coordinates; Camera uses coordinates after existing camera stabilization transforms, requiring Camera motion to be enabled and usable anchor observations or loaded camera transforms. px denotes pixel units; cm requires valid Scale calibration in the same space as the measurement. Local direction uses 0° to the right and 90° upward, distinct from the downward-positive Y direction of stored original-image coordinates.

Local measurements calculate numerical derivatives from coordinates at distinct frame times, using consecutive decoded frame numbers divided by nominal FPS; container PTS gaps are not interpreted as extra images. Automatic annotations are segmented by consecutive frames; manual samples allow their regular sampling intervals, with gaps substantially exceeding those intervals starting new segments. Missing coordinates, duplicate observations for the same identity/frame, and excluded interpolated/non-kept records cannot serve as reliable derivative samples.

| Metric | Definition, Units, and Limits |
| --- | --- |
| Speed | Magnitude of the velocity vector, px/s or cm/s |
| Acceleration magnitude | Magnitude of the velocity vector's derivative, px/s² or cm/s² |
| Acceleration X / Y | Acceleration components, positive rightward for X and upward for Y |
| Tangential acceleration | Time derivative of speed; positive for speeding up and negative for slowing down |
| Local direction | Current local velocity direction, 0–360°; undefined at zero speed |
| Segment direction | Direction of net displacement from segment start to end; undefined for closed segments or near-zero net displacement |
| Segment displacement | Straight-line distance from segment start to end, px or cm |
| Segment path length | Sum of path lengths between adjacent valid positions within the continuous segment, without bridging gaps |
| Segment tortuosity | Path length / net displacement; undefined for near-zero net displacement |
| Turning angle | Absolute change in direction between two consecutive displacements, 0–180°; undefined at segment endpoints and adjacent to stationary positions |
| Curvature | Local planar curvature, 1/px or 1/cm; undefined at zero speed or with insufficient sampling |
| Segment mean speed | Path length / continuous-segment duration, px/s or cm/s |

A one-point segment cannot provide local motion; a two-point segment can measure displacement and speed but cannot provide reliable acceleration or curvature. Measurement smoothing reduces spike effects but also attenuates real sharp turns and brief acceleration, so verify against images.

Motion metrics are calculated on complete continuous source segments before applying Rows, frame, and identity-scope conditions. Thus, `frame between 100 and 200` does not redefine the complete segment's Segment path length or Segment direction as geometry for frames 100–200. Maximum speed / Median speed instead aggregate local Speed over matched rows. Do not conflate the scope meanings of different metrics.

**Example: locating box jumps.** Use Source, px, and Window=1, set Rows to `Speed > 800`, inspect matching frames in Current frame and Selected ID, then play the surrounding segments. If original-image movement mainly comes from the camera, first enable Camera and select Camera coordinates before checking again; camera displacement must not be interpreted directly as target speed.

### 2.11.5 Exact-Record Editing and Whole-Identity Selection

Enabling filtering changes only the preview. Use matched rows and Select IDs have different meanings:

| Action | Scope of Subsequent Changes |
| --- | --- |
| Use matched rows | Freezes matching automatic row UIDs and manual sample-point identities; Delete and Change class affect only these records that still exist |
| Select IDs | Selects the complete identities represented by matched results and releases the exact-record scope; subsequent operations use ordinary ID / Range rules |

Use matched rows remains pressed and displays the frozen count. Both the shared D and Box → Delete use this exact scope; other Edit tools require its release first to prevent interpolation, merging, or position additions from misusing filtered records. Click Use matched rows again, Clear, or Select IDs, or directly edit the shared ID / Range to release this scope. Records absent after deletion are not recreated; Apply again to obtain a new matching set.

**Exact-scope example:** A query matches only ID 1 at frame 100 and ID 2 at frame 200. After Use matched rows, Delete removes only these two records, excluding ID 1 at frame 200, ID 2 at frame 100, or another unmatched duplicate box in the same frame. Matching manual points are also located by name, aligned frame, and sample-point index rather than expanding the operation to the whole name.

One exact deletion or class change is committed as one operation and can be undone/redone through the main History; when automatic and manual sources are mixed, one undo restores both. Filter conditions, preview changes, and browsing actions themselves do not enter annotation History. Conditions and exact scopes apply only within the current application session and do not change the SQLite schema.
