package com.anakrusis.SMBMusEdit.song;

import com.anakrusis.SMBMusEdit.handler.GuiHandler;

public class Note {
    int pitch;
    int onset;
    int duration;
    Channel channel;
    int pitchByte;

    public Note( int pitch, int onset, int duration, Channel channel, int pitchByte ){
        this.pitch = pitch;
        this.onset = onset;
        this.duration = duration;
        this.channel = channel;
        this.pitchByte = pitchByte;
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
        int sub = (this.channel == GuiHandler.songSelected.getTriangle()) ? 12 : 0;
        return -((this.pitch - sub) * 10) - GuiHandler.camera.getY();
    }

    public double getScreenWidth(){
        return this.getDuration() * GuiHandler.camera.getZoom() - 2;
    }

    public Channel getChannel() {
        return channel;
    }

    public void setChannel(Channel channel) {
        this.channel = channel;
    }

    public int getPitchByte() {
        return pitchByte;
    }

    public void setPitchByte(int pitchByte) {
        this.pitchByte = pitchByte;
    }
}
