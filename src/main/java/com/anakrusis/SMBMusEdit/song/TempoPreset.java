package com.anakrusis.SMBMusEdit.song;

import java.util.HashMap;

public class TempoPreset {
    HashMap<Integer, Integer> durations;

    // Kind of a wrapper for the HashMap, but more legible
    public TempoPreset(){
        durations = new HashMap<>();
    }

    public HashMap<Integer, Integer> getDurations() {
        return durations;
    }
}
