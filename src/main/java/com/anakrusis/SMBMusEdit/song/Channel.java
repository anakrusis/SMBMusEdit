package com.anakrusis.SMBMusEdit.song;

import java.util.ArrayList;

public class Channel {
    ArrayList<Note> notes;

    public Channel(){
        notes = new ArrayList<>();
    }
    public ArrayList<Note> getNotes() {
        return notes;
    }
}
