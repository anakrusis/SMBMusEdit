package com.anakrusis.SMBMusEdit;

import com.anakrusis.SMBMusEdit.handler.FileReader;
import com.anakrusis.SMBMusEdit.handler.GuiHandler;
import com.anakrusis.SMBMusEdit.handler.PianoRollHandler;
import com.anakrusis.SMBMusEdit.song.Song;
import com.anakrusis.SMBMusEdit.song.Songs;
import javafx.animation.AnimationTimer;
import javafx.application.Application;
import javafx.scene.paint.Color;
import javafx.stage.Stage;

public class SMBMusEdit extends Application {

    public static int[] ROMData;

    public static Stage primaryStage;

    public static void main (String[] args){
        launch(args);
    }

    @Override
    public void start(Stage stage) {

        primaryStage = stage;

        Songs.init();
        FileReader.init();
        GuiHandler.init();
        PianoRollHandler.init();

        primaryStage.setTitle("SMBMusEdit 0.1.0pre by anakrusis");
        primaryStage.setScene(GuiHandler.scene);
        primaryStage.show();
    }
}
