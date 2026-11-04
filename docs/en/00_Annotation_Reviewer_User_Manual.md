# Annotation Reviewer User Manual

# 0 Introduction

## 0.1 Scope

This manual describes the inputs, operating procedures, practical effects, algorithmic principles, and data limitations of Annotation Reviewer.

## 0.2 Chapter Index

| Chapter | Contents |
| --- | --- |
| 1 | [Basic operations: startup, opening files, navigation, playback, saving, and export](01_Basic_Operations.md) |
| 2 | [Main interface, data tables, Filter, selection, segment review, and display appearance](02_Interface_and_Segment-by-Segment_Review.md) |
| 3 | [Detection: model inference and batch detection](03_Detection_Operations.md) |
| 4 | [Detection: postprocessing parameter tests and result replay](04_Detection_Postprocessing_Tests.md) |
| 5 | [Edit: Box, ID, Interpolate, Swap, and staged operations](05_Edit_Operations.md) |
| 6 | [Trajectory: Edit, Draw, Smooth, Redistribute, Transform](06_Trajectory_Operations.md) |
| 7 | [Match: manual and automatic trajectory alignment, candidates, binding, and review](07_Match_Operations.md) |
| 8 | [Tracking: manual addition, template tracking, and manual takeover](08_Tracking_Instructions.md) |
| 9 | [Scale: calibration bars, lengths, angles, and spatial measurement](09_Scale_Operations.md) |
| 10 | [Camera: anchors, stabilization, and Expanded motion canvas](10_Camera_Operations.md) |
| 11 | [Points and Events: reference information, subjects, events, and verification](11_Points_and_Events_Operations.md) |
| 12 | [Undo, redo, and recovery](12_Undo_and_Recovery.md) |
| 13 | [Boutlist creation, field mapping, and synchronization](13_Creating_and_Using_a_Boutlist.md) |
| 14 | [Settings, decoding, rendering, performance, and Profiler](14_Settings_and_Performance.md) |
| 15 | [Terminology, shortcuts, and data conventions](15_Terminology_Shortcuts_and_Data_Conventions.md) |

## 0.3 Standard Workflow

1. Open the video and its corresponding sources, and verify image identity, frame count, coordinates, classes, and paths.
2. If a model task is required, complete Detection, test postprocessing with a fixed raw input, and then explicitly load the results.
3. Use data tables, timeline strips, and trails to locate problematic segments; distinguish identity errors from position errors first.
4. Correct errors with Edit, Trajectory, Match, or Tracking. Inspect the preview before confirming and committing.
5. Complete Camera stabilization and Scale calibration as needed, and check their relationship to original image coordinates.
6. Record Points, Events, subject identities, and verification status.
7. Check History, transitions at segment boundaries, and source fields, and save the results; reopen the file for spot checks.
8. Treat annotated video as a separate output. Verify display and encoding with a short clip before exporting the full video.

## 0.4 Shared Conventions

- Video images are numbered from 1; ranges include both endpoints. `100-110` contains 11 frames.
- The original image origin is at the upper left, with X increasing to the right and Y downward; box x/y specify the center, and w/h specify dimensions.
- View zoom does not change original coordinates; Camera and Scale provide separate coordinate and measurement transformations.
- Display, candidates, preview, commit, and saving to disk are distinct states.
- Hover over labels for explanations and over input fields to view their current contents; buttons and checkboxes describe their actions.
- Percentage match scores, model confidence, geometric residuals, and position sources are different measures.
- Interpolation, smoothing, redistribution, and position holding rely on assumptions. Visually smooth results alone do not establish more accurate reconstruction of actual motion.
- Save original videos, detection outputs, and manually reviewed results separately. Recovery snapshots support recovery and do not replace formal results.

## 0.5 Task-Based Reference

| Task | Main chapters |
| --- | --- |
| Find missed-detection segments or locate outliers | 2, 5, 6 |
| A stationary target reappears under a different ID | 5 |
| Two targets exchange IDs after crossing | 5, 7 |
| An entire segment has no boxes and requires manual or template-based trajectory completion | 8, 5 |
| A curved trajectory has incorrect positions, jitter, or unreasonable speed allocation | 6 |
| Detection boxes remain present but identities change frequently | 3, 4 |
| Camera movement or image/annotation correspondence problems | 1, 10 |
| Pixel-to-centimeter conversion and perspective variation | 9 |
| Events, capture participants, and left truncation | 11 |
| Unexpected exit, operating errors, or comparison of alternatives | 12 |
| Quickly open multiple bouts and write back changes | 13 |
| Playback, tracking, or export performance | 14 |
