package com.anakrusis.SMBMusEdit.handler;

import com.anakrusis.SMBMusEdit.song.Song;
import com.anakrusis.SMBMusEdit.song.SoundChannel;

public class NoteParser {
    public static void parseNotes(Song song){
        int sq2Start = song.getPulse2Start();
        int sq1Start = song.getPulse1Start();
        int triStart = song.getTriangleStart();
        int noiStart = song.getNoiseStart();

    }
}
