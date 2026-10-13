# B99 Scene Lock Scopes

This package contains the working B99 Scene Randomizer source and its remix
definition. It uses the B94 module bundle and live scene-update path, without
the temporary track-length shortcut from B98.

Controls:

- Hold Scene A or B and press PLAYBACK, AMP, LFO, FX1 or FX2 to randomize
  existing locks on that page of the current track.
- Hold Scene A or B and press T1–T8 to randomize existing locks on all five
  pages of that track.
- Hold Scene A or B and press YES to randomize existing locks across all
  audio tracks and pages in the current Part.
- Scene + NO has no custom random action.

Only already-locked parameters are changed. The pressed page or track key
continues to the stock key handler. The new shortcuts worked on Kazeko's
Octatrack; the temporary length feature is not part of this build.

## Source layout

- `modules/scene-lock-scopes/`: manifest, ColdFire code and module notes.
- `remixes/test/b99-scene-lock-scopes/`: remix definition and release notes.

Copy both directories into matching paths in an Octabam checkout, then build
with `make image REMIX=b99-scene-lock-scopes BUILD=99`. The firmware BIN/SYX
and remix image are kept separately in `/Volumes/EXT/-=octabam=-/-=builds=-`;
they are not included here.
