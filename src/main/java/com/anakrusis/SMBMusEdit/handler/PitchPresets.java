package com.anakrusis.SMBMusEdit.handler;

import com.anakrusis.SMBMusEdit.song.PitchPreset;

import java.util.HashMap;

public class PitchPresets {
    public static PitchPreset SQ2_TRI_PITCH_PRESET = new PitchPreset();

    public static void init() {

        // Temporary pitch stuff
        // TODO Replace this with proper pitch value reading from ROM
        HashMap<Integer, Integer> p = SQ2_TRI_PITCH_PRESET.getPitches();
        p.put(0x58, 91); // G-6
        p.put(0x56, 88); // E-6
        p.put(0x02, 86); // D-6
        p.put(0x54, 84); // C-6

        p.put(0x52, 82); // Bb5
        p.put(0x50, 80); // Ab5
        p.put(0x4e, 79); // G-5
        p.put(0x4c, 77); // F-5
        p.put(0x44, 76); // E-5
        p.put(0x4a, 75); // Eb5
        p.put(0x48, 74); // D-5
        p.put(0x46, 73); // C#5
        p.put(0x64, 72); // C-5

        p.put(0x42, 71); // B-4
        p.put(0x3e, 70); // Bb4
        p.put(0x40, 69); // A-4
        p.put(0x3c, 68); // Ab4
        p.put(0x3a, 67); // G-4
        p.put(0x38, 66); // F#4
        p.put(0x36, 65); // F-4
        p.put(0x34, 64); // E-4
        p.put(0x32, 63); // Eb4
        p.put(0x30, 62); // D-4
        p.put(0x2e, 61); // C#4
        p.put(0x2c, 60); // C-4 (middle C)

        p.put(0x2a, 59); // B-3
        p.put(0x28, 58); // Bb3
        p.put(0x26, 57); // A-3
        p.put(0x24, 56); // Ab3
        p.put(0x22, 55); // G-3
        p.put(0x20, 54); // F#3
        p.put(0x1e, 53); // F-3
        p.put(0x1c, 52); // E-3
        p.put(0x1a, 51); // Eb3
        p.put(0x18, 50); // D-3
        p.put(0x16, 49); // C#3
        p.put(0x14, 48); // C-3

        p.put(0x12, 47); // B-2
        p.put(0x10, 46); // Bb2
        p.put(0x62, 45); // A-2
        p.put(0x0e, 44); // Ab2
        p.put(0x0c, 43); // G-2
        p.put(0x0a, 42); // F#2
        p.put(0x08, 41); // F-2
        p.put(0x06, 40); // E-2
        p.put(0x60, 39); // Eb2
        p.put(0x5e, 38); // D-2
        p.put(0x5c ,36); // C-2
    }
}
