package com.anakrusis.SMBMusEdit;

import java.util.ArrayList;

public class Song {
    private String name;
    private byte headerStart = 0x00;

    ArrayList<Note> pulse1Notes;
    ArrayList<Note> pulse2Notes;
    ArrayList<Note> triangleNotes;
    ArrayList<Note> noiseNotes;

    public Song (String name) {
        this.name = name;
        this.pulse1Notes = new ArrayList<>();
        this.pulse2Notes = new ArrayList<>();
        this.triangleNotes = new ArrayList<>();
        this.noiseNotes = new ArrayList<>();

        Songs.songs.add(this);
    }

    public String getName() {
        return name;
    }

    public byte getHeaderStart() {
        return headerStart;
    }

    public void setHeaderStart(byte headerStart) {
        this.headerStart = headerStart;
    }
}
