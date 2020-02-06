package com.anakrusis.SMBMusEdit;

import javafx.scene.Scene;
import javafx.scene.canvas.Canvas;
import javafx.scene.canvas.GraphicsContext;
import javafx.scene.control.ListView;
import javafx.scene.control.Menu;
import javafx.scene.control.MenuBar;
import javafx.scene.control.MenuItem;
import javafx.scene.layout.BorderPane;
import javafx.scene.layout.VBox;

public class GuiHandler {

    public static MenuBar menuBar = new MenuBar();

    // file
    static Menu menuFile = new Menu("File");
    static MenuItem newFile = new MenuItem("New");
    static MenuItem opnFile = new MenuItem("Open...");
    static MenuItem savFile = new MenuItem("Save Project");
    static MenuItem saveAs = new MenuItem("Save Project As...");
    static MenuItem importRom = new MenuItem("Import from ROM...");
    static MenuItem exportRom = new MenuItem("Export to ROM...");
    static MenuItem exit = new MenuItem("Exit");

    //edit
    static Menu menuEdit = new Menu("Edit");

    //list of songs
    static ListView<String> songList = new ListView<>();
    //
    static BorderPane pane = new BorderPane();
    static Scene scene = new Scene(pane, 800, 600);
    static Canvas pianoRoll = new Canvas(800, 600);

    static GraphicsContext gc = pianoRoll.getGraphicsContext2D();

    public static void init(){
        menuFile.getItems().addAll(newFile, opnFile, savFile, saveAs, importRom, exportRom, exit);
        menuBar.getMenus().addAll(menuFile, menuEdit);

        for (Song song : Songs.songs){
            songList.getItems().add(song.getName());
        }

        //vb.getChildren().addAll(songList, pianoRoll);
        pane.setCenter(pianoRoll);
        pane.setTop(menuBar);
        pane.setLeft(songList);
    }
}
