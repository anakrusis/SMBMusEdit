package com.anakrusis.SMBMusEdit.render;

import com.anakrusis.SMBMusEdit.handler.GuiHandler;
import com.anakrusis.SMBMusEdit.song.Note;

public class RenderNote {
    public static void renderNote( Note note, Camera camera ){
        GuiHandler.gc.fillRect( note.getScreenX(), note.getScreenY(), note.getScreenWidth(), 10 );
    }
}
