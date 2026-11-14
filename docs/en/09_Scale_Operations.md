# 9 Scale Operations

[Return to the main index](00_Annotation_Reviewer_User_Manual.md)

## 9.1 Purpose and Measurement Prerequisites

Scale establishes a metric relationship between image pixels and real-world centimeters. A plane viewed approximately head-on can use a uniform px/cm value; oblique views, perspective variation, or spatially varying scale require multiple length segments and, where applicable, real-world angle constraints.

Scale is separate from the experimental origin and Camera stabilization: Scale determines distance measurement; Hive/Axis determines the reference origin for display or experimental coordinates; Camera uses background anchors to remove camera motion between frames. Configuring one does not automatically configure the other two.

Calibration objects should lie in the same, or approximately the same, measurement plane as the target motion. Planar calibration cannot eliminate parallax when a target leaves the plane. Without known real-world lengths, drawn lines provide geometric directions only, not centimeter units.

## 9.2 Interface and States

Open Edit → Scale to see the calibration bars.

| Control | Behavior |
| --- | --- |
| Scale (px/cm) | Displays a summary outside editing mode: a single value for uniform scale or a range for variable scale |
| Changes / Apply | Starts a calibration transaction; clicking Apply again commits all changes as one History operation |
| Add bar | Adds a calibration bar within the transaction, without a default real-world length |
| Condition | Shows numerical conditioning; hover for fit and cross-validation diagnostics and each bar’s placement frame |
| Scale metric | Shows whether absolute length is available and the constraint rank for affine/homography models |
| Inputs / Need | Summarizes the numbers of lines, lengths, and angles, and the constraints still required |

Results shown during editing are previews; Apply places them in the working data, and Save as writes them to disk. ESC cancels an uncommitted calibration transaction. Cancellation does not delete calibration saved before editing began.

## 9.3 Entering a Uniform Scale

1. Confirm that perspective differences across the measurement region are negligible.
2. Click Changes and enter a positive px/cm value in the Scale field.
3. Click Apply.
4. Enable Axis/Metric grid to check known distances, then save.

For example, if a known 5 cm length occupies 150 px in the image, the scale is 30 px/cm; a 60 px displacement corresponds to 2 cm. The input is px/cm, not cm/px. Entering a single value selects a uniform scale representation. Replacing existing variable calibration with an average value does not preserve its local corrections.

## 9.4 Editing Calibration Bars and Lengths

### 9.4.1 Creating and Positioning a Bar

1. Click Changes, then Add bar.
2. A new bar appears in the image without a real-world length.
3. Click an endpoint to select it, then specify its correct position; follow the canvas interaction prompts to move it onto a ruler or known marker.
4. Position the other endpoint in the same way. Zooming in helps with precise point placement.
5. Right-click a segment to add an intermediate point representing measurable subdivisions.

Place a bar at any frame, before or after adding Camera anchors. The application records source-image coordinates, a coordinate reference frame, and the actual placement/edit frame. Multiple bars are mapped to the first bar’s reference frame for calibration, normally without rebasing to video frame 1. To rebase a single bar to frame 1, use **Changes → Pin bar → Apply**. Its actual placement frame is retained and appears in the **Condition** tooltip.

Calibration bars use straight-line geometry. Intermediate points subdivide a line; do not treat a curved object contour as a single straight ruler. After moving endpoints, check that intermediate points and segments still correspond to the real markers.

### 9.4.2 Entering Lengths

Left-click a segment to open the on-canvas length field, enter its actual length in centimeters, and confirm with `√` or `Enter`. Only confirmed lengths participate in the metric solution.

When adding subsequent segments, the input field may suggest a length based on the current calibration. This is an estimate from the existing model, not new independent measurement evidence; verify it against the actual known length before confirming. Leaving the field blank and confirming removes the segment's length constraint while retaining its geometry.

### 9.4.3 Intermediate Points and Deletion

Right-click a segment to add a point; right-click a point to select it, then perform the corresponding deletion interaction again on the selected point to delete it. Check adjacent segment length definitions after deletion; do not assume that an existing length still refers to the same endpoints. When deleting or rebuilding a line, check which angle constraints become invalid.

## 9.5 Real-World Angle Constraints

Hold Ctrl and select two lines to open angle editing. The on-canvas display shows the image angle and a `Real` input; branch buttons select the corresponding angle orientation. Enter a real planar angle greater than 0 and less than 180 degrees, then confirm; leave the field blank to clear the angle constraint for this pair of lines.

**An image angle is not the real-world angle.** An obliquely viewed right angle may appear acute or obtuse; conversely, two approximately perpendicular image lines do not establish real-world perpendicularity. Enter 90° only when the actual geometry is known.

**Example: a rectangular calibration board.** If two sides are known to be perpendicular, represent each side as a line, record the actual side lengths, and add 90°. For two arbitrary wall scratches with an unknown real angle, leave the angle unconstrained.

## 9.6 Five Calibration Models

### 9.6.1 Uniform: Constant Scale

A single ratio describes all positions and directions. Distance in centimeters is approximately pixel distance divided by px/cm. This is suitable for approximately head-on views with limited scale variation. It cannot correct directional stretching or perspective convergence.

### 9.6.2 Projective 1D: Projective Scale Along One Direction

When a single line has sufficient segment length information, it can describe scale variation along that line. Equal real-world segments at different depths may have different image lengths. This model is supported by one-dimensional evidence only and does not establish a complete two-dimensional planar transformation.

### 9.6.3 Local field: Local Scale Field

Multiple lines provide local scales at different positions; when two-dimensional constraints are insufficient, the application uses a local scale approximation. This helps describe spatial variation but is not equivalent to a two-dimensional affine/projective coordinate system with complete angular relationships. Interpret extrapolation far from calibration bars cautiously.

### 9.6.4 Affine: Two-Dimensional Affine Metric

Sufficient independent length and angle constraints determine directional differences in the two-dimensional metric. An affine metric has 3 independent components; a constraint rank of 3 indicates that this information is sufficient. Multiple lengths in the same direction often provide similar, redundant information rather than automatically satisfying three independent constraints.

### 9.6.5 Homography: Two-Dimensional Planar Projective Metric

With sufficient information at different positions and orientations, a planar projective metric can be fitted to address position-dependent perspective variation. Metric determination uses 5 independent constraint directions; concentrated, nearly parallel, or excessively concurrent inputs may be poorly conditioned even when their number is sufficient.

Model selection favors the simpler model sufficient to explain the data. Constraint rank, numerical conditioning, and fit results jointly affect selection; L, T, cross, and rectangular line arrangements are not model types.

## 9.7 Rank, Condition, and Diagnostics

| Indicator | Correct interpretation |
| --- | --- |
| Abs | Whether an absolute length reference in centimeters is available |
| Affine r/3 | Independent constraint rank for the affine metric, not a line count |
| Homography r/5 | Independent constraint rank for the projective metric |
| Condition | Stability of the current constraint geometry; hover to see each bar’s actual placement frame |
| Fit RMS / Max residual | Fitting error for entered lengths or angles |
| CV length error | Held-out length validation when calculable; may be N/A without redundancy |

When the minimum constraints are fitted exactly, an RMS of zero does not imply error-free measurement. Add independent measured segments with good spatial coverage and different orientations to check extrapolation and errors. Do not repeatedly enter model-estimated suggested lengths to create apparent redundant validation.

Need prompts help select the next useful input, but cannot determine whether a real-world length or angle is actually known.

## 9.8 Single Values, Ranges, and Complete Output

`scale_px_per_cm` always provides a representative scale summary for quick reference. When a variable model displays `[min,max]`, this indicates local scale variation, not two directly enterable upper and lower bound settings.

The complete `scale_calibration` stores the calibration type, line points, known lengths, angle constraints, and corresponding model data for recovery and downstream measurement. The output annotation file retains the full JSON; Boutlist mappings for `scale_px_per_cm` and `scale_calibration` are enabled independently, allowing both the scale summary and complete JSON to be saved. Clear the corresponding column name to disable write-back for that item.

When opening a Boutlist or using Sync from, a simple `scale_px_per_cm` value cannot replace existing complete calibration, even if it differs from the current average summary; it does not prompt model replacement. Only a valid complete `scale_calibration` participates in source comparison for full calibration. A fixed single-value scale can still synchronize a new ratio; small serialization precision differences are treated as equivalent, retaining the annotation's original precision.

For variable calibration, dividing all pixel distances by the summary scale in subsequent analysis loses local and directional corrections. Confirm that the analysis program reads the complete model. The Scale tab only establishes and saves calibration; it cannot ensure that external analysis scripts use it automatically.

## 9.9 Metric grid and Coordinate Origin

Metric grid maps centimeter spacing back to the image for inspection. A Uniform grid is approximately evenly spaced; projective calibration may produce convergence or uneven spacing; a local field grid represents approximate measurement. Grid anchor selects the grid reference position, while the Axis/Hive origin does not change entered lengths or real-world angles.

Hive/Axis can be placed at any frame, before or after adding Camera anchors. It stores source-image coordinates and the actual placement frame. With Camera enabled, the origin is mapped from its placement frame to the current frame. Hover over the Hive value button to see `x, y (Frame=n)`. Older data without a placement frame shows `Frame=?`; placing the origin again at a known frame records it.

Compare the grid with real markers not used for fitting. Visual regularity is not evidence of accuracy. If lines are too dense, increase physical spacing or reduce display density rather than changing real-world lengths to reduce the number of grid lines. Screen zoom and pan change the view, not the calibration values.

## 9.10 Camera and Expanded motion canvas

Camera uses background anchors to map positions between frames. Expanded motion canvas places the transformed images on a common canvas so that the background stays stable. Scale then converts image distances to centimeters. Calibration bars, the coordinate origin, and target annotations therefore need to use the same Camera transformation.

On the normal image, bars, the origin, and the metric matrix follow the corresponding background. In Expanded motion canvas they remain fixed relative to the stabilized background. Switching views does not require recalibration or rewrite source coordinates and real lengths. Temporarily disabling Camera retains the calibration. If an older canvas-space calibration lacks the required transformation, restore the correct Camera state before editing it.

For a practical setup, choose fixed background anchors on the calibration plane, verify compensation, and then place bars and enter known lengths. Anchors can also be added after placing the bars. Check the beginning, middle, and end of the clip: each bar should stay on the same reference object. Verify scale against a known length not used for fitting; a stable background alone does not establish accurate centimeter measurements.

Bars may be placed at any frame, before or after adding anchors. Moving a bar endpoint or intermediate point and applying updates that bar’s actual placement frame. Browsing frames or applying without changes does not update it. The coordinate reference frame is stored separately, so bars can share a coordinate reference while retaining their individual placement frames.

Whether planar perspective changes can be compensated depends on anchor geometry and the Camera model. Different planes for calibration and targets, changes in target height, occlusion, and registration errors can still bias measurements. Fixing the canvas does not remove those errors. Recheck calibration coverage after substantial changes in viewpoint or zoom.

## 9.11 Typical Examples

### 9.11.1 A Uniform Ruler

Choose a clear ruler segment close to the target plane, position its endpoints, enter its actual length, and click Apply. Verify the scale using another known length, then save.

### 9.11.2 A Ruler with Scale Variation Along Its Depth

Place intermediate points at identifiable marks along the same straight ruler and enter known segment lengths. Check for an along-line variable model and reasonable graduations; do not interpret along-line information as complete two-dimensional perspective calibration.

### 9.11.3 Calibration in Multiple Directions

Distribute multiple known lengths throughout the measurement region and add genuinely known real-world angles. Observe rank, Condition, and residuals as inputs are added. Independent directions and positions are more useful than additional nearly parallel lines within one small region.

### 9.11.4 An Incorrect Segment Length

Changes → click the segment → correct cm → confirm → check the model and other residuals → Apply. If the overall result is unreasonable, cancel the preview or undo it in History rather than overwriting all original inputs with a summary scale.

## 9.12 Acceptance and Saving Procedure

Verify the measurement plane, units, endpoint positions, intermediate segment lengths, and sources of real-world angles. Check that the model matches the available information and that diagnostics show no obvious degeneracy; test with lengths excluded from fitting. After Apply, use Save as, then reload to confirm that original line points, constraints, and the model remain editable. A Boutlist summary alone cannot reconstruct the full calibration.
