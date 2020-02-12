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

            // And the value 0x00 is hardcoded as the frame's looping or stopping point
            // (if the song loops or not)
            }else if (sq2Byte == 0x00){
                break;
            }else{
                if (pitchPreset.getPitches().get(sq2Byte) != null){
                    currentPitch = pitchPreset.getPitches().get(sq2Byte);
                    currentNote = new Note (currentPitch, time, currentDuration, song.getPulse2(), sq2Index);
                    song.getPulse2Notes().add(currentNote);
                }else{
                    currentNote = new Note (1, time, currentDuration, song.getPulse2(), sq2Index);
                    song.getPulse2Notes().add(currentNote);
                }

                time += currentDuration;
            }
            sq2Index++;
        }
        song.setEndTick(time);
        time = 0;

        // If the channel is the same then they will point to the same channel
        // Parsing triangle next, stopping when reaching the pulse 2 endpoint.
        int triIndex = triStart;
        int triByte;
        while (time < song.getEndTick()) {
            triByte = SMBMusEdit.ROMData[triIndex];
            if (preset.getDurations().get(triByte) != null) {
                currentDuration = preset.getDurations().get(triByte);
            } else {
                if (pitchPreset.getPitches().get(triByte) != null) {
                    currentPitch = pitchPreset.getPitches().get(triByte);
                    currentNote = new Note(currentPitch, time, currentDuration, song.getTriangle(), triIndex);
                    song.getTriangleNotes().add(currentNote);
                } else {
                    currentNote = new Note(1, time, currentDuration, song.getTriangle(), triIndex);
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

            // Upper two bits plus the least significant are used for rhythm (8 in total)
            durationKey = sq1Byte & 0xc0;
            durationKey = durationKey >> 6;
            durationKey += 0x80;
            if (sq1Byte % 2 == 1){
                durationKey += 0x04;
            }
            currentDuration = preset.getDurations().get(durationKey);

            // The middle 5 bits are used for pitch. (This is a smaller pitch set than pulse 2 and tri)
            pitchKey = sq1Byte & 0x3e;

            if (pitchKey != 0x00){
                currentPitch = PitchPresets.SQ2_TRI_PITCH_PRESET.getPitches().get(pitchKey);

                currentNote = new Note (currentPitch, time, currentDuration, song.getPulse1(), sq1Index);
                song.getPulse1Notes().add(currentNote);

                time += currentDuration;
            }
            sq1Index++;
        }
    }
}
