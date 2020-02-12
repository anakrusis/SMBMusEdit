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

        for (int i = 0; i < raw.length; i++){
            raw[i] = (byte) (SMBMusEdit.ROMData[i] & 0xff);
        }
        try {
            Files.write(Paths.get("rom\\new mario.nes"), raw);
            ;
        }catch (IOException e){
            e.printStackTrace();
        }

    }
}
