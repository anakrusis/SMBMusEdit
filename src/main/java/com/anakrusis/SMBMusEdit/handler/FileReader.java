package com.anakrusis.SMBMusEdit.handler;

import com.anakrusis.SMBMusEdit.SMBMusEdit;
import com.anakrusis.SMBMusEdit.song.Song;
import com.anakrusis.SMBMusEdit.song.Songs;
import com.anakrusis.SMBMusEdit.song.TempoPreset;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;

public class FileReader {
    public static void init() {
        try{
            byte[] raw;
            int[]  rom;
            // Converting raw data (java reads it as signed) to usable data (unsigned integers)
            raw = Files.readAllBytes(Paths.get("rom\\original mario.nes"));
            rom = new int[ raw.length ];
            for (int i = 0; i < raw.length; i++){
                rom[i] = raw[i] & 0xff;
            }
            SMBMusEdit.ROMData = rom;

            // Initializing the global note duration values
            TempoPresets.init();

            int pointerStartByte = 0x791d;
            for (int i = 0; i < Songs.songs.size(); i++){
                Song song = Songs.songs.get(i);

                // Assigning header start points to songs
                int pointertarget = rom[pointerStartByte + i];
                song.setHeaderStart(pointertarget);

                // Assigning tempo presets to songs
                int tempoPreset = rom[pointerStartByte + pointertarget];
                song.setTempoPreset(tempoPreset);

                // Address of the first byte of pulse 2 data (the first music data)
                int _lowByte = rom[pointerStartByte + pointertarget + 1];
                int highByte = rom[pointerStartByte + pointertarget + 2];
                int cpuAddress = (highByte << 8) | _lowByte;
                int romAddress = cpuAddress - 0x8000 + 0x10;
                song.setPulse2Start(romAddress);

                // Address of the first byte of triangle wave data
                int triangleStart = romAddress + rom[pointerStartByte + pointertarget + 3];
                song.setTriangleStart(triangleStart);

                // Address of the first byte of pulse 1 data
                int pulse1Start = romAddress + rom[pointerStartByte + pointertarget + 4];
                song.setPulse1Start(pulse1Start);

                // Address of the first byte of noise data, which is not found in all songs
                if (song.hasNoise()){
                    int noiseStart = romAddress + rom[pointerStartByte + pointertarget + 5];
                    song.setNoiseStart(noiseStart);
                }

                NoteParser.parseNotes(song);
            }

        } catch (IOException e){
            e.printStackTrace();
        }

    }
}
