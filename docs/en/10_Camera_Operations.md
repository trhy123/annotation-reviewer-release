# 10 Camera Operations

[Return to the main index](00_Annotation_Reviewer_User_Manual.md)

## 10.1 Purpose and Coordinates

Camera estimates relative background motion and maps images and annotations to stabilized display coordinates. Original video boxes remain stored in source-image pixels; do not write screen coordinates from the stabilized canvas directly to CSV. Expanded motion canvas extends the display area to accommodate transformed images; blank regions do not represent new image content available for annotation.

## 10.2 Manual Anchor Procedure

1. Select clear, persistently visible features on a stationary background; avoid honeybees, hornets, reflections, and moving objects.
2. Select the number of anchors and the active Anchor, use Add to create a keyframe at the reference frame, and position the corresponding background point.
3. Move to a frame where the background has shifted and set the new position of the same physical feature.
4. Enable Enable and inspect the HUD, Anchor markers, and table; play through the intervals between keyframes.
5. Use Lock to protect anchors when needed; Delete removes the selected keyframe, and Clear removes all keyframes. Check and confirm before proceeding.

A single valid anchor primarily constrains translation; more independent, well-distributed anchors can constrain richer transformations. Clustered, nearly collinear, or incorrectly tracked anchors make rotation/scale estimation unreliable. The HUD shows states before, between, and after keyframes; check that interpolation and boundary continuation match actual conditions.

Estimate uses the existing facilities to estimate motion. Verify its results against fixed background features; a target appearing stationary after compensation does not necessarily establish camera stabilization, as a moving object may have been selected as an anchor.

## 10.3 Automatic Camera Anchor Tracking

### 10.3.1 Purpose and Prerequisites

Camera Anchor tracking writes template recognition positions to the observation sequence of the selected Camera anchor for use by the existing camera motion model, image stabilization, and Expanded motion canvas. It does not generate an object Track ID or alter other individuals' annotations.

For camera motion estimation, choose a reliable feature on a stationary background as the template. Selecting a moving target introduces a target-following component into stabilization, so the compensation can no longer be interpreted as camera motion alone.

### 10.3.2 Operating Procedure

1. Select `Enable` on the Camera panel to enable Camera compensation.
2. Select the Anchor slot to track and check its position in the current frame.
3. Click `Track` to enter Tracking → Track Motion; the shared area displays `Target: Anchor N`.
4. In the template selection state that opens, click a background feature, or resample using Add Template / Alt + Shift + left-click.
5. If the existing Anchor position differs from the template center, inspect the automatically retained offset; correct it with Mark offset if necessary.
6. Adjust the template region, search region, threshold, and direction, then click Run Auto.
7. Inspect the original background feature, anchor position, and stabilized image together.
8. For manual correction, click `Correct` at the top, then click the correct Anchor position; use Resume to continue afterward.
9. Finish commits one Camera History change; Cancel restores the Camera state from before this session began.
10. Save anchor data according to the Camera saving procedure.

### 10.3.3 Differences from Object Tracking

- One selected slot is tracked at a time; complete multiple Anchors separately. The existing Camera model's anchor count rules remain unchanged.
- Identity is displayed as Anchor N; Class and Assist are not used as object detection parameters, and Assist is disabled.
- Some Camera slot management controls are locked during an active session to prevent changes to the target slot structure.
- Alt + left-click does not write object annotations; use Correct, or finish the Camera session before using object Tracking.
- Switch to Camera to inspect and use native anchor interactions; changes to the current anchor are handled by the same Camera session.
- Ctrl + Z/Y, Delete for the current point, and range deletion use session-local undo; deletion affects only observations for the corresponding frames in that slot.
- Finish/Cancel use Camera History and state recovery, preserving other slots and unmodified frames.
- Template matching still operates on the original video, preventing stabilized images from being reused as independent original observations.

Camera observations are recorded as integer source-image pixels when merged into the existing anchor structure; object Tracking x/y values can retain floating-point precision. The two use different storage systems.

Camera compensation and Scale metric calibration are separate steps. Anchor tracking supplies observations for inter-frame registration; background templates do not automatically determine centimeter scale or real planar geometry.


## 10.4 Saving and Modification Boundaries

Camera keyframes and toggles are session metadata. Disabling Enable retains anchor data for later reuse rather than clearing it. Finish in an automatic Anchor session creates one Camera history operation; Cancel restores the pre-session state. Saving CSV retains supported Camera metadata and motion information; after reloading, verify compensation direction and the reference image.

## 10.5 Camera Parameters and Anchor Table

| Control | Meaning |
| --- | --- |
| Enable | Applies camera compensation; disabling it does not clear existing keyframes |
| Anchor | Displays background anchor markers |
| HUD / HUD scale | Enables camera information and adjusts its text size; uses the same toggle as Display → HUD → Camera |
| Threshold | Pixel threshold for recording camera displacement updates |
| Number of anchors | Number of anchor slots used to describe camera motion |
| Set anchor | Selects the anchor slot currently being operated on |
| Lock | Locks the corresponding anchor interaction state to prevent accidental changes |
| Add / Delete / Clear | Adds the current keyframe, deletes the corresponding keyframe, or clears motion records; verify the scope first |
| Estimate | Estimates camera displacement from video image changes; results still require inspection |
| Track | Tracks the current background anchor using a template, with a preview before committing |

The anchor table organizes observations/changes by time. Click a column to navigate to the corresponding frame, and verify the anchor slot before editing values; deleting table selections should affect only the corresponding cells or keyframes. The model name changes with available anchors and geometry; the count selected in the dropdown alone does not guarantee a stable solution.

## 10.6 Models and Anchor Layout

A single anchor primarily supports translation; two valid, separated anchors can describe translation, rotation, and uniform scaling; more valid points can support affine or projective relationships. Concentrated or collinear anchors make complex transformations unstable. Choose clear, fixed, widely distributed background features in the same plane.

Do not use moving honeybees, hornets, swaying vegetation, or strong reflections as stationary background anchors. Camera zoom, viewpoint changes, rolling shutter, and background depth differences may not be fully explained by a single planar model.

## 10.7 Expanded motion canvas

With the expanded canvas enabled, the current original image is transformed onto a stabilized canvas that accommodates camera displacement, with background fill outside the original image. Object annotations remain stored in each frame's original image coordinates; display and point selection use the same coordinate mapping.

The expanded canvas may have different dimensions from the original video. Check resolution and visible boundaries before export; black borders are not space actually captured by the camera. Zooming/panning the view changes only observation, whereas dragging anchors changes camera registration.

## 10.8 Differences Between Estimate and Track

Estimate rapidly generates candidate camera records from overall image displacement cues and can be affected by large foreground motion; Track follows specified background templates frame by frame and supports manual takeover at failures. Both require checking that fixed background features are stable; a straighter target trajectory is not an acceptance criterion.

## 10.9 Complete Example: Slight Handheld Camera Movement

1. Choose a clear fixed marker in the target motion plane and set the first anchor reference position.
2. First test whether translation compensation with one anchor is sufficient; add distributed anchors if rotation/scaling is actually present.
3. Run Track for the current slot, set appropriate template and search regions, and click Run Auto.
4. Pause and correct manually at occlusions or errors, then confirm before continuing.
5. After Finish, enable compensation and compare fixed background positions at the start, middle, and end.
6. Enable Expanded motion canvas if greater displacement must be accommodated.
7. After stabilization, check the coordinate space and applicable range of Scale calibration.
8. Save and reload to check Camera records, compensation direction, and canvas boundaries.

## 10.10 Acceptance and Limitations

At minimum, check background stability, agreement between target boxes and images, trajectory point selection positions, first and last keyframes, a short exported clip, and the Scale display. Camera adjusts coordinate registration only; it does not correct object identity errors or restore missing video images.
