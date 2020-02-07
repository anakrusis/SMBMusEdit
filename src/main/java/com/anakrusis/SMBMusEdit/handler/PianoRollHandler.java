package com.anakrusis.SMBMusEdit.handler;

import com.anakrusis.SMBMusEdit.render.RenderNote;
import com.anakrusis.SMBMusEdit.song.Note;
import com.anakrusis.SMBMusEdit.song.Song;
import com.anakrusis.SMBMusEdit.song.Songs;
import javafx.animation.AnimationTimer;
import javafx.scene.input.KeyCode;
import javafx.scene.paint.Color;

public class PianoRollHandler {
    public static void init(){
        new AnimationTimer()
        {

            Song lastTickSong;

            public void handle(long currentNanoTime)
            {
                int index = GuiHandler.songList.getSelectionModel().getSelectedIndex();
                GuiHandler.songSelected = Songs.songs.get(index);

                if (lastTickSong != GuiHandler.songSelected){
                    GuiHandler.onSongChange();
                }
                // Clear the canvas
                GuiHandler.gc.setFill( new Color(0, 0, 0, 1.0) );
                GuiHandler.gc.fillRect(0,0, 1800,1000);

                for (Note note : GuiHandler.songSelected.getPulse2Notes()){
                    RenderNote.renderNote( note, GuiHandler.camera );
                }

                lastTickSong = GuiHandler.songSelected;
            }
        }.start();

        GuiHandler.pianoRoll.setOnDragDetected(action -> {

        });
        GuiHandler.pianoRoll.setOnMouseDragged(action -> {

        });
        GuiHandler.pianoRoll.setOnKeyPressed(action -> {
            if (action.getCode() == KeyCode.A){
                GuiHandler.camera.setX( GuiHandler.camera.getX() + 1 );
            }
        });
    }
}
