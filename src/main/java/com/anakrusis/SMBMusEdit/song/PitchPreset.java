package com.anakrusis.SMBMusEdit.song;

import java.util.HashMap;

public class PitchPreset {
    // Key: encoded byte
    // Value: midi note value
    HashMap<Integer, Integer> pitches;

    public PitchPreset() {
        pitches = new HashMap<>();
    }

    public HashMap<Integer, Integer> getPitches() {
        return pitches;
    }
}
