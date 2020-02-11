package com.anakrusis.SMBMusEdit.render;

import com.anakrusis.SMBMusEdit.handler.GuiHandler;
import com.anakrusis.SMBMusEdit.handler.PianoRollHandler;
import com.anakrusis.SMBMusEdit.song.Note;
import javafx.scene.paint.Color;

public class RenderPianoRoll {
    public static void renderPianoRoll(){
        // Clear the canvas
        GuiHandler.gc.setFill( new Color(0, 0, 0, 1.0) );
        GuiHandler.gc.fillRect(0,0, 1800,1000);

        // Note rendering
        GuiHandler.gc.setFill( new Color(1, 0, 1, 1.0) );
        for (Note note : GuiHandler.songSelected.getPulse2Notes()){
            RenderNote.renderNote( note, GuiHandler.camera );
        }
        GuiHandler.gc.setFill( new Color(0.5, 0, 0.7, 1.0) );
        for (Note note : GuiHandler.songSelected.getPulse1Notes()){
            RenderNote.renderNote( note, GuiHandler.camera );
        }
        GuiHandler.gc.setFill( new Color(0, 0, 1, 1.0) );
        for (Note note : GuiHandler.songSelected.getTriangleNotes()){
            RenderNote.renderNote( note, GuiHandler.camera );
        }

        // Side piano
        for (int i = -7; i < -2; i++){
            double pianoY = (120 * i) - GuiHandler.camera.getY() + 10;
            GuiHandler.gc.drawImage(PianoRollHandler.pianoTexture, 0, pianoY);
        }
        // Play line
        GuiHandler.gc.setFill( new Color (1, 1, 1, 1));
        GuiHandler.gc.fillRect(PianoRollHandler.playLinePos, 0, 2, 1000);

    }
}
