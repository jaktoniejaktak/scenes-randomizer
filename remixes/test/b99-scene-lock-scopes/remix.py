"""B94 module bundle with page, track and Part Scene lock scopes."""

from remix.schema import Proof, Remix

REMIX = Remix(
    name="b99-scene-lock-scopes",
    family="mods",
    proof=Proof.PORT,
    proof_note="B94 module bundle; scoped Scene lock shortcuts need hardware verification",
    doc="B94 bundle: USB MIDI, sidechain, RPS9, MIDI velocity, Play Modes 2/4 and Transient, with Scene lock randomization by page, track or Part.",
    modules=(
        "USB MIDI", "MIDI VELOCITY", "SIDECHAIN_COMPRESSOR",
        "REPITCH_REPEAT98_KYOTI", "PLAY MODES", "TRANSIENT", "SCENE LOCK SCOPES",
        "FILTER", "EQUALIZER", "DJ EQ", "PHASER", "FLANGER", "CHORUS",
        "SPATIALIZER", "COMB FILTER", "LO-FI", "DELAY", "DARK REV",
    ),
    fallback="NONE",
)
