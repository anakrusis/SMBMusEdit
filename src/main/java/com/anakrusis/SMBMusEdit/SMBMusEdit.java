package com.anakrusis.SMBMusEdit;

import com.anakrusis.SMBMusEdit.handler.FileReader;
import com.anakrusis.SMBMusEdit.handler.GuiHandler;
import com.anakrusis.SMBMusEdit.song.Song;
import com.anakrusis.SMBMusEdit.song.Songs;
import javafx.animation.AnimationTimer;
import javafx.application.Application;
import javafx.scene.paint.Color;
import javafx.stage.Stage;

public class SMBMusEdit extends Application {

    public static byte[] rawData;
    public static int[] ROMData;

    public static void main (String[] args){
        launch(args);
    }

    @Override
    public void start(Stage primaryStage) {

        Songs.init();
        FileReader.init();
        GuiHandler.init();

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

                GuiHandler.gc.setFill( new Color(1, 1, 1, 1.0) );
                GuiHandler.gc.fillText("Head: " + Songs.songs.get(index).getHeaderStart(), 100, 100);

                lastTickSong = GuiHandler.songSelected;
            }
        }.start();

        primaryStage.setTitle("SMBMusEdit 0.1.0pre by anakrusis");
        primaryStage.setScene(GuiHandler.scene);
        primaryStage.show();
    }
}
