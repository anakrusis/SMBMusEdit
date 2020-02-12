package com.anakrusis.SMBMusEdit.player;

import com.anakrusis.SMBMusEdit.handler.GuiHandler;
import com.anakrusis.SMBMusEdit.song.Note;

import javax.sound.midi.*;

public class SongPlayer {
    static int time;
    static boolean isPaused = true;
    static boolean loopMode = true;

    static MidiChannel[] midiChannels;

    public static void init() {


        try {
            Synthesizer midiSynth =  MidiSystem.getSynthesizer();
            midiSynth.open();
            Instrument[] instr = midiSynth.getDefaultSoundbank().getInstruments();
            midiChannels = midiSynth.getChannels();
            midiSynth.loadInstrument(instr[0]);
            midiChannels[0].programChange(80);
            midiChannels[1].programChange(80);
            midiChannels[2].programChange(80);

        } catch (MidiUnavailableException e){

        }
    }

    public static void update(){
        for (Note note: GuiHandler.songSelected.getPulse2Notes()){
            if (note.getOnset() == time){
                playNote(note, 0);
            } else if (note.getOnset() + note.getDuration() == time){
                stopNote(note, 0);
            }
        }
        for (Note note: GuiHandler.songSelected.getTriangleNotes()){
            if (note.getOnset() == time){
                playNote(note, 1);
            } else if (note.getOnset() + note.getDuration() == time){
                stopNote(note, 1);
            }
        }
        for (Note note: GuiHandler.songSelected.getPulse1Notes()){
            if (note.getOnset() == time){
                playNote(note, 2);
            } else if (note.getOnset() + note.getDuration() == time){
                stopNote(note, 2);
            }
        }
        time++;
        if (time == GuiHandler.songSelected.getEndTick()){
            if (loopMode){
                time = 0;
            }else{
                isPaused = true;
            }
            midiChannels[0].allNotesOff();
            midiChannels[1].allNotesOff();
            midiChannels[2].allNotesOff();
        }
    }

    public static void playNote(Note note, int channel)
    {
        int add = 12;
        if (note.getChannel() == GuiHandler.songSelected.getTriangle()){
            add = 0;
        }
        midiChannels[channel].noteOn(note.getPitch() + add, 50);
    }
    public static void stopNote(Note note, int channel){
        int add = 12;
        if (note.getChannel() == GuiHandler.songSelected.getTriangle()){
            add = 0;
        }
        midiChannels[channel].noteOff(note.getPitch() + add, 50);
    }

    public static void playSong(boolean loopMode) {
        SongPlayer.setTime(0);
        SongPlayer.setPaused(false);
        SongPlayer.setLoopMode(loopMode);
        SongPlayer.getMidiChannels()[0].allNotesOff();
        SongPlayer.getMidiChannels()[1].allNotesOff();
        SongPlayer.getMidiChannels()[2].allNotesOff();
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

    public static MidiChannel[] getMidiChannels() {
        return midiChannels;
    }

    public static void setLoopMode(boolean loopMode) {
        SongPlayer.loopMode = loopMode;
    }

    public static boolean getLoopMode() {
        return loopMode;
    }
}
