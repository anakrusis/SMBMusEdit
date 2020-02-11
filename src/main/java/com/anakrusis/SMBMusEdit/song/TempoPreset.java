package com.anakrusis.SMBMusEdit.song;

import java.util.HashMap;

public class TempoPreset {
    // Key: encoded byte
    // Value: length in ticks (where each tick is 1/60 of a second)
    HashMap<Integer, Integer> durations;

    // Vice versa
    HashMap<Integer, Integer> keys;


    // Kind of a wrapper for the HashMap, but more legible
    public TempoPreset(){
        durations = new HashMap<>();
        keys = new HashMap<>();
    }

    public HashMap<Integer, Integer> getDurations() {
        return durations;
    }

    public HashMap<Integer, Integer> getKeys() {
        return keys;
    }
}
