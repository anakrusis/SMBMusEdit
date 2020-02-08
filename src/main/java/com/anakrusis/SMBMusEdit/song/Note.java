package com.anakrusis.SMBMusEdit.song;

public class Note {
    int pitch;
    int onset;
    int duration;

    public Note( int pitch, int onset, int duration ){
        this.pitch = pitch;
        this.onset = onset;
        this.duration = duration;
    }

    public int getPitch() {
        return pitch;
    }

    public int getDuration() {
        return duration;
    }

    public void setPitch(int pitch) {
        this.pitch = pitch;
    }

    public void setDuration(int duration) {
        this.duration = duration;
    }

    public int getOnset() {
        return onset;
    }

    public void setOnset(int onset) {
        this.onset = onset;
    }
}
