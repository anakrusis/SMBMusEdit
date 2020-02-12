package com.anakrusis.SMBMusEdit.handler;

import com.anakrusis.SMBMusEdit.SMBMusEdit;
import com.anakrusis.SMBMusEdit.song.Note;
import com.anakrusis.SMBMusEdit.song.PitchPreset;
import com.anakrusis.SMBMusEdit.song.Song;
import com.anakrusis.SMBMusEdit.song.TempoPreset;

public class NoteWriter {
    public static void writeNote(Note note){
        int index = note.getPitchByte();
        TempoPreset preset = TempoPresets.tempoPresets.get(GuiHandler.songSelected.getTempoPreset());
        int durationValue = preset.getKeys().get(note.getDuration());
        int pitchValue = PitchPresets.SQ2_TRI_PITCH_PRESET.getKeys().get(note.getPitch());

        if (note.getChannel() == GuiHandler.songSelected.getPulse1()){
            // temporarily retaining rhythm data
            durationValue = SMBMusEdit.ROMData[index] & 0xc1;
            SMBMusEdit.ROMData[index] = (pitchValue & 0x7e) | durationValue;

        }else{
            SMBMusEdit.ROMData[index] = pitchValue;
        }
    }
}
