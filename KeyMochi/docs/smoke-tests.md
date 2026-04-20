# KeyMochi — Manual Smoke Tests

Run this checklist after any significant change. All tests are manual and require a physical Mac with wired headphones connected.

## Setup
- [ ] Fresh build (`Cmd-Shift-K`, then `Cmd-R`)
- [ ] Wired headphones connected and selected as system output
- [ ] KeyMochi granted Accessibility permission

## Core functionality
- [ ] Typing in any app produces keystroke sounds within 10 ms (perceptually instant)
- [ ] Left-hand keys (Q, A, Z) sound in the left ear; right-hand keys (P, ;, /) sound in the right ear
- [ ] Spacebar sounds centred
- [ ] Holding a key does not produce machine-gun audio (auto-repeat drop)
- [ ] Pressing Shift/Cmd/Ctrl/Opt alone produces no sound (modifier filter)

## Pack switching
- [ ] Each of the 5 packs (Creamy, Thocky, Clacky, Poppy, Clicky) auditions correctly
- [ ] Switching pack via UI immediately changes the sound while typing
- [ ] Pack selection persists across app restart

## Spatial position
- [ ] Dragging the listener dot left/right/back/forward shifts where sounds appear to come from
- [ ] Reset position returns to centre
- [ ] Height slider changes perceived up/down position (subtle but audible)
- [ ] Position persists across app restart

## Bluetooth warning
- [ ] Connecting AirPods / BT headphones while app is running shows the yellow banner in the main window
- [ ] Disconnecting Bluetooth removes the banner

## Menu bar
- [ ] Clicking the keyboard icon reveals the menu bar popover
- [ ] Toggle Enabled off → no sounds on keypress
- [ ] Toggle Enabled on → sounds resume
- [ ] Master volume slider changes output level
- [ ] Volume 0 = silent; volume 1 = loud
- [ ] Quit exits the app

## Permission handling
- [ ] Fresh launch on a system without Accessibility permission → Permissions tab forces itself open
- [ ] Granting permission + restart → app functions
- [ ] Revoking permission at runtime (System Settings) → audio stops; Permissions tab returns to "not granted" state after next app restart

## Output device change
- [ ] Unplug headphones mid-typing → app continues working, audio switches to speakers
- [ ] Replug headphones → audio switches back
- [ ] No crashes, no silence requiring restart

## Stress
- [ ] Mash 10+ keys/second for 30 seconds → no clicks, no dropouts
- [ ] Type during a Zoom/Meet call → no interaction issues

## Not expected to work (known limitations)
- [ ] AirPods head tracking (rotating head keeps sound fixed) — DEFERRED to v1.x
- [ ] Per-app sound profiles — DEFERRED
- [ ] Custom pack import UI — DEFERRED
