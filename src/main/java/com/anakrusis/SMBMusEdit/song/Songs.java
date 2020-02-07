package com.anakrusis.SMBMusEdit.song;

import com.anakrusis.SMBMusEdit.song.Song;

import java.util.ArrayList;

public class Songs {

    public static ArrayList<Song> songs = new ArrayList<>();

    public static Song SONG_DEATH = new Song("Death");
    public static Song SONG_GAME_OVER = new Song("Game Over");
    public static Song SONG_ENDING = new Song("Ending");
    public static Song SONG_CASTLE_COMPLETE = new Song ("Castle Complete");
    public static Song SONG_GAME_OVER_2 = new Song("Game Over (Alternate)");
    public static Song SONG_LEVEL_COMPLETE = new Song ("Level Complete");
    public static Song SONG_HURRY_UP = new Song("Hurry Up");
    public static Song SILENCE_1 = new Song("Silence #1");
    public static Song UNKNOWN = new Song("?????");
    public static Song UNDERWATER = new Song ("Underwater", true);
    public static Song UNDERGROUND = new Song ("Underground");
    public static Song CASTLE = new Song ("Castle");
    public static Song CLOUD = new Song ("Cloud", true);
    public static Song PRE_PIPE = new Song ("Pre-Pipe Theme", true);
    public static Song STARMAN = new Song ("Starman Theme", true);
    public static Song WORLD_TITLE = new Song ("World Title");

    public static void init(){
        for (int i = 0; i < 33; i++){
            Song OVERWORLD = new Song("Overworld " + (i + 1), true);
        }
    }
}
