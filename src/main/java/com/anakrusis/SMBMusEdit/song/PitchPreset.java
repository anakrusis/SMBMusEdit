package com.anakrusis.SMBMusEdit.song;

import com.anakrusis.SMBMusEdit.handler.GuiHandler;

import java.util.HashMap;

public class PitchPreset {
    // Key: encoded byte
    // Value: midi note value
    HashMap<Integer, Integer> pitches;

    // Vice versa
    HashMap<Integer, Integer> keys;

    public PitchPreset() {
        pitches = new HashMap<>();
        keys = new HashMap<>();
    }

    public HashMap<Integer, Integer> getPitches() {
        return pitches;
    }

    public HashMap<Integer, Integer> getKeys() {
        return keys;
    }

    public int getNearestPitch (Note note, int offset, boolean above){
        int pitch = note.getPitch() + offset;

        int nearestPitchDist = 100000;
        int nearestPitch = -1;
        int currentPitchDist;
        int currentPitch;
        for (Integer key : pitches.keySet()){
            currentPitchDist = Math.abs(pitches.get(key) - pitch);
            currentPitch = pitches.get(key);

            if (currentPitchDist < nearestPitchDist){
                if ( (above && currentPitch >= pitch) ||
                    (!above && currentPitch <= pitch)){

                    // Pulse 1 has an even more limited selection of notes, just within byte values 00-3F
                    if (note.getChannel() == GuiHandler.songSelected.getPulse1()){
                        if (key > 0x00 && key < 0x3f){
                            nearestPitchDist = currentPitchDist;
                            nearestPitch = pitches.get(key);
                        }
                    }else{
                        nearestPitchDist = currentPitchDist;
                        nearestPitch = pitches.get(key);
                    }
                }
            }
        }

        return nearestPitch;
    }
}
