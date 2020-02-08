package com.anakrusis.SMBMusEdit.handler;

import com.anakrusis.SMBMusEdit.SMBMusEdit;
import com.anakrusis.SMBMusEdit.song.Note;
import com.anakrusis.SMBMusEdit.song.Song;
import com.anakrusis.SMBMusEdit.song.SoundChannel;
import com.anakrusis.SMBMusEdit.song.TempoPreset;

public class NoteParser {

    static int time;

    public static void parseNotes(Song song){
        time = 0;

        int sq2Start = song.getPulse2Start();
        int sq1Start = song.getPulse1Start();
        int triStart = song.getTriangleStart();
        int noiStart = song.getNoiseStart();

        TempoPreset preset = TempoPresets.tempoPresets.get(song.getTempoPreset());

        int sq2Index = sq2Start;
        int sq2Byte = 0x01;
        int currentDuration = 0;
        int currentPitch = 0;
        Note currentNote;

        while (sq2Byte != 0x00){
            sq2Byte = SMBMusEdit.ROMData[sq2Index];
            if (preset.getDurations().get(sq2Byte) != null) {
                currentDuration = preset.getDurations().get(sq2Byte);
            }else if (sq2Byte == 0x04) {
                time += currentDuration;
            }else if (sq2Byte == 0x00){
                break;
            }else{
                currentNote = new Note (1, time, currentDuration);
                song.getPulse2Notes().add(currentNote);
                time += currentDuration;
            }
            sq2Index++;
        }

    }
}
