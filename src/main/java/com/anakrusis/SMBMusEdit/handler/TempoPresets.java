package com.anakrusis.SMBMusEdit.handler;

import com.anakrusis.SMBMusEdit.SMBMusEdit;
import com.anakrusis.SMBMusEdit.song.TempoPreset;

import java.util.ArrayList;
import java.util.HashMap;

public class TempoPresets {

    static HashMap<Integer, TempoPreset> tempoPresets;

    public static void init() {
        tempoPresets = new HashMap<>();
        int tempoPresetStartByte = 0x7f76;
        int noteDurationByte;

        // Iterates through the six 8-byte long presets
        for (int i = 0; i < 0x30; i += 0x8){
            TempoPreset currentPreset = new TempoPreset();

            // For each byte 0-7, assign it to the hashmap keys 80-87 for easy access
            for (int j = 0; j < 0x8; j++){
                noteDurationByte = SMBMusEdit.ROMData[tempoPresetStartByte + i + j];
                int rhythmValue = 0x80 + j;
                currentPreset.getDurations().put(rhythmValue, noteDurationByte);
            }

            tempoPresets.put( i, currentPreset );
        }
    }
}
