package com.anakrusis.SMBMusEdit.handler;

import com.anakrusis.SMBMusEdit.render.RenderNote;
import com.anakrusis.SMBMusEdit.song.Note;
import com.anakrusis.SMBMusEdit.song.Song;
import com.anakrusis.SMBMusEdit.song.Songs;
import javafx.animation.AnimationTimer;
import javafx.scene.input.KeyCode;
import javafx.scene.input.MouseEvent;
import javafx.scene.paint.Color;

import java.util.concurrent.atomic.AtomicReference;

public class PianoRollHandler {

    public static double lastDragX = 0;
    public static double lastDragY = 0;

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

        GuiHandler.pianoRoll.setOnMouseClicked(action -> {

        });

        GuiHandler.pianoRoll.setOnMouseDragged(action -> {

            if (action.isStillSincePress()){
                lastDragX = action.getX();
                lastDragY = action.getY();
            }

            double dragX = action.getX() - lastDragX;
            double dragY = action.getY() - lastDragY;
            GuiHandler.camera.setX( GuiHandler.camera.getX() + dragX );
            GuiHandler.camera.setY( GuiHandler.camera.getY() + dragY );
            lastDragX = action.getX();
            lastDragY = action.getY();
        });

        GuiHandler.pianoRoll.setOnKeyPressed(action -> {

        });
    }
}
