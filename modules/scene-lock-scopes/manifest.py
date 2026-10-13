"""B94-based Scene lock randomization with page, track and Part scopes."""

from remix.schema import Category, Claims, Detour, Kind, Linked, Module, Proof

H = bytes.fromhex

MODULE = Module(
    name="scene-lock-scopes",
    key="SCENE LOCK SCOPES",
    kind=Kind.CF_PATCH,
    category=Category.TRACK,
    author="kazeko",
    author_url="https://github.com/kazeko",
    proof=Proof.PORT,
    proof_note="Uses the B94 scene-lock update path; new page/track/Part key scopes await Octatrack testing.",
    doc="Hold Scene A or B and press a parameter page key to randomize existing locks on that page for the selected track; press T1–T8 to randomize that track; press YES to randomize existing locks across the Part. SCENE + NO has no custom action.",
    linked=(
        Linked("scene_lock_scopes", "modules/scene-lock-scopes/scene_lock_scopes.s", dram=True),
    ),
    claims=Claims(sram=((0x80000ed4, 0x200,
                         "live A/B scene lock bytes, updated for immediate audio response"),)),
    detours=(
        Detour(
            0x40031734,
            H("4feffff048d7041c"),
            "scene_lock_scopes",
            "sr_key_dispatch",
            "Scene A/B + page, track and YES scoped lock randomization",
            kind="jmp",
            pad_to=8,
        ),
    ),
)
