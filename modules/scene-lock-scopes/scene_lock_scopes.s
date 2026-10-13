| SCENE LOCK SCOPES -- held scene + page key randomizes the selected
| parameter page; + track key randomizes that track; + YES randomizes the
| whole Part. Only existing locks change.

        .equ    SCENE_HELD, 0x460d169c   | 1 = A held, 2 = B held
        .equ    TRACK_CUR,  0x80000000
        .equ    MIDI_MODE,  0x80000012
        .equ    PAGE_MODE,  0x460d1684
        .equ    DBPTR,      0x46c82456
        .equ    PART_DISP,  0x100b14cf
        .equ    PART_STRIDE, 0x18b2
        .equ    PART_WINDOW, 0x8ed80
        .equ    SCENE_ASSIGN, 0x10
        .equ    SCENE_LOCKS, 0x662
        .equ    PART_SRAM,  0x100a4ece
        .equ    SCENE_LIVE, 0x80000ed4   | interleaved A/B scene bytes, 0x40 per track
        .equ    PAGE_DESC,  0x40031ee0
        .equ    DIRTY,      0x40027e00
        .equ    NOTIFY,     0x4005a2b8
        .equ    EDIT_A,     0x460d1694
        .equ    EDIT_B,     0x460d1698
        .equ    REDRAW,     0x46c7d244
        .equ    TOAST_TIME, 0x3c

        .text
        .globl  sr_key_dispatch

| set_key_state(code, event) at 0x40031734. The stock prologue is eight
| bytes; run it verbatim after an optional randomization, then resume at +8.
sr_key_dispatch:
        | Only act on key-down while A or B is held. Page keys 0x22..0x26
        | select PLAYBACK, AMP, LFO, FX1, FX2; track keys 0x10..0x17 select
        | T1..T8. These keys continue to stock, so the chosen page/track opens.
        movel   %sp@(8),%d0
        cmpil   #0,%d0                 | stock uses edge 0 for press
        bne.w   sr_dispatch_stock
        tstl    SCENE_HELD
        beq.w   sr_dispatch_stock
        movel   %sp@(4),%d0
        cmpil   #0x31,%d0              | YES: whole Part
        beq.w   sr_part_key
        cmpil   #0x10,%d0
        bcs.s   sr_page_keys
        cmpil   #0x18,%d0
        bcc.s   sr_page_keys

sr_track_key:
        lea     %sp@(-60),%sp
        movem.l %d0-%d7/%a0-%a6,%sp@
        movel   %sp@(64),%d3
        subil   #0x10,%d3
        moveq   #1,%d1                | mode 1 = all pages on chosen track
        jsr     sr_randomize_scope
        movem.l %sp@,%d0-%d7/%a0-%a6
        lea     %sp@(60),%sp
        bra.w   sr_dispatch_stock

sr_page_keys:
        movel   %sp@(4),%d0
        cmpil   #0x22,%d0
        bcs.w   sr_dispatch_stock
        cmpil   #0x26,%d0
        bhi.w   sr_dispatch_stock
        lea     %sp@(-60),%sp
        movem.l %d0-%d7/%a0-%a6,%sp@
        moveq   #0,%d3
        moveb   TRACK_CUR,%d3
        moveq   #0,%d4
        movel   %sp@(64),%d0
        cmpil   #0x22,%d0
        beq.s   sr_page_playback
        cmpil   #0x23,%d0
        beq.s   sr_page_amp
        cmpil   #0x24,%d0
        beq.s   sr_page_lfo
        cmpil   #0x25,%d0
        beq.s   sr_page_fx1
        moveq   #4,%d4                | FX2
        bra.s   sr_page_call
sr_page_playback:
        moveq   #0,%d4
        bra.s   sr_page_call
sr_page_amp:
        moveq   #2,%d4
        bra.s   sr_page_call
sr_page_lfo:
        moveq   #1,%d4
        bra.s   sr_page_call
sr_page_fx1:
        moveq   #3,%d4
sr_page_call:
        moveq   #0,%d1                | mode 0 = selected page on current track
        jsr     sr_randomize_scope
        movem.l %sp@,%d0-%d7/%a0-%a6
        lea     %sp@(60),%sp
        bra.w   sr_dispatch_stock

sr_part_key:
        lea     %sp@(-60),%sp
        movem.l %d0-%d7/%a0-%a6,%sp@
        moveq   #2,%d1                | mode 2 = every lock in the Part
        jsr     sr_randomize_scope
        movem.l %sp@,%d0-%d7/%a0-%a6
        lea     %sp@(60),%sp

sr_dispatch_stock:
        lea     %sp@(-16),%sp
        movem.l %d2-%d4/%a2,%sp@
        jmp     0x4003173c

| The caller saves all registers around these helpers. The helpers preserve
| the callee-saved working set around stock's parameter randomizers.
sr_randomize_scope:
        lea     %sp@(-64),%sp
        movem.l %d2-%d7/%a2-%a6,%sp@
        movel   %d1,%sp@(56)           | 0 = page, 1 = track, 2 = Part

        tstl    MIDI_MODE              | stock audio scenes have no MIDI rows
        bne.w   sr_return
        moveq   #0,%d2
        movel   SCENE_HELD,%d2
        subql   #1,%d2                 | A=0, B=1
        cmpil   #1,%d2
        bhi.w   sr_return

        | Resolve the current Part once. Keep both its working and SRAM copy.
        moveq   #0,%d7
        moveb   PART_DISP,%d7
        moveal  DBPTR,%a1
        movel   %d7,%d0
        movel   #PART_STRIDE,%d1
        mulu.l  %d1,%d0
        addal   %d0,%a1
        addal   #PART_WINDOW,%a1
        movel   %a1,%sp@(44)
        moveal  #PART_SRAM,%a5
        addal   %d0,%a5
        movel   %a5,%sp@(48)

        | Scene A/B buttons select one of the Part's sixteen scene records.
        lea     SCENE_ASSIGN(%a1),%a0
        moveq   #0,%d0
        moveb   %a0@(0,%d2:l),%d0
        cmpil   #16,%d0
        bcc.w   sr_return
        movel   %d0,%sp@(52)
        moveq   #0,%d6                | changed lock count

        movel   %sp@(56),%d0
        cmpil   #2,%d0
        bhi.w   sr_return
        tstl    %d0
        beq.s   sr_page_start
        cmpil   #1,%d0
        beq.s   sr_track_start
        bra.s   sr_part_start

sr_page_start:
        cmpil   #8,%d3
        bcc.w   sr_return
        cmpil   #5,%d4
        bcc.w   sr_return
        bsr.w   sr_randomize_page
        bra.w   sr_finish

sr_track_start:
        cmpil   #8,%d3
        bcc.w   sr_return
        moveq   #0,%d4                | PLAYBACK, LFO, AMP, FX1, FX2
sr_track_page:
        bsr.w   sr_randomize_page
        addql   #1,%d4
        cmpil   #5,%d4
        bne.s   sr_track_page
        bra.w   sr_finish

sr_part_start:
        moveq   #0,%d3                | audio tracks 0..7
sr_part_track:
        moveq   #0,%d4                | PLAYBACK, LFO, AMP, FX1, FX2
sr_part_page:
        bsr.w   sr_randomize_page
        addql   #1,%d4
        cmpil   #5,%d4
        bne.s   sr_part_page
        addql   #1,%d3
        cmpil   #8,%d3
        bne.s   sr_part_track

sr_finish:
        tstl    %d6
        beq.w   sr_return

        | Keep Part Save / project save and power-cycle restoration in sync.
        moveq   #1,%d0
        movel   %d0,EDIT_A
        movel   %d0,EDIT_B
        moveal  DBPTR,%a0
        movel   %d7,%d1
        moveq   #1,%d0
        lsll    %d1,%d0
        movel   %a0,%d1
        addil   #0x95048,%d1
        moveal  %d1,%a2
        moveq   #0,%d1
        moveb   %a2@,%d1
        orl     %d0,%d1
        moveb   %d1,%a2@
        moveq   #0,%d1
        moveb   0x100b145e,%d1
        orl     %d0,%d1
        moveb   %d1,0x100b145e
        moveal  %a0,%a2
        addal   #0x9b332,%a2
        moveq   #1,%d0
        movel   %d0,%a2@
        movel   %d0,0x100f8598
        jsr     DIRTY

        pea     TOAST_TIME
        pea     sr_toast
        jsr     NOTIFY
        addql   #8,%sp

sr_return:
        movem.l %sp@,%d2-%d7/%a2-%a6
        lea     %sp@(64),%sp
        rts

| d2 = A/B side, d3 = audio track, d4 = page. d6 accumulates the number of
| changed locks. The BSR return address places locals four bytes above the
| outer frame's saved-register area: Part +48, SRAM +52, scene id +56.
sr_randomize_page:
        moveal  %sp@(48),%a1
        moveal  %sp@(52),%a5

        | Part offset = scene*256 + track*32 + page*6.
        movel   %sp@(56),%d0
        lsll    #8,%d0
        movel   %d3,%d1
        lsll    #5,%d1
        addl    %d1,%d0
        movel   %d4,%d1
        lsll    #2,%d1
        addl    %d4,%d1
        addl    %d4,%d1
        addl    %d1,%d0
        moveal  %a1,%a4
        addal   #SCENE_LOCKS,%a4
        addal   %d0,%a4

        | Descriptor P supplies min/count and the six stock randomizer
        | pointers at P+0x15a, exactly as RANDOMIZE PAGE uses them.
        movel   %d4,%sp@-
        movel   %d3,%sp@-
        jsr     PAGE_DESC
        addql   #8,%sp
        tstl    %d0
        beq.w   sr_page_done
        moveal  %d0,%a0
        lea     0x6a(%a0),%a2         | per-knob minimums
        lea     0x9a(%a0),%a3         | per-knob value counts
        lea     0x15a(%a0),%a6        | stock per-knob randomizers

        moveq   #0,%d5                | knob 0..5
sr_knob:
        moveq   #0,%d0
        moveb   %a4@(0,%d5:l),%d0
        cmpil   #127,%d0
        bhi.w   sr_next               | 0xff = unlocked; ignore bad bytes too
        movel   %a6@(0,%d5:l:4),%a0
        tstl    %a0
        beq.w   sr_next               | same as stock: no randomizer, no edit
        movel   %a3@(0,%d5:l:4),%d1
        tstl    %d1
        beq.w   sr_next
        subql   #1,%d1                | stock randomizer wants inclusive max
        movel   %a2@(0,%d5:l:4),%d0  | min
        addl    %d1,%d0              | max = min + count - 1

        | Keep loop state over the stock randomizer.
        lea     %sp@(-44),%sp
        movem.l %d2-%d7/%a2-%a6,%sp@
        movel   %d0,%sp@-             | max
        movel   %a2@(0,%d5:l:4),%sp@- | min
        jsr     %a0@
        addql   #8,%sp
        movem.l %sp@,%d2-%d7/%a2-%a6
        lea     %sp@(44),%sp

        moveb   %d0,%a4@(0,%d5:l)
        movel   %d0,%sp@(64)          | preserve value while calculating offsets

        | Matching battery-backed Part copy.
        moveal  %a5,%a0
        addal   #SCENE_LOCKS,%a0
        movel   %sp@(56),%d1
        lsll    #8,%d1
        movel   %d3,%d0
        lsll    #5,%d0
        addl    %d0,%d1
        movel   %d4,%d0
        lsll    #2,%d0
        addl    %d4,%d0
        addl    %d4,%d0
        addl    %d0,%d1
        addal   %d1,%a0
        moveq   #0,%d0
        movel   %sp@(64),%d0
        moveb   %d0,%a0@(0,%d5:l)

        | The frame builder morphs the live A/B pair in SRAM every frame.
        | Update the corresponding interleaved byte for immediate response.
        movel   %d3,%d1
        lsll    #6,%d1                 | track * 0x40
        movel   %d4,%d0
        lsll    #2,%d0
        addl    %d4,%d0
        addl    %d4,%d0                | page * 6
        addl    %d5,%d0
        lsll    #1,%d0                 | two interleaved bytes per lock
        addl    %d0,%d1
        addl    %d2,%d1                | A=0, B=1
        moveal  #SCENE_LIVE,%a0
        moveq   #0,%d0
        movel   %sp@(64),%d0
        moveb   %d0,%a0@(0,%d1:l)
        addql   #1,%d6

        | Refresh the readout only when this is the page on screen.
        moveq   #0,%d0
        moveb   TRACK_CUR,%d0
        cmp.l   %d3,%d0
        bne.s   sr_next
        movel   PAGE_MODE,%d0
        cmp.l   %d4,%d0
        bne.s   sr_next
        movel   %d5,%d0
        lsll    #4,%d0
        movel   %d5,%d1
        lsll    #2,%d1
        addl    %d1,%d0
        addql   #4,%d0
        lea     REDRAW,%a0
        moveq   #0x14,%d1
        movel   %d1,%a0@(0,%d0:l)

sr_next:
        addql   #1,%d5
        cmpil   #6,%d5
        bne.w   sr_knob

sr_page_done:
        rts

        .data
sr_toast:
        .asciz  "SCENE RANDOMIZED"
