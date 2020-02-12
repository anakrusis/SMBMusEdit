package com.anakrusis.SMBMusEdit.handler;

import com.anakrusis.SMBMusEdit.SMBMusEdit;
import com.anakrusis.SMBMusEdit.player.SongPlayer;
import com.anakrusis.SMBMusEdit.render.Camera;
import com.anakrusis.SMBMusEdit.song.Note;
import com.anakrusis.SMBMusEdit.song.Song;
import com.anakrusis.SMBMusEdit.song.Songs;
import javafx.geometry.Insets;
import javafx.geometry.Orientation;
import javafx.scene.Scene;
import javafx.scene.canvas.Canvas;
import javafx.scene.canvas.GraphicsContext;
import javafx.scene.control.*;
import javafx.scene.input.KeyCode;
import javafx.scene.layout.BorderPane;
import javafx.scene.layout.ColumnConstraints;
import javafx.scene.layout.FlowPane;
import javafx.scene.layout.GridPane;

public class GuiHandler {

    public static Song songSelected;
    public static Camera camera = new Camera(-120,-980);
    public static boolean followMode = true;

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
    public static ListView<String> songList = new ListView<>();

    // song details
    public static GridPane songSettings = new GridPane();
    public static TextField headerStart = new TextField();
    public static TextField tempoPreset = new TextField();
    public static TextField pulse2Start = new TextField();
    public static TextField pulse1Start = new TextField();
    public static TextField trngleStart = new TextField();
    public static TextField _noiseStart = new TextField();
    public static Label headerStartLbl = new Label("Header Start: ");
    public static Label tempoPresetLbl = new Label("Tempo Preset: ");
    public static Label pulse2StartLbl = new Label("Pulse 2 Start: ");
    public static Label pulse1StartLbl = new Label("Pulse 1 Start: ");
    public static Label triangleStartLbl = new Label("Triangle Start: ");
    public static Label noiseStartLbl = new Label("Noise Start: ");

    // Top bar stuff
    public static Button playButton = new Button("Play \u25B6");
    public static Button loopButton = new Button("Play & Loop \uD83D\uDD01");
    public static Button stopButton = new Button("Stop \u23F9");
    public static MenuBar menuBar = new MenuBar();
    public static FlowPane playbackBar = new FlowPane(Orientation.HORIZONTAL);
    public static FlowPane topPane = new FlowPane(Orientation.VERTICAL);

    // The main stuff
    public static BorderPane mainPane = new BorderPane();
    public static FlowPane leftPane = new FlowPane(Orientation.HORIZONTAL);
    public static Scene scene = new Scene(mainPane, 1000, 650);
    public static Canvas pianoRoll = new Canvas(1800, 1000);
    public static GraphicsContext gc = pianoRoll.getGraphicsContext2D();

    public static void init(){
        menuFile.getItems().addAll(newFile, opnFile, savFile, saveAs, importRom, exportRom, exit);
        menuBar.getMenus().addAll(menuFile, menuEdit);

        playbackBar.getChildren().addAll(playButton, loopButton, stopButton);

        for (Song song : Songs.songs){

            String headerstart = String.format("%02X", song.getHeaderStart());
            songList.getItems().add(song.getName() + " (" + headerstart + ")");
        }
        songList.getSelectionModel().selectFirst();
        GuiHandler.songSelected = Songs.songs.get( songList.getSelectionModel().getSelectedIndex() );

        songSettings.getColumnConstraints().add( new ColumnConstraints(100));
        songSettings.getColumnConstraints().add( new ColumnConstraints(50));

        songSettings.add(headerStartLbl, 0, 1);
        songSettings.add(tempoPresetLbl, 0, 2);
        songSettings.add(pulse2StartLbl, 0, 3);
        songSettings.add(pulse1StartLbl, 0, 4);
        songSettings.add(triangleStartLbl, 0, 5);
        songSettings.add(noiseStartLbl, 0, 6);

        songSettings.add(headerStart, 1, 1);
        songSettings.add(tempoPreset, 1, 2);
        songSettings.add(pulse2Start, 1, 3);
        songSettings.add(pulse1Start, 1, 4);
        songSettings.add(trngleStart, 1, 5);
        songSettings.add(_noiseStart, 1, 6);

        songSettings.setHgap(8);
        songSettings.setVgap(8);
        songSettings.setPadding(new Insets(8));

        //songList.setMaxHeight(300);
        leftPane.getChildren().addAll(songList, songSettings);

        topPane.getChildren().addAll(menuBar, playbackBar);
        topPane.setMaxHeight(50);

        mainPane.setCenter(pianoRoll);
        mainPane.setTop(topPane);
        mainPane.setLeft(leftPane);

        scene.setOnKeyPressed( action -> {
            if (action.getCode() == KeyCode.W || action.getCode() == KeyCode.S){
                int newPitch = -1;
                Note noteSelected = PianoRollHandler.noteSelected;
                if (action.getCode() == KeyCode.W){
                    newPitch = PitchPresets.SQ2_TRI_PITCH_PRESET.getNearestPitch(noteSelected, 1, true);
                }
                if (action.getCode() == KeyCode.S){
                    newPitch = PitchPresets.SQ2_TRI_PITCH_PRESET.getNearestPitch(noteSelected, -1, false);
                }
                if (newPitch != -1 && newPitch != noteSelected.getPitch()){
                    SongPlayer.stopNote(noteSelected, 0);
                    noteSelected.setPitch(newPitch);
                    NoteWriter.writeNote(noteSelected);
                    GuiHandler.onNoteChange();
                    SongPlayer.playNote(noteSelected, 0);
                    PianoRollHandler.noteSelectedPlayTimer = 10;
                }
            }
        });

        exit.setOnAction( action -> {
            SMBMusEdit.primaryStage.close();
        });

        stopButton.setOnAction( action -> {
           SongPlayer.setPaused(true);
           SongPlayer.getMidiChannels()[0].allNotesOff();
           SongPlayer.getMidiChannels()[1].allNotesOff();
           SongPlayer.getMidiChannels()[2].allNotesOff();
        });

        playButton.setOnAction( action -> {
            SongPlayer.playSong(false);
        });

        loopButton.setOnAction( action -> {
            SongPlayer.playSong(true);
        });

        exportRom.setOnAction( action -> {
            FileWriter.writeROM("");
        });
    }

    public static void onNoteChange(){
        for (Song song: Songs.songs){
            song.clearChannels();
            NoteParser.parseNotes(song);
        }
    }

    public static void onSongChange(){
        headerStart.setText( String.format( "%02X", songSelected.getHeaderStart() ) );
        tempoPreset.setText( String.format( "%02X", songSelected.getTempoPreset() ) );
        pulse2Start.setText( String.format( "%04X", songSelected.getPulse2Start() ) );
        pulse1Start.setText( String.format( "%04X", songSelected.getPulse1Start() ) );
        trngleStart.setText( String.format( "%04X", songSelected.getTriangleStart() ) );
        _noiseStart.setText( String.format( "%04X", songSelected.getNoiseStart() ));

        // Resets the player and stops all notes
        SongPlayer.getMidiChannels()[0].allNotesOff();
        SongPlayer.getMidiChannels()[1].allNotesOff();
        SongPlayer.getMidiChannels()[2].allNotesOff();
        SongPlayer.setTime(0);
        SongPlayer.setPaused(true);

        camera.setX( -PianoRollHandler.playLinePos );
        camera.setY(-980);
    }
}
