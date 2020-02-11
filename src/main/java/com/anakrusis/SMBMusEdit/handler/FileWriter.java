package com.anakrusis.SMBMusEdit.handler;

import com.anakrusis.SMBMusEdit.SMBMusEdit;
import com.anakrusis.SMBMusEdit.song.Song;
import com.anakrusis.SMBMusEdit.song.Songs;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;

public class FileWriter {
    public static void writeROM(String path) {
        int[] rom = SMBMusEdit.ROMData;
        byte[] raw = new byte[rom.length];

        int pointerStartByte = 0x791d;
        for (int i = 0; i < Songs.songs.size(); i++) {
            Song song = Songs.songs.get(i);

            // Assigning header start points to songs
            int pointertarget = song.getHeaderStart();
            rom[pointerStartByte + i] = pointertarget;

            // Assigning tempo presets to songs
            int tempoPreset = song.getTempoPreset();
            rom[pointerStartByte + pointertarget] = tempoPreset;

            NoteWriter.writeNotesToROM(song);
        }

        for (int i = 0; i < raw.length; i++){
            raw[i] = (byte) (rom[i] & 0xff);
        }
        try {
            Files.write(Paths.get("rom\\original mario.nes"), raw);
        }catch (IOException e){

        }

    }
}
