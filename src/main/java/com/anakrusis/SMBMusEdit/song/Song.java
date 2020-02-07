package com.anakrusis.SMBMusEdit.song;

import java.util.ArrayList;

public class Song {
    private String name;
    private int headerStart = 0x00;
    boolean hasNoise;

    private int tempoPreset = 0x00;
    private int pulse1Start = 0x00;
    private int pulse2Start = 0x00;
    private int triangleStart = 0x00;
    private int noiseStart = 0x00;

    ArrayList<Note> pulse1Notes;
    ArrayList<Note> pulse2Notes;
    ArrayList<Note> triangleNotes;
    ArrayList<Note> noiseNotes;

    public Song (String name, boolean hasNoise) {
        this.name = name;
        this.hasNoise = hasNoise;

        this.pulse1Notes = new ArrayList<>();
        this.pulse2Notes = new ArrayList<>();
        this.triangleNotes = new ArrayList<>();
        this.noiseNotes = new ArrayList<>();

        Songs.songs.add(this);
    }
    public Song (String name){
        this(name, false);
    }

    public String getName() {
        return name;
    }

    public int getHeaderStart() {
        return headerStart;
    }

    public void setHeaderStart(int headerStart) {
        this.headerStart = headerStart;
    }

    public void setTempoPreset(int tempoPreset) {
        this.tempoPreset = tempoPreset;
    }

    public int getTempoPreset() {
        return tempoPreset;
    }

    public void setPulse2Start(int pulse2Start) {
        this.pulse2Start = pulse2Start;
    }

    public int getPulse2Start() {
        return pulse2Start;
    }

    public void setTriangleStart(int triangleStart) {
        this.triangleStart = triangleStart;
    }

    public int getTriangleStart() {
        return triangleStart;
    }

    public int getPulse1Start() {
        return pulse1Start;
    }

    public void setPulse1Start(int pulse1Start) {
        this.pulse1Start = pulse1Start;
    }

    public boolean hasNoise() {
        return hasNoise;
    }

    public void setNoiseStart(int noiseStart) {
        this.noiseStart = noiseStart;
    }

    public int getNoiseStart() {
        return noiseStart;
    }
}
