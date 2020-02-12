package com.anakrusis.SMBMusEdit.song;

import java.util.ArrayList;

public class Song {
    private String name;
    private int headerStart = 0x00;
    boolean hasNoise;

    // tick in which either the song goes to the next pattern, or ends
    // dictated by square 2 giving the value 00 at this time
    private int endTick;

    private int tempoPreset = 0x00;
    private int pulse1Start = 0x00;
    private int pulse2Start = 0x00;
    private int triangleStart = 0x00;
    private int noiseStart = 0x00;

    Channel pulse1;
    Channel pulse2;
    Channel triangle;
    Channel noise;

    public Song (String name, boolean hasNoise) {
        this.name = name;
        this.hasNoise = hasNoise;
        this.clearChannels();

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

    public ArrayList<Note> getPulse1Notes() {
        return pulse1.getNotes();
    }

    public ArrayList<Note> getPulse2Notes() {
        return pulse2.getNotes();
    }

    public ArrayList<Note> getTriangleNotes() {
        return triangle.getNotes();
    }

    public void setEndTick(int endTick) {
        this.endTick = endTick;
    }

    public int getEndTick() {
        return endTick;
    }

    public Channel getPulse1() {
        return pulse1;
    }

    public Channel getPulse2() {
        return pulse2;
    }

    public Channel getTriangle() {
        return triangle;
    }

    public Channel getNoise() {
        return noise;
    }

    public void setPulse1(Channel pulse1) {
        this.pulse1 = pulse1;
    }

    public void setPulse2(Channel pulse2) {
        this.pulse2 = pulse2;
    }

    public void setTriangle(Channel triangle) {
        this.triangle = triangle;
    }

    public void setNoise(Channel noise) {
        this.noise = noise;
    }

    public void clearChannels(){
        this.pulse1 = new Channel();
        this.pulse2 = new Channel();
        this.triangle = new Channel();
        this.noise = new Channel();
    }
}
