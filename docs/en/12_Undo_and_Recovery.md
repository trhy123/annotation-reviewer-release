# 12 Undo and Recovery

[Return to the main index](00_Annotation_Reviewer_User_Manual.md)

## 12.1 Three Distinct Levels

| Level | Contents | Typical access |
| --- | --- | --- |
| Current interactive preview | Uncommitted point, curve, or calibration changes | Tracking, Trajectory, Continuous, Scale |
| Working session history | Commands committed to the current working data | History → Undo / Redo |
| Persistent storage and recovery | Annotation files, automatic recovery snapshots, and manual snapshots on disk | Save / Save as, Display → Recovery |

Undoing a command does not delete a saved annotation file; restoring a snapshot does not automatically save its results as an annotation file. A preview remaining visible does not mean it has entered History.

## 12.2 Undo Within the Current Interaction

### 12.2.1 Tracking

Before commit, Ctrl + Z undoes one automatic/manual position step and Ctrl + Y redoes it; current point and range deletions are also recorded within this session. The local stack stores lightweight changes rather than a full History command for each frame.

Finish commits the pending results as one tracking command. Afterward, one Undo in History reverses the entire commit. Cancel discards the session and restores the working data from before it began.

### 12.2.2 Trajectory

Previews of anchor editing, handle editing, redrawing, smoothing, redistribution, and transformation support stepwise undo. Apply commits the confirmed trajectory segment as one change; Discard abandons the preview. When repeatedly comparing the same segment, check that the preview is complete before Apply.

### 12.2.3 Change position Continuous

Within a Continuous session, position changes are reversed step by step; after the session ends, history follows committed session boundaries. Canceling an editing mode differs from undoing points already modified successfully; inspect the working data and History after exiting.

Recovery snapshots can retain executed lightweight operation records and local redo branches in Change position Continuous. After restoration, stepwise undo/redo remains available; ending the Continuous session enters History at the overall commit boundary. Position inputs not yet executed are not saved as completed annotations.

### 12.2.4 Input Focus

When keyboard focus is in a text field, Ctrl + Z may undo text input. To undo trajectory operations, move focus to the canvas or use the corresponding Undo button. Enter, right-click, and ESC depend on the current interaction mode and should not all be interpreted as saving a file.

### 12.2.5 Boutlist Editing

Cell editing in Select bout uses an independent undo history outside annotation History. When the window has focus and Edit is enabled, ↶ or Ctrl + Z undoes the latest cell commit, and ↷ or Ctrl + Y redoes it; both immediately write back to the Boutlist file. With Edit disabled, both buttons are grayed out and cell undo shortcuts do not execute.

While cell text is being entered, Ctrl + Z/Ctrl + Y first operate on text in the editor. Only after leaving the cell and committing do shortcuts affect saved cell changes. When the main window has focus, its existing local undo and History apply.

Records are maintained separately for each Boutlist file. They survive closing the selection window and switching bouts until the application exits; they are not saved in annotation files or recovery snapshots. If external changes invalidate records, reread the file; obsolete cell records are no longer used to overwrite new content. Navigation back/forward is independent of both forms of edit undo.

### 12.2.6 Filtering and Operation Staging

Applying Filter conditions, toggling filters, and previewing results do not generate annotation History. Use matched rows only establishes a precise scope; a corresponding change is created only when Delete or Change class executes. For mixed changes to automatic and imported manual records, one undo restores both and one redo reapplies both, without relocating targets by hidden table row numbers or the current ID/Range.

Creating, renaming, selecting, removing, and restoring drafts in Operation stash do not modify annotations or enter the annotation undo stack. Automatic operation input records and manual drafts are stored per video in the operation_stash subdirectory of the recovery directory and remain available across launches; they store inputs only and do not replace annotation Recovery or formal results. Restore inputs/Send only populates tool inputs; actual operations follow their own commit and undo rules.

## 12.3 History Table

The columns are `#`, `Time`, `Op`, `IDs`, `Frames`, and `Details`, used to check sequence, time, command type, identities, frame range, and parameter summary respectively. Clicking an entry helps inspect affected objects; selecting a table entry does not perform an undo.

Undo moves back one step in the current command stack; Redo restores one undone step. A new edit after undo may create a new history branch; the old Redo chain is not a permanent backup.

After Save writes back to the current annotation file, the current session's Undo/Redo remains available. Default saving retains concise history and row-level audits inside SQLite, omitting command payloads that cannot restore cross-session undo. Compact SQLite save removes these histories and audits. Reopening a file does not restore its previous undo stack; new operations remain undoable. Old command archives and the `_edit_log.txt` exported with CSV are read-only. Recovery snapshots separately store session state using the existing `.pkl` mechanism.

**Procedure:** Pause and finish the current interaction → inspect recent command IDs/Frames → Undo → check the canvas and tables → Redo if needed → save again.

## 12.4 Recovery Settings

Access the Recovery settings in Display.

| Setting/button | Purpose |
| --- | --- |
| Recovery | Enables session recovery snapshots |
| Recovery directory / Browse | Specifies the recovery data directory |
| Snapshot | Requests an immediate automatic recovery snapshot |
| Save as... | Explicitly saves a named snapshot for later manual opening |
| Open... | Manually loads a saved recovery snapshot |

Snapshots are written in the background; clicking Snapshot does not establish that disk writing has finished. The recovery directory must exist and be writable; check error states for disconnected network drives, insufficient space, and similar conditions.

Save as... here saves a recovery snapshot; Save / Save as at the bottom saves formal result files. The CSV option in the bottom Save as exports a compatibility table only, neither creating a recovery snapshot nor clearing the current project's unsaved state.

Automatic recovery is intended for abnormally terminated sessions; automatic snapshots following normal exit should not be used as a persistent project library. To retain milestone states long term, use named snapshots and also save formal annotation files.

## 12.5 Recovery After Unexpected Interruption

1. Restart and check for a session recovery prompt.
2. Verify the video and annotation sources associated with the snapshot.
3. After restoration, inspect the current frame, working rows, History, key metadata, and pending edits.
4. If video paths have changed, restore the correct source first and verify image identity correspondence.
5. Inspect the last operation segment and complete the necessary Finish/Apply or cancel it.
6. Save formal results under a new name to avoid overwriting the only output with an unverified recovery state.

### 12.5.1 Example: Unexpected Process Exit During Automatic Tracking

Recovered content may include committed data and pending tracking state recorded in the snapshot. Check recent frames, templates, and buffered points first; do not assume the final frame visible before exit was written to the snapshot. After verification, continue tracking or use Finish, then save the annotation file.

### 12.5.2 Example: Retaining Two Editing Alternatives

Explicitly save a named snapshot and annotation file before branching. Complete and save the first alternative separately, then load the snapshot from a known starting point for the second alternative. Do not rely solely on repeated Undo/Redo in place of named versions.

### 12.5.3 Saving Before Image Identity Verification Is Complete

Formal outputs use frame numbers in actual decoding order. If video indexing is incomplete or edits retain image references awaiting verification, Save / Save as waits for indexing and edit record reconciliation before continuing; waiting does not mean the file has been written. Old image references restored from snapshots must also pass this check.

If `Frame mapping pending` appears, inspect the reported error and the FFprobe path in Display → Decoder. After correction, click Save / Save as again to retry failed indexing; choosing a different output filename cannot bypass image identity verification.

To preserve work before resolving the problem, pause automatic tracking first; Apply trajectory curve previews or explicitly discard them. Then use Display → Others → Manual snapshot → Save as... to save a named `.pkl`, and wait for `Snapshot saved`. Executed Continuous steps and local undo records can be retained in the snapshot without ending the session solely for backup. This does not require Recovery to be enabled and does not create a formal annotation file. After restoring the snapshot, complete indexing reconciliation, verify the data, and save formal results.

## 12.6 Limitations and Checks

Recovery depends on readable videos and source data; snapshots cannot reconstruct lost video images. Layer caches accelerate display and do not replace recovery snapshots; clearing or changing display caches should not be used as undo. Formal output is the annotation file successfully saved and reopened for verification.
