# 7 Match Operations

[Return to the main contents](00_Annotation_Reviewer_User_Manual.md)

## 7.1 Purpose and data relationships

Match aligns manual Tracker trajectories with automatic detections, computes candidate identity relationships, and supports confirming, rejecting, unbinding, and ignoring them by frame or segment, producing reviewed trajectories that remain editable.

Manual trajectories provide continuous identities and approximate spatial positions, but may contain click errors, timing delays, and occasional outliers. Automatic boxes usually provide more detailed per-frame geometry, but may have fragmented tracks, identity switches, or missed detections. Matching and combining them allows complementary information to improve annotation quality. Match uses both types of information without treating every point from either as absolutely correct.

Trajectories in automatic detection CSV files come from the YOLO/tracking pipeline and usually have fields such as `track_id`, `x/y/w/h`, and `class`. Manual trajectories come from Tracker `.trk` files or converted `manual_track_file` CSV files, usually containing only point coordinates, trajectory names, roles, classes, and frame numbers. `Match` places both on the same video-frame coordinate axis and establishes bindings identifying which automatic detection ID corresponds to a segment of a manual trajectory.

The core procedure has three steps:

1. Alignment: determine the manual trajectory's frame positions and x/y offsets in the video.
2. Match preview: automatically propose bindings from manual points to automatic boxes using distance and path continuity.
3. Confirmation and application: write bindings into the current working CSV and, when needed, correct automatic trajectory positions using manual points.

| Data layer | Meaning | Equivalent to the final reviewed result? |
| --- | --- | --- |
| Raw manual points | Samples in `.trk` or manual CSV files | No; temporal/spatial alignment is still required |
| Aligned manual points | Points mapped to the video-frame axis and original-image pixel coordinates | No |
| Automatic source boxes | Boxes from the automatic annotation source, carrying source identities | No |
| Candidate | Correspondence proposed by the algorithm | No; review is still required |
| Bind result | Manually confirmed correspondence and the working rows it generates | Entered in working data, but still requires saving |
| Finalize status | A specified manual trajectory has completed review | Does not mean it has been saved to disk |

Match differs from template search in Tracking and from direct renumbering in Edit → ID. Equal numeric IDs across videos or alternative result sets must not automatically be treated as the same individual.

## 7.2 Opening manual trajectories

### 7.2.1 Importing from Boutlist

Configure Boutlist column mappings before opening a record. The program can read manual trajectory paths, Tracker capture frames, video capture frames, Tracker frame rates, start/end ranges, reverse flags, and offsets. Check the imported fields, then inspect the manual points in the image.

### 7.2.2 Importing separately

1. Open the corresponding video and automatic annotations.
2. Open the `.trk` or manual trajectory CSV.
3. Check manual frame-axis parameters and scaling information in the timing dialog.
4. After import, check manual trajectory names, classes, ranges, and initial positions.
5. Complete alignment before computing Match; increasing match tolerance is not a substitute for alignment.

## 7.3 Alignment: temporal and spatial alignment

The timeline alignment formula is:

$$
\mathrm{capture\_frame} + \mathrm{sign} \times (\mathrm{trk\_frame} - \mathrm{trk\_capture\_frame}) \times \frac{\mathrm{det\_fps}}{\mathrm{trk\_fps}}
$$

Here, `sign=-1` when `trk_reverse=True`.

Changing video Capture shifts an existing Tracker calibration reference by the Capture difference multiplied by the trk/video FPS ratio; reversed changes the sign. Prepared manual points keep their alignment. The reference may be fractional or outside the sampled source range; blank means unset. Undo/redo restores both references together. With equal frame rates, the reference changes by the same number of frames.

### 7.3.1 Parameter table

| Interface item | Meaning and units |
| --- | --- |
| Start-End range in trk | Original Tracker frame range to process; not the video Range |
| Fps of trk | Frame rate of the video used for manual tracking; maps manual frames to video frames by time ratio |
| reversed | Reverse the frame-axis mapping when the manual trajectory comes from a reversed video; check this when annotation in Tracker used a reversed video |
| Calibration frame (capture) in trk | Event reference frame on the manual timeline, used as the alignment anchor; usually the capture frame |
| align to video | Corresponding frame of the same event in the current video |
| Frame offset | Video-frame offset added to the base mapping; positive advances toward later frames |
| x/y offset | Pixel offsets of manual points in original-image coordinates; positive X is rightward and positive Y downward |
| Auto set offset | Prepare manual data again using the current timing information and estimate alignment; may overwrite existing frame/x/y offsets after a confirmation dialog |
| Preview points | Refresh the manual-point preview using current offsets; does not generate final bindings |
| Sync from / Sync to | Read relevant alignment fields from the selected Boutlist record or write them back to it |

### 7.3.2 Recommended procedure

1. Find a reference event identifiable in both video and manual trajectory, and enter its corresponding frames on both axes.
2. Check FPS, reversed, and the Tracker range.
3. Use Auto set offset when rereading/recalculation is needed, paying attention to its confirmation prompt.
4. Check synchronization of manual points with the target at the start, middle, and end of the video.
5. For a uniform shift only, change Frame offset or x/y offset and run Preview points.
6. Run Match after alignment is also correct during rapid movement.

**Example: the entire manual trajectory lags by 3 frames.** Manual points follow the target path but reach the same positions 3 frames after the image. Reduce Frame offset by 3 relative to its current value (enter `-3`), click Preview points, and inspect multiple positions.

**Example: temporal alignment error increases over time.** Check whether the FPS values agree; a fixed offset cannot correct a scaling error.

**Example: manual points are 12 px too far right and 4 px too high.** Reduce x offset by 12 relative to its current value (enter `-12`) and increase y offset by 4 (enter `4`), then use Preview points. This moves all manual points 12 px left and 4 px down; it does not translate the original automatic boxes.

## 7.4 Match and candidate preview

Match organizes candidates using aligned manual points, spatial proximity to automatic boxes, classes, and path continuity. A manual point inside a box indicates spatial compatibility, but overlapping targets can still have different identities. Candidate scores or small distances cannot replace segment-by-segment verification.

Match is a toggle button: pressing computes and displays matches; pressing again hides them while retaining explicit binding decisions. Bind, Reject, Unbind, Ignore, and related actions are unavailable while it is off; enable it and obtain a valid preview before operating. After upstream automatic boxes or alignment parameters change, check whether candidates are stale and recompute the relevant segments.

First inspect overall correspondence, then focus on target crossings, periods around occlusion, automatic ID changes, low-confidence tails, manual trajectory gaps, and video edges.

## 7.5 Involved ID, Range, and table selection

Range uses video frame numbers, such as `300-360`, including both endpoints; comma-separated intervals can be combined. Manual trajectory names and automatic IDs each serve as identities in Involved. A manual name must not be treated as an automatic integer ID.

A selected Binding-table row supplies its involved identities and **actual frame set**. Multiselection uses the union of these sets; Link selection does not expand them to an entire manual trajectory or automatic identity range. After editing Involved directly, check the scope again before execution.

| Interval type | Explanation |
| --- | --- |
| Continuous manual sampling segment | Original manual samples exist continuously on their own timeline |
| resolution gap | Empty mapped video frames caused by a manual frame rate lower than the video frame rate; not necessarily missing annotations |
| GAP | An interval with missing original manual samples, separating truly continuous segments |
| Before / After | An interval outside the first/last manual data; manual points must not be assumed to exist |

Ranges containing a resolution gap may be marked with parentheses, such as `(2-10)`. This indicates lower-frequency sampling, not a real manual click in every video frame. During binding, inspect the effective frames and results reported by the program; different gap types must not be treated as the same interpolation requirement.

## 7.6 Bind, Reject, Unbind, and Ignore

### 7.6.1 Bind

Bind accepts identity relationships within the specified range, generates final working rows, and records their consumption of automatic sources. It does more than change display colors. Class mismatch, a source already used by another identity, or an invalidated snapshot can cause conflicts, skips, or rejection. Check the actual successful range in the result message.

**Example: frames 300–360 should correspond to automatic ID 25, but the candidate is ID 33.** Select the manual trajectory and correct automatic identity, explicitly set Range to `300-360`, execute Bind, and inspect the segment and both endpoints. Clicking the correct box in the current frame alone does not establish that the entire segment has been switched.

### 7.6.2 Reject

Reject excludes the current candidate correspondence. For confirmed frames, it first removes the confirmed result; for candidate frames, it rejects that candidate. This means the correspondence is incorrect; it does not accept manual-point positions or delete all automatic source boxes. Continue finding the correct candidate or explicitly choose another treatment after rejection.

### 7.6.3 Unbind

The effect of Unbind depends on each frame's prior state. Inspect the Binding table first:

| Prior state | Result |
| --- | --- |
| Confirmed binding | Remove the confirmed result, restore consumed sources, and permit candidate review again |
| Unconfirmed automatic candidate with reliable manual geometry | Clear the automatic correspondence and create a Manual-only final result using the manual position |
| Unconfirmed Manual-only row with reliable manual geometry | Confirm that manual position as a Manual-only final result |
| True GAP with no reliable manual geometry | Do not fabricate a position; skip the corresponding frames |

Unbind therefore does not always mean reversing an operation; use Undo to reverse the preceding modification completely. Before changing automatic source ownership, Unbind confirmed segments first to avoid using the same source again for another trajectory. If another tool subsequently modified the final row, observe the conflict confirmation: restoring the source may also reverse later geometry changes.

**Example: a hornet is undetected in frames 500–520 but its manual trajectory remains reliable.** Select the unconfirmed Manual-only rows and execute Unbind to confirm this interval using manual positions, then inspect the 499/500 and 520/521 transitions. Do not use Ignore instead of adding manual positions, or repeatedly press Unbind on the same already confirmed segment.

### 7.6.4 Ignore

Ignore explicitly excludes a segment from matching/merging for the current manual trajectory. It differs from an unreviewed state. Use it for manual points clearly off-target, segments without reliable evidence, or explicitly excluded ranges. Do not ignore all missing segments merely because the algorithm currently fails to match them.

When the entire selected range is ignored, the button reads Restore; clicking restores its participation in review. A range with mixed states still shows Ignore. Restoring participation does not confirm every candidate in it.

## 7.7 Final position sources and dimensions

### 7.7.1 Position when conflicting

| Option | Result when both position types are valid |
| --- | --- |
| Detected | Use the valid automatic source box center |
| Mix | Use the arithmetic midpoint of the automatic center and manual point |
| Manual | Use the aligned manual point center |

For an automatic center (100, 80) and manual point (110, 86), these give (100, 80), (105, 83), and (110, 86), respectively. Mix is an explicit compromise rule; it does not automatically switch to Detected merely because the manual point lies inside the automatic box. Nor is it an optimal smoothing fit of the entire trajectory.

When a valid automatic source exists, its box dimensions are retained. Manual-only positions require dimension fallback, first using nearby final boxes, then class statistics or default dimensions. Such dimensions are not measurements from that frame's image.

After selecting Binding-table segments, choosing Position when conflicting updates their position policy. Completing a Transition input likewise updates the policy and records one undoable modification. Multiple segments are processed using their respective frame sets. With no segment selected, changing the drop-down does not batch-change positions throughout the video; check the scope of subsequent Bind operations.

### 7.7.2 manual_fill and actual missed detections

`manual_fill` means that a manual point can supplement the result but no acceptable automatic source box exists. It commonly occurs during occlusion, missed detections, and at image edges. Using manual positions over a long missing segment does not recover actual shapes during occlusion; retain position provenance in subsequent analysis.

**Example: a manual hornet point passes over a honeybee box.** Check the class and original hornet source first. If the original hornet box still exists, select it; do not consume the neighboring honeybee box. If the hornet detection is missing, use manual evidence and inspect transitions rather than forcibly binding the nearest automatic box.

## 7.8 Transition: switching between sources

Transition specifies the transition length at position-source-type changes within the consecutive adjacent rows generated by the operation. It defaults to 3 frames; 0 disables it. It does not cross actual missing frames or smooth the entire automatic trajectory uniformly.

When switching from Detected to manual/Mix, the last automatic point anchors a gradual approach to the new source over at most the following N frames. In the reverse direction, the first automatic point anchors adjustments over at most the preceding N frames. Missing frames or new source boundaries limit the transition range.

**Numerical example:** With N=3, last automatic X=100, and subsequent manual targets all at X=120, the first three points toward the manual source are 105, 110, and 115, followed by 120. The automatic segment itself retains automatic positions.

If one source occurs every few frames and positions differ greatly, short transitions may recur. Explicitly select more reliable source segments or use previewed geometry correction in Trajectory. Increasing Transition does not guarantee removal of all repeated jumps.

## 7.9 Checking the Binding table and timeline

Check three areas together:

1. Canvas: whether manual points, automatic source diagnostic boxes, and final working boxes represent the same target.
2. Table: whether manual names, automatic sources, actual ranges, review states, and position policies are correct.
3. Timeline: whether binding segments cover the intended interval without crossing a true GAP or entering another target's occurrence range.

Original-source diagnostics and final boxes may be visible together as a source-inspection aid; this does not justify repeatedly deleting normal sources. Hide the diagnostic layer to inspect final working results, but return to the table to confirm source relationships before saving.

## 7.10 Finalize, Reopen, and saving

### 7.10.1 Completing review

1. Select the manual trajectory to finalize.
2. Resolve pending candidates, conflicts, missing segments, and clearly abnormal geometry.
3. Inspect blocking issues listed by review diagnostics and navigate to resolve them.
4. Execute Finalize; it records that review of this trajectory is complete without writing directly to disk.
5. Play through key intervals, then Save as.

Use Reopen to continue modifying a finalized trajectory. Alignment is shared by all manual trajectories; reopen every finalized manual trajectory before changing alignment. Binding provenance and review states in saved results support later checks; do not hide conflicts by deleting metadata.

### 7.10.2 Complete example: one manual hornet trajectory corresponding to multiple automatic IDs

1. Complete temporal/spatial alignment and run Match.
2. Automatic ID 18 corresponds to the earlier segment and 25 to the segment after occlusion; check each in the Binding table.
3. Bind reliable segments, Reject clear mismatches, then select the correct source.
4. Use manual evidence for short intervals with missing automatic detections but reliable manual data, checking dimension fallback and Transition.
5. Do not forcibly treat a true GAP without reliable manual data as successful detection.
6. Check final identity continuity, same-frame uniqueness, and source-consumption conflicts.
7. Save after Finalize, reopen the result, and inspect both identity transitions.

## 7.11 Limits on interpreting results

Binding is an identity-review decision, whereas smoothing is geometric processing; neither substitutes for the other. A continuous manual identity does not guarantee a precise center, and a relatively accurate automatic box center does not guarantee a correct identity. Downstream statistics should distinguish measured, manual, mixed, and interpolated positions, selecting analysis ranges in conjunction with review states.

### 7.11.1 Checking match reliability

Inspect three types of information together:

1. Video image: whether manual points, automatic boxes, and highlighted binding symbols agree spatially.
2. Manual traj table: fields such as `matched_auto_id`, `match_status`, and distance for each manual point.
3. Progress bar/segment display: whether binding segments cover the expected range without crossing gaps that should remain separate.

Recommended principles:

- Do not blindly bind an entire segment containing gaps.
- Prioritize manual inspection when automatic match distances increase substantially.
- Do not directly merge mismatched hornet and honeybee classes unless automatic misclassification has been confirmed.
