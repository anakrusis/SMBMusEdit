package com.anakrusis.SMBMusEdit.render;

import com.anakrusis.SMBMusEdit.handler.GuiHandler;
import com.anakrusis.SMBMusEdit.song.Note;
import javafx.scene.paint.Color;

public class RenderNote {
    public static void renderNote( Note note, Camera camera ){
        GuiHandler.gc.fillRect( note.getOnset() - camera.getX(), 100 - camera.getY(), note.getDuration() * 0.9, 10 );
    }
}
