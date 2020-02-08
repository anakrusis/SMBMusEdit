package com.anakrusis.SMBMusEdit.render;

import com.anakrusis.SMBMusEdit.handler.GuiHandler;
import com.anakrusis.SMBMusEdit.song.Note;
import javafx.scene.paint.Color;

public class RenderNote {
    public static void renderNote( Note note, Camera camera ){
        GuiHandler.gc.setFill( new Color(1, 0, 1, 1.0) );
        GuiHandler.gc.fillRect( 100 - camera.getX(), 100 - camera.getY(), 100, 10 );
    }
}
