package com.anakrusis.SMBMusEdit.player;

public class SongPlayer {
    static int time;
    static boolean isPaused;

    public static void update(){

    }

    public static void setPaused(boolean isPaused) {
        SongPlayer.isPaused = isPaused;
    }

    public static boolean isPaused() {
        return isPaused;
    }

    public static void setTime(int time) {
        SongPlayer.time = time;
    }

    public static int getTime() {
        return time;
    }
}
