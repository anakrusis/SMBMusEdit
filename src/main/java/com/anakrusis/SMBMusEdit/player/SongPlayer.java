package com.anakrusis.SMBMusEdit.player;

import com.anakrusis.SMBMusEdit.handler.GuiHandler;
import com.anakrusis.SMBMusEdit.song.Note;

import javax.sound.midi.*;

public class SongPlayer {
    static int time;
    static boolean isPaused;
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
                midiChannels[0].noteOn(note.getPitch(), 50);
            } else if (note.getOnset() + note.getDuration() == time){
                midiChannels[0].noteOff(note.getPitch());
            }
        }
        for (Note note: GuiHandler.songSelected.getTriangleNotes()){
            if (note.getOnset() == time){
                midiChannels[1].noteOn(note.getPitch(), 50);
            } else if (note.getOnset() + note.getDuration() == time){
                midiChannels[1].noteOff(note.getPitch());
            }
        }
        for (Note note: GuiHandler.songSelected.getPulse1Notes()){
            if (note.getOnset() == time){
                midiChannels[2].noteOn(note.getPitch(), 50);
            } else if (note.getOnset() + note.getDuration() == time){
                midiChannels[2].noteOff(note.getPitch());
            }
        }
        time++;
        if (time == GuiHandler.songSelected.getEndTick() && loopMode){
            time = 0;
            midiChannels[0].allNotesOff();
            midiChannels[1].allNotesOff();
            midiChannels[2].allNotesOff();
        }
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
