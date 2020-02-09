package com.anakrusis.SMBMusEdit.handler;

import com.anakrusis.SMBMusEdit.SMBMusEdit;
import com.anakrusis.SMBMusEdit.song.*;

public class NoteParser {

    static int time;

    public static void parseNotes(Song song){
        time = 0;

        int sq2Start = song.getPulse2Start();
        int sq1Start = song.getPulse1Start();
        int triStart = song.getTriangleStart();
        int noiStart = song.getNoiseStart();

        TempoPreset preset = TempoPresets.tempoPresets.get(song.getTempoPreset());
        PitchPreset pitchPreset = PitchPresets.SQ2_TRI_PITCH_PRESET;

        int sq2Index = sq2Start;
        int sq2Byte = 0x01;
        int currentDuration = 0;
        int currentPitch = 0;
        Note currentNote;

        // Parsing square 2 first, determining the loop point or end of the song
        while (sq2Byte != 0x00){
            sq2Byte = SMBMusEdit.ROMData[sq2Index];
            if (preset.getDurations().get(sq2Byte) != null) {
                currentDuration = preset.getDurations().get(sq2Byte);

            // The value 0x04 is hardcoded as a note rest
            }else if (sq2Byte == 0x04) {
                time += currentDuration;

            // And the value 0x00 is hardcoded as the frame's looping or stopping point
            // (if the song loops or not)
            }else if (sq2Byte == 0x00){
                break;
            }else{
                if (pitchPreset.getPitches().get(sq2Byte) != null){
                    currentPitch = pitchPreset.getPitches().get(sq2Byte);
                    currentNote = new Note (currentPitch + 12, time, currentDuration);
                    song.getPulse2Notes().add(currentNote);
                }else{
                    currentNote = new Note (1, time, currentDuration);
                    song.getPulse2Notes().add(currentNote);
                }

                time += currentDuration;
            }
            sq2Index++;
        }
        song.setEndTick(time);
        time = 0;

        // Parsing triangle next, stopping when reaching the pulse 2 endpoint.
        int triIndex = triStart;
        int triByte;
        while (time < song.getEndTick()) {
            triByte = SMBMusEdit.ROMData[triIndex];
            if (preset.getDurations().get(triByte) != null) {
                currentDuration = preset.getDurations().get(triByte);

            // The value 0x04 is hardcoded as a note rest
            } else if (triByte == 0x04) {
                time += currentDuration;
            } else {
                if (pitchPreset.getPitches().get(triByte) != null) {
                    currentPitch = pitchPreset.getPitches().get(triByte) - 12;
                    currentNote = new Note(currentPitch + 12, time, currentDuration);
                    song.getTriangleNotes().add(currentNote);
                } else {
                    currentNote = new Note(1, time, currentDuration);
                    song.getTriangleNotes().add(currentNote);
                }

                time += currentDuration;
            }
            triIndex++;
        }
        time = 0;

        int sq1Index = sq1Start;
        int sq1Byte;
        int durationKey;
        int pitchKey;
        while (time < song.getEndTick() && song != Songs.UNDERGROUND) {
            sq1Byte = SMBMusEdit.ROMData[sq1Index];

            // Upper two bits plus the parity are used for rhythm (4 * 2 = 8 rhythms)
            durationKey = sq1Byte & 0xc0;
            durationKey = durationKey >> 6;
            durationKey += 0x80;
            if (sq1Byte % 2 == 1){
                durationKey += 0x04;
            }
            currentDuration = preset.getDurations().get(durationKey);

            // Lower 6 bits are used for pitch, with each even and odd pair encoding the same pitch
            pitchKey = sq1Byte & 0x3f;
            if (pitchKey % 2 == 1){
                pitchKey--;
            }

            if (pitchKey != 0x04 && pitchKey != 0x00){
                currentPitch = PitchPresets.SQ2_TRI_PITCH_PRESET.getPitches().get(pitchKey);

                currentNote = new Note (currentPitch + 12, time, currentDuration);
                song.getPulse1Notes().add(currentNote);
            }
            if (pitchKey != 0x00){
                time += currentDuration;
            }
            sq1Index++;
        }
    }
}
