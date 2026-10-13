# Scene Lock Scopes

This is based on B94's working Scene Randomizer image and its immediate live
parameter update path. The new shortcuts change only values for locks that
already exist in the selected scene; unlocked parameters stay unlocked.

- Hold Scene A or B and press a parameter page key (PLAYBACK, AMP, LFO, FX1
  or FX2) to randomize that page's existing locks on the selected track.
- Hold Scene A or B and press T1–T8 to randomize existing locks across all
  five pages of that track.
- Hold Scene A or B and press YES to randomize existing locks across all
  audio tracks and five pages in the current Part.
- Scene + NO has no custom randomization action.

The pressed page or track key continues to the stock handler, so the selected
page or track opens after the randomization. Scene + YES replaces the former
visible-page action and the former Scene + NO whole-Part action.

The code updates the current Part, its battery-backed copy and the live A/B
scene bytes so audio responds without switching scenes. Hardware testing of
these new scopes is still needed.
