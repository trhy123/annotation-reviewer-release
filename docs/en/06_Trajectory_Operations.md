# 6 Trajectory Operations

[Return to the main contents](00_Annotation_Reviewer_User_Manual.md)

## 6.1 Shared trajectory tools: scope and preview

### 6.1.1 Access and modes

Open `Edit → Trajectory`, between the Swap and Scale subtabs. Modes appear in this order: `Edit`, `Draw`, `Smooth`, `Redistribute`, `Transform`.

| Mode | Changes | Typical use |
| --- | --- | --- |
| Edit | Change local shape through anchors and handles | Correct sharp turns or adjust individual curve segments |
| Draw | Redefine the selected segment's path with a mouse stroke | Redraw a curved route when much of the original path is displaced |
| Smooth | Reduce position jitter using a local algorithm | Remove spikes and smooth continuous small-amplitude noise |
| Redistribute | Change the position assigned to each frame along the current path | Apply assumptions of uniform speed, acceleration/deceleration, or slowing at turns |
| Transform | Apply an overall geometric transformation to center coordinates | Translate, scale, or rotate an entire segment |

### 6.1.2 Selecting an identity and frame interval

1. Select the target ID in the shared Edit ID field. Preview is unavailable without an ID; this operation does not merge other IDs.
2. With `Set` pressed, navigate to the start and click `A:`, then navigate to the end and click `B:`. Both frame numbers can also be entered directly.
3. With `Set` released, clicking `A:` or `B:` navigates to the stored endpoint without changing its input value.
4. Inspect the orange range strip and click `Preview` to create a preview.

A and B are both included, regardless of order. A = 300 and B = 200 selects 200–300. The fields are initially empty; a local-range preview requires both endpoints. Check **All frames** in the shared Edit area to use the entire selected ID. Press **<500>** to use a window extending 500 frames before and after the current frame; this overrides All frames. Turning it off restores the original A/B or All frames scope. Setting endpoints or switching modes does not automatically enter editing.

**<500>** is independent of ID and A/B inputs and can always be enabled or resized; creating a Preview still requires a selected ID. Double-click the button quickly to turn it into an integer field. Enter a positive integer and press Enter or move focus away to update its label, for example <1000>. Esc abandons the value change. With the window enabled, changing its frame count or navigating to a new frame immediately updates the orange range strip, without first entering Preview or pressing Set again.

When the window changes during a preview, completed changes outside it are retained; Apply commits them together and Discard discards them together. Changing the window does not automatically reapply Smooth, Redistribute, or Transform parameters. Adjust the relevant parameters again to affect the new range. A window without trajectory points displays an empty preview while retaining existing uncommitted changes.

The range must contain at least two existing positions to create a preview. Extending the range into empty frames does not automatically create positions beyond the first/last observation. After changing the selected ID, check endpoints again to avoid reusing the previous target's range.

### 6.1.3 Preview, live calculation, and commit

Every mode requires an explicit Preview action to begin. During a preview, the button reads Discard and remains pressed; Apply is enabled and highlighted. On exit, the button returns to Preview and Apply loses its highlight and is disabled. Merely setting endpoints, switching tools, or changing parameters outside a preview does not start editing. In an active preview, parameter changes are briefly coalesced and computed in the background; Apply is temporarily unavailable during computation.

The gray line represents the original trajectory; the orange line and per-frame triangles represent the preview. Triangle direction follows increasing frame order. The current frame's preview point has an orange ring. Hovering over a preview segment shows its frame number and an orange ring, with a corresponding progress-bar position. This feedback is independent of Display's Trajectory picking switch and range settings. Original-trajectory hover feedback can still appear, with orange preview feedback drawn above it.

Hovering over an existing preview frame on the progress bar also displays feedback at that frame's modified position, without requiring Pick progress bar. Missing frames do not display nonexistent preview points.

Except in Draw, double-click a position on a preview segment to navigate to the corresponding existing frame while retaining the preview. During a preview, the original trajectory provides hover feedback only and does not take over click-to-navigate or selection. Draw double-clicks do not perform this navigation, preserving drawing interactions. The status bar shows frame count, control-point count, and displacement statistics. Maximum/RMS displacement measures geometric difference from this preview's original input, rather than an empirically measured localization error.

- `Apply`: write results to working data as one History edit.
- `Discard`: discard the current preview while retaining previously uncommitted Tracking points.
- Enter in the image: apply the curve preview.
- Esc in the image: discard the curve preview.
- Ctrl + Z / Ctrl + Y: undo/redo incrementally within the current preview.

While a curve preview exists, operations requiring a commit, such as Tracking Finish and saving, are blocked until Apply or Discard. Right-clicking the image still invokes Tracking Finish and cannot replace curve Apply.

A/B and curve type are locked during an Edit preview; use Discard or Apply before reselecting them. In other modes, changing A/B, switching window mode, or changing All frames discards the unapplied preview and requires Preview again. With window mode already enabled, frame navigation or radius changes retain the preview and local undo records. Clearing the shared ID field also exits and discards the preview. Switching tools can reuse the active preview shape, but check that this is intended. Repeated adjustment of the same parameters uses the baseline before the current fitting round, rather than simply accumulating every recalculation.

### 6.1.4 Frame count, dimensions, and boundaries

Except for Edit's Fill gaps, trajectory tools preserve the existing set of frame numbers and do not automatically generate all missing frames. Ordinary edits retain the original ID, class, and per-frame W/H. Transform scaling also scales only the center path, without proportionally enlarging annotation boxes.

On commit, boxes are constrained to the original video boundaries. Near an edge, the final center may be adjusted so that the original W/H fits entirely inside the image. Dragging a preview outside the original image does not mean annotations can be saved in the expanded blank region.

When pending Tracking points participate in the preview, Apply commits the Tracking session first and the curve modification second, producing two History edits. One global Undo reverses only the curve modification; the next reverses the preceding tracking segment.

## 6.2 Editing trajectory shape with Edit

### 6.2.1 Parameters and control points

| Control | Function |
| --- | --- |
| `Bezier / Polyline` | Use a cubic Bézier curve or a polyline between adjacent anchors |
| Anchor drop-down, with entries such as `F2301` | Select the control anchor for the corresponding frame |
| `Corner` | Make the two direction handles independent, allowing corners or discontinuous directions |
| `Smooth` | Keep the opposite handle collinear and oppositely directed when one is dragged, preserving its original length |
| `Lock` | Lock the selected anchor to protect its position and control operations |
| `Keep timing` | Assign curve parameters according to frame order between adjacent control anchors |
| `Project ordered` | Fit original points to the edited curve while preventing frame order from reversing |
| `Fill gaps` | Fill missing frames between existing positions when creating the preview |
| `Add` | Add a control anchor at the current video frame without adding an extra video-frame record |
| `Remove` | Remove the selected internal control anchor, connect its neighboring anchors, and redistribute existing frame positions in that segment without referring to the removed control point or deleting its frame record; Bezier smooths using the outer tangents, while Polyline retains a polyline connection |

### 6.2.2 Procedure for local curve changes

1. Select a range between reliable endpoints and choose Edit and Bezier.
2. Click Preview. The initial preview retains original per-frame positions instead of replacing the entire segment with a straight endpoint-to-endpoint line.
3. At a direction change, drag an existing square anchor, or drag an intermediate curve position directly to create an anchor for that frame.
4. Select the anchor and adjust its circular handles to control incoming/outgoing tangent directions and curvature.
5. Use Corner to control each side independently at sharp turns, or Smooth for continuous rounded turns.
6. Check Lock for reliable positions that must remain fixed.
7. Inspect the orange preview points frame by frame against the target's positions, then Apply.

Each drag is one local undo step. Endpoints and locked anchors cannot be removed, although unlocked endpoints can be dragged explicitly. Remove directly connects neighboring anchors without retaining the removed anchor's original curved path; Ctrl + Z restores the original shape. Removing a control point does not delete that frame's annotation; use Tracking Delete to delete annotations.

### 6.2.3 Curve and timing principles

Adjacent anchors `P₀` and `P₃`, with their outgoing/incoming handles `P₁` and `P₂`, define the curve:

$$
B(t) = (1-t)^3P_0 + 3(1-t)^2tP_1 + 3(1-t)t^2P_2 + t^3P_3
$$

Keep timing maps frame positions between adjacent anchors to curve parameter t. Equal t intervals do not guarantee equal arc-length intervals or uniform target speed. Project ordered is closer to projecting existing points onto the new shape while preserving order, but can bring neighboring points close together or make them coincide; it must not be treated as speed preservation.

**Example:** A trajectory in frames 100–120 was incorrectly joined by a straight line, but actually turns sharply downward at frame 110. Use Add at 110 or drag the intermediate position directly, move the anchor to the actual turn, and use Corner to adjust both tangents. Separate curves are formed for 100–110 and 110–120; unrelated segments are not rewritten to follow the new curve.

### 6.2.4 Missing frames and Fill gaps

Without Fill gaps, missing frames are retained by default, rather than automatically adding points across unannotated intervals. To estimate missing annotations between two existing points, check Fill gaps before Preview.

Filling first interpolates `x/y/w/h` between adjacent existing positions in proportion to frame position, after which the shape can be edited further. Only internal gaps bounded by existing positions are filled, with no extension before the earliest or after the latest point. Added records are marked `curve_fill`, distinct from successful automatic recognition.

**Example:** Only three manual points exist, at frames 100, 110, and 120. Fill gaps can generate estimated positions at 101–109 and 111–119 before curve adjustment. Changing From to 90 does not automatically estimate 90–99, because that segment lacks an existing starting position.

### 6.2.5 Soft move

Use this to pull a continuously displaced trajectory segment back as a group, reducing local indentations caused by moving only one of many closely spaced anchors.

1. Select the target ID and a range including the incorrect segment and transitions on both sides, enter Edit, and click Preview.
2. Check **Soft** and enter an influence radius on the right, in original-image pixels; the default is 25.
3. Hold and drag an internal point on the orange preview trajectory. The dragged point moves most; other points' displacement falls rapidly with their original-image distance from it, reaching zero smoothly at the radius boundary. There is no central plateau of equal displacement.
4. Release the mouse to end the drag. Ctrl + Z undoes the entire drag; Apply commits all preview changes, and Discard discards them.

Spatial displacement weights use a smooth function with compact support:

$$
\frac{(1-u)^6(35u^2+18u+3)}{3}
$$

Here, $u$ is the original-image distance from the dragged point divided by the pixel radius. The center weight is 1; at one-quarter radius it is about 0.575, at half radius about 0.108, at three-quarter radius about 0.003, and outside the radius 0. Range endpoints, locked points, and missing-frame breaks limit propagation. Additional smooth tapering near fixed boundaries prevents movement from crossing a gap into another segment. Fixed boundaries remain stationary when an internal point is dragged. Dragging an endpoint automatically uses ordinary Edit behavior for that operation while leaving Soft enabled. Frame numbers and box dimensions are retained, without changing motion timing.

A smaller radius concentrates deformation. Select a range with room for transitions on both sides, and use several small drags if necessary. A very small radius combined with a large displacement can still produce excessive bending; inspect the preview before Apply.

**Example:** A segment near frame 200 is displaced to the right. Select frames 160–240 and a 30 px radius, then drag the frame-200 preview point 10 px left. Nearby points move left together and gradually rejoin the original path on both sides; positions outside the range are not recalculated into a new curve.

## 6.3 Redrawing with Draw

### 6.3.1 Standard procedure

1. Select the ID and frame interval to redraw, then choose Draw.
2. Check `Keep endpoints` and `Controls px`, then click Preview.
3. Hold the left mouse button in the video area and draw one stroke along the desired spatial path.
4. Release the button and wait for per-frame previews to be generated in the background.
5. Inspect both endpoint connections and frame distribution; if unsuitable, undo one stroke with Ctrl + Z or redraw.
6. Switch to Redistribute if needed to adjust point distribution along the path, then Apply.

Middle-button dragging and Ctrl + wheel retain image panning/zooming. Changing frames, leaving the canvas, or hiding it while drawing cancels an unfinished stroke; complete a stroke before navigating.

### 6.3.2 Parameters and effects

| Parameter | Initial value | Effect |
| --- | --- | --- |
| `Keep endpoints` | Checked | Connect the new path's ends to the original segment endpoints and retain their per-frame positions |
| `Controls px` | 1; allowed 0–100 | Geometric tolerance for selecting editable anchors after redrawing; increasing it only reduces control-point count, without simplifying the stroke or changing resampled per-frame positions |

One stroke redraws the entire selected segment; the scope is not automatically narrowed when the stroke covers only a small part. Narrow A/B first for local errors. If stroke direction opposes time order, the program chooses the better direction using endpoint distances.

The turns sampled from mouse movement are retained, with only consecutive duplicate points removed. Keep endpoints determines whether to connect to the original segment's ends. Mouse movement speed is not treated as target motion speed. Original frame positions are mapped to the new stroke using the original trajectory's relative cumulative arc length; if the original path has negligible length, points are distributed in order. The number of per-frame points does not increase, so the segment's frame count determines how finely it can represent the drawn curve. Locked points remain fixed; if they disagree with the new path, local reversals or abrupt changes can occur and require inspection.

Draw does not fill missing frames, although a stroke can cover existing points throughout the selected range. With a long missing interval, a redrawn connection must not be treated as observations obtained during that interval.

**Example:** A target moves around an obstacle, but recognition connects the two sides with a straight line. Select the range around the detour, retain endpoints, and draw a U-shaped route. The preview maps the original frame count onto the U-shaped path rather than deriving a speed curve from how fast the mouse drew the U.

## 6.4 Trajectory smoothing with Smooth

### 6.4.1 Procedure and live preview

Select an ID and local range, then switch to Smooth. Algorithm or parameter changes automatically preview the result; consecutive inputs are coalesced for about 180 ms before background computation. Preview can also trigger recalculation manually. Only Apply writes the result.

Parameter adjustments in one round use the trajectory before that fitting round as the baseline, avoiding an additional smoothing pass for every changed value. If manual curve changes were made first, subsequent smoothing can use the modified preview. Discard returns to the working positions before that preview began.

### 6.4.2 Algorithms

| Smoothing algorithm | Principle | Main parameters | Effects and limitations |
| --- | --- | --- | --- |
| `Median` | Take separate x/y medians in a local window | Window | Remove isolated jumps; may weaken brief but real movements |
| `Savitzky-Golay` | Fit a low-order polynomial in a sliding window | Window, Order | Smooth continuous noise while retaining some local trend; does not guarantee correct positions |
| `Smoothing spline` | Regularize the balance between data fit and curve smoothness | Strength | Continuous smoothing; larger values suppress more bends; short segments with fewer than five points are retained |
| `Simplify controls` | Simplify the path using geometric tolerance, then apply ordered projection | Tolerance | Reduce small geometric fluctuations and control structure, without reducing per-frame record count |

### 6.4.3 Parameters

| Control | Initial value and range | Meaning |
| --- | --- | --- |
| `Window` | 7; allowed 3–501 | Number of frames in the local window; constrained during calculation to a valid odd number available within the segment |
| `Order` | 2; allowed 1–5 | Savitzky-Golay polynomial order, capped at the value supported by the window |
| `Strength` | 1; allowed 0–10000 | Spline regularization strength; 0 retains the input, larger values tend toward smoother results; not a percentage |
| `Tolerance` | 1; allowed 0–10000 | Pixel tolerance for simplification and identifying prominent turns |
| `Max px` | 10; allowed 0–10000 | Maximum displacement per point; 0 prohibits position changes rather than removing the limit |
| `Keep corners` | Checked | Protect prominent turns; an erroneous spike can also be protected as a turn |
| `Stabilized` | Unchecked | Smooth in Camera-compensated coordinates first, then map back to each frame's original-image coordinates |

Parameters irrelevant to the current algorithm do not participate in its core calculation. For example, Strength does not govern Median smoothing, so changing Strength does not imply that Median results should change.

### 6.4.4 Protection rules and stabilized coordinates

Smooth does not add frames or smooth continuously across actual missing frames. Each continuous segment's endpoints, Lock points, and prominent turns identified with Keep corners enabled are protected.

Stabilized requires Camera compensation to be enabled and a transform available for each frame. It first removes the camera-motion component in display coordinates, smooths in stabilized coordinates, then maps back to the original image. Max px is then measured in stabilized coordinates; displacement statistics relative to the original trajectory still use the source-coordinate results after mapping back.

**Example:** A honeybee is nearly stationary while the camera shakes slightly. Strong smoothing directly in source coordinates may treat real camera displacement as annotation noise. Establish reliable Camera compensation and choose Stabilized to process residual jitter in a stable reference frame.

**Single-point spike example:** A point deviates 8 px from its neighborhood. Use Median, Window = 5, and Max px = 10. If Keep corners protects the spike, inspect whether it is a real turn before deciding to disable the option. Do not remove a discernible real turn merely to obtain a smooth line.

## 6.5 Redistributing positions along a trajectory with Redistribute

### 6.5.1 Purpose and shared constraints

Redistribute retains the current path while changing which frame occupies which position along it. Smooth primarily changes geometry, whereas Redistribute primarily changes motion progress along the path.

The original frame-number set, chronological order, segment endpoints, and locked points are retained. Each side of a missing-frame gap is processed separately. Locked points also bound redistribution intervals. All modes use consecutive frame order rather than stretching a segment to account for gaps in container timestamps.

The current preview's point-by-point path supplies the geometry. Correct obvious shape errors with Edit, Draw, or Smooth before deciding whether to apply a speed-distribution model.

### 6.5.2 Parameters and live preview

| Control | Initial value and range | Applicable modes |
| --- | --- | --- |
| `Preset` | Uniform speed | Four distribution models |
| `Influence %` | 50; 0–100 | All modes; blend the original and model distributions |
| `Acceleration %` | 0; −100–100 | Constant acceleration |
| `Turns %` | 50; 0–100 | Curvature-aware; control the influence of slowing at turns |
| `Transition %` | 50; 0–100 | Ease in/out, Curvature-aware |
| `Ends` | Keep; Stop also available | Ease in/out, Curvature-aware |

Parameters occupy two rows; fields unused by a mode are unavailable. Parameter changes automatically preview results, Apply commits them, and Ctrl + Z provides incremental undo before commit.

### 6.5.3 Mathematical meaning of Influence

Let the original point's cumulative distance along the path be `s_original`, the selected model's cumulative distance be `s_model`, and `a = Influence / 100`:

$$
s_{\text{new}} = (1-a) \times s_{\text{original}} + a \times s_{\text{model}}
$$

The program takes the position at `s_new` on the path rather than linearly averaging two-dimensional coordinates. Intermediate influence therefore still moves points along the path, without averaging opposite sides of a bend into a straight line across its inside.

- 0%: retain every original position.
- 100%: use the model distribution entirely.
- 50%: give equal weight to original and model progress.

### 6.5.4 Uniform speed

Distribute positions uniformly by arc length according to frame progress. For a continuous frame segment at 100% Influence, each adjacent frame covers the same path length.

**Example:** Five consecutive frames have original positions 0, 10, 20, 60, and 100 px along a straight path. Uniform speed with Influence = 100% gives 0, 25, 50, 75, 100; at 50% it gives 0, 17.5, 35, 67.5, 100.

On a curved path, straight-line distance between adjacent points can be slightly shorter than distance along the path; connecting-line lengths alone cannot strictly establish equal arc-length spacing.

### 6.5.5 Constant acceleration

Apply constant acceleration to tangential progress along the path. Let normalized frame progress `u` run from 0 to 1, path length be `L`, and `b = Acceleration / 100`:

$$
\frac{s_{\text{model}}}{L} = (1-b)u + bu^2
$$

- b = 0: uniform speed.
- b = +1: accelerate from rest.
- b = −1: gradually decelerate to rest.
- Intermediate values: weaker acceleration or deceleration.

**Example:** With five consecutive frames over a 100 px path, Acceleration = +100% and Influence = 100% give progress positions 0, 6.25, 25, 56.25, and 100 px. Points are denser near the start, indicating a lower initial speed.

Constant acceleration here is tangential to the path. On a curved path, velocity direction also changes, so the second derivatives of x/y are not necessarily constant. This mode cannot smoothly start and end at rest within the same segment; use Ease in/out for starts and stops at both ends.

### 6.5.6 Ease in/out

Smooth the start and finish according to **temporal position within the segment**, joining a relatively stable-speed middle section. Transition determines the proportion occupied by speed transitions at both ends; larger values extend the starting/finishing influence. In the implementation, each end's transition lasts approximately 5%–50% of the full interval.

`Ends = Stop` requires zero model speed at both endpoints. `Keep` uses estimated speed near the original path endpoints as a boundary reference, subject to limits and overall normalization. Keep must not be interpreted as unconditionally preserving arbitrary original endpoint speeds exactly.

**Example:** A target waits at the route's start before taking off, then gradually stops at its end. Choose Ease in/out with Ends = Stop. A bend in the middle does not itself cause additional slowing in this mode; deceleration primarily follows the frame interval's endpoints.

### 6.5.7 Curvature-aware

Reduce local model speed according to **the location and degree of path curvature**, with smooth transitions between straight and curved sections. For equal time steps, more closely spaced points are assigned near turns and more widely spaced points on straight sections.

- Increasing Turns strengthens the influence of sharp bends on distribution.
- Increasing Transition more strongly limits abrupt speed changes between straight and curved sections, extending acceleration/deceleration transitions.
- Ends = Stop requires zero model speed at both endpoints.
- Ends = Keep does not force endpoint stops; this mode does not thereby reproduce original endpoint speeds exactly.

The algorithm estimates smoothed curvature from the path, constructs a speed cap that decreases with curvature, limits acceleration changes in both temporal directions, and normalizes by total frame duration. It is a geometry-driven distribution model and does not identify insect dynamics parameters.

**Example:** A trajectory with a sharp central turn and straighter sections on both sides is suitable for inspecting Curvature-aware. Even if the sharp turn lies 70% through the segment, dense points occur near that bend. Ease in/out slows primarily according to starting/ending times and cannot substitute for this behavior.

### 6.5.8 Choosing a mode

| Required distribution assumption | Choice | Conclusion that cannot be inferred directly |
| --- | --- | --- |
| Consistent speed along the entire path | Uniform speed | Does not prove that the target actually moved at uniform speed |
| Acceleration or deceleration in one direction | Constant acceleration | Does not prove constant two-dimensional acceleration during turns |
| Smooth starts/stops at both endpoints | Ease in/out | Does not guarantee automatic slowing at bends |
| Slower sharp turns and faster straight sections with smooth transitions | Curvature-aware | Does not prove constant power or a specific biomechanical mechanism |

All four modes change a manually selected motion assumption rather than recover missing measured speeds. Before using results in speed, acceleration, or behavioral statistics, retain provenance and distinguish observations from manually redistributed results.

## 6.6 Transforming an entire trajectory with Transform

### 6.6.1 Parameters and procedure

1. Select an ID and a whole or partial frame interval, then choose Transform.
2. Check the default center; on first entry it is the center of the segment path's bounding box.
3. Enter X/Y offset or set Scale and Rotate. Specify a rotation center with Center X/Y or click `Pick center` and then click the video.
4. Inspect the live preview and its endpoint connections to the trajectory outside the range.
5. Commit with Apply or discard with Discard.

| Control | Units and initial meaning |
| --- | --- |
| `X offset / Y offset` | Source-image pixels; positive values move right/down respectively |
| `Center X / Center Y` | Source-image coordinates of the scaling/rotation center |
| `Scale %` | 100 is original size; allowed 0.01–100000 |
| `Rotate °` | 0 means no rotation; positive values rotate counterclockwise in the original image |
| `Pick center` | Set the center at the next click inside the video |
| `Reset` | Reset offsets and angle to zero and Scale to 100; retain the center |

Transformation order is scaling around the center, then rotation, then XY offset. Parameters in one round are calculated relative to the trajectory before that round, so repeated input changes do not accumulate the same transformation. Lock points are retained; records outside the range remain unchanged.

### 6.6.2 Effects

**Translation example:** An entire annotation segment is 8 px too far right and 3 px too high. Set X offset = −8 and Y offset = +3. Every unlocked selected frame center moves by this offset, while box W/H remains unchanged.

**Scaling example:** With Center at `(500, 300)`, point `(520, 300)` becomes `(530, 300)` at Scale = 150%. This enlarges the path's distance from the center rather than scaling box width/height to 150%.

**Rotation example:** Around the same center, point `(520, 300)` becomes approximately `(500, 280)` after a 90° counterclockwise rotation. Source-image y increases downward, so counterclockwise rotation moves it above the center.

Transform does not automatically create smooth connections outside the range. Translating a local segment can create endpoint jumps; expand the transition range or inspect junctions with Edit.
