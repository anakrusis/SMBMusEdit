package com.anakrusis.SMBMusEdit;

import javafx.animation.AnimationTimer;
import javafx.application.Application;
import javafx.scene.Scene;
import javafx.scene.canvas.Canvas;
import javafx.scene.canvas.GraphicsContext;
import javafx.scene.control.Menu;
import javafx.scene.control.MenuBar;
import javafx.scene.control.MenuItem;
import javafx.scene.layout.StackPane;
import javafx.scene.layout.VBox;
import javafx.scene.paint.Color;
import javafx.stage.Stage;

public class SMBMusEdit extends Application {
    public static void main (String[] args){
        launch(args);
    }

    @Override
    public void start(Stage primaryStage) {

        Songs.init();
        GuiHandler.init();

        new AnimationTimer()
        {
            public void handle(long currentNanoTime)
            {
                // Clear the canvas
                GuiHandler.gc.setFill( new Color(0, 0, 0, 1.0) );

                GuiHandler.gc.fillRect(0,0, 800,600);

                int index = GuiHandler.songList.getSelectionModel().getSelectedIndex();

                GuiHandler.gc.setFill( new Color(1, 1, 1, 1.0) );
                GuiHandler.gc.fillText("Selected item: " + index, 100, 100);
            }
        }.start();

        primaryStage.setTitle("SMBMusEdit 0.1.0pre by anakrusis");
        primaryStage.setScene(GuiHandler.scene);
        primaryStage.show();
    }
}
