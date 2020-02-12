package com.anakrusis.SMBMusEdit.handler;

import com.anakrusis.SMBMusEdit.player.SongPlayer;
import com.anakrusis.SMBMusEdit.render.RenderNote;
import com.anakrusis.SMBMusEdit.render.RenderPianoRoll;
import com.anakrusis.SMBMusEdit.song.Note;
import com.anakrusis.SMBMusEdit.song.PitchPreset;
import com.anakrusis.SMBMusEdit.song.Song;
import com.anakrusis.SMBMusEdit.song.Songs;
import javafx.animation.AnimationTimer;
import javafx.scene.image.Image;
import javafx.scene.input.KeyCode;
import javafx.scene.input.MouseEvent;
import javafx.scene.paint.Color;

import java.io.InputStream;
import java.util.concurrent.atomic.AtomicReference;

public class PianoRollHandler {

    public static double lastDragX = 0;
    public static double lastDragY = 0;
    public static boolean draggingNote = false;
    public static Note noteSelected = null;
    // When clicked, a note plays for 10 ticks and then stops
    public static int noteSelectedPlayTimer = 0;

    public static double playLinePos = 200;

    public static Image pianoTexture = new Image("piano.png");

    public static void init(){

        new AnimationTimer()
        {

            Song lastTickSong;

            public void handle(long currentNanoTime)
            {
                int index = GuiHandler.songList.getSelectionModel().getSelectedIndex();
                GuiHandler.songSelected = Songs.songs.get(index);

                RenderPianoRoll.renderPianoRoll();

                if (GuiHandler.followMode && !SongPlayer.isPaused()){
                    GuiHandler.camera.setX( (SongPlayer.getTime() * GuiHandler.camera.getZoom()) - playLinePos );
                }

                if (lastTickSong != GuiHandler.songSelected){
                    GuiHandler.onSongChange();
                }

                if (!SongPlayer.isPaused()){
                    SongPlayer.update();
                }
                noteSelectedPlayTimer--;
                if (noteSelectedPlayTimer == 0){
                    SongPlayer.stopNote(noteSelected, 0);
                    noteSelected = null;
                }

                lastTickSong = GuiHandler.songSelected;
            }
        }.start();

        GuiHandler.pianoRoll.setOnMousePressed(action -> {
            Song song = GuiHandler.songSelected;
            for (Note note : song.getPulse2Notes()){
                if (isPointCollidingInBox(action.getX(), action.getY(), note.getScreenX(), note.getScreenY(), note.getScreenWidth(), 10)){
                    noteSelected = note;
                    SongPlayer.playNote(noteSelected, 0);
                    noteSelectedPlayTimer = 10;
                }
            }
            for (Note note : song.getTriangleNotes()){
                if (isPointCollidingInBox(action.getX(), action.getY(), note.getScreenX(), note.getScreenY(), note.getScreenWidth(), 10)){
                    noteSelected = note;
                    SongPlayer.playNote(noteSelected, 0);
                    noteSelectedPlayTimer = 10;
                }
            }
            for (Note note : song.getPulse1Notes()){
                if (isPointCollidingInBox(action.getX(), action.getY(), note.getScreenX(), note.getScreenY(), note.getScreenWidth(), 10)){
                    noteSelected = note;
                    SongPlayer.playNote(noteSelected, 0);
                    noteSelectedPlayTimer = 10;
                }
            }
        });

        GuiHandler.pianoRoll.setOnMouseDragged(action -> {

            if (action.isStillSincePress()){
                lastDragX = action.getX();
                lastDragY = action.getY();
            }

            double dragX = action.getX() - lastDragX;
            double dragY = action.getY() - lastDragY;
            GuiHandler.camera.setX( GuiHandler.camera.getX() - dragX );
            GuiHandler.camera.setY( GuiHandler.camera.getY() - dragY );
            lastDragX = action.getX();
            lastDragY = action.getY();
        });
    }

    public static boolean isPointCollidingInBox( double pointx, double pointy, double boxX, double boxY, double boxWidth, double boxHeight){
        return (pointx > boxX && pointx < (boxX + boxWidth) &&
                pointy > boxY && pointy < (boxY + boxHeight));
    }
}
