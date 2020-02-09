package com.anakrusis.SMBMusEdit.song;

import com.anakrusis.SMBMusEdit.handler.GuiHandler;

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

    public double getScreenX() {
        return (onset * GuiHandler.camera.getZoom()) - GuiHandler.camera.getX();
    }

    public double getScreenY() {
        return -(this.pitch * 10) - GuiHandler.camera.getY();
    }

    public double getScreenWidth(){
        return this.getDuration() * GuiHandler.camera.getZoom() - 2;
    }
}
