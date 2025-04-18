unit WAV_File_Implementation;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,WAV_File_Procedure_var_type,delay,
  Vcl.Menus, Vcl.ExtCtrls, VclTee.TeeGDIPlus, VCLTee.TeEngine, VCLTee.TeeProcs,
  VCLTee.Chart, VCLTee.Series, VCLTee.TeeSpline, Vcl.Imaging.pngimage,
  Vcl.Imaging.jpeg;

type
  TForm_1 = class(TForm)
    Unprocessed_sound: TButton;
    Processed_Sound: TButton;
    ScrollBar1: TScrollBar;
    wetDrylabel: TLabel;
    Output_Waveform: TChart;
    Calculate: TButton;
    Series1: TLineSeries;
    ScrollBar2: TScrollBar;
    Predelaylabel: TLabel;
    Input_waveform: TChart;
    LineSeries1: TLineSeries;
    Calculate2: TButton;
    RoomType: TComboBox;
    RoomType_label: TLabel;
    ChooseWav: TComboBox;
    Image9: TImage;
    Image3: TImage;
    Image4: TImage;
    Image5: TImage;
    Image6: TImage;
    Image7: TImage;
    Image8: TImage;
    Image1: TImage;
    Image11: TImage;
    Image12: TImage;
    Image15: TImage;
    Image10: TImage;
    Image17: TImage;
    Image18: TImage;
    Image19: TImage;
    Image20: TImage;
    Image21: TImage;
    Image22: TImage;
    Image23: TImage;
    Image24: TImage;
    Image25: TImage;
    Image26: TImage;
    Image27: TImage;
    Image29: TImage;
    Image30: TImage;
    Image31: TImage;
    Image32: TImage;
    Image33: TImage;
    Image34: TImage;
    Image35: TImage;
    Image36: TImage;
    Image37: TImage;
    Image38: TImage;
    Image39: TImage;
    Image40: TImage;
    Image41: TImage;
    Image42: TImage;
    Image43: TImage;
    Image44: TImage;
    Image45: TImage;
    Image46: TImage;
    Image47: TImage;
    Image48: TImage;
    Image49: TImage;
    Image50: TImage;
    Image51: TImage;
    Image52: TImage;
    Image53: TImage;
    Image13: TImage;
    Image14: TImage;
    Image28: TImage;
    Image54: TImage;
    Image55: TImage;
    Image56: TImage;
    Image57: TImage;
    Image58: TImage;
    Image59: TImage;
    Image60: TImage;
    Image61: TImage;
    Image62: TImage;
    Image63: TImage;
    Image64: TImage;
    Image65: TImage;
    Image66: TImage;
    Image67: TImage;
    Image68: TImage;
    Image69: TImage;
    Image16: TImage;
    Label1: TLabel;
    Label2: TLabel;
    Image70: TImage;
    Image71: TImage;
    Image72: TImage;
    Image73: TImage;
    Image74: TImage;
    Image75: TImage;
    Image76: TImage;
    Image2: TImage;
    Image77: TImage;     // Edit box for status messages
    procedure Unprocessed_soundClick(Sender: TObject);
    procedure Processed_SoundClick(Sender: TObject);
    procedure ScrollBar1Change(Sender: TObject);  // procedure delcared for reading wav
    procedure ScrollBar2Change(Sender: Tobject);
    procedure ChooseWavChange(Sender: TObject);
    procedure RoomTypeChange(Sender: TObject);
    procedure CalculateClick(Sender: TObject);
    procedure Calculate2Click(Sender: TObject);



  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form_1: TForm_1;

implementation

{$R *.dfm}





procedure TForm_1.Processed_SoundClick(Sender: TObject);
begin
Read_Wav_File1(WavFilePath);
sumdelays();
Phaseshift(Audiodata3,Audiodata2);
Predelay();
Wetdry(AudioDataFinal, AudioData3, AudioDataPadded,wetDryMix);
Play_File2();

end;

procedure TForm_1.ScrollBar1Change(Sender: TObject);



begin
ScrollBar1.Min := 0;
ScrollBar1.Max := 100;
wetDryMix :=  1 - ScrollBar1.Position/100;
wetDrylabel.Caption := Format('Wet/Dry: %d%%', [100-ScrollBar1.Position]);
end;

procedure TForm_1.ScrollBar2Change(Sender: Tobject);
begin
ScrollBar2.Min := 0;
ScrollBar2.Max := 2000;
pre_delay := 2000-ScrollBar2.Position;
predelaylabel.Caption:= Format('Predelay= %d ms' , [2000-ScrollBar2.Position]);

end;



procedure TForm_1.Unprocessed_soundClick(Sender: TObject);

 //Button click to read wav file
  begin
  ShowMessage('Button clicked!');

   Read_Wav_File1(WavFilePath);
   Play_File1();




  end;

procedure TForm_1.ChooseWavChange(Sender: TObject);
begin
  // Get the selected item index (starting from 0)
  case ChooseWav.ItemIndex of
    0: WavFilePath := ('original voice.wav');
    1: WavFilePath := ('Trump.wav');
    2: WavFilePath := ('white noise burst.wav');

  else
    WavFilePath := ('original voice.wav');
  end;
end;

procedure TForm_1.RoomTypeChange(Sender: TObject);
begin
  // Get the selected item index (starting from 0)
  case RoomType.ItemIndex of
    0:
      begin
        g:= 0.7 ;
        room:= 200      //medium room
      end;
    1:
      begin
        g:= 0.6 ;
        room:= 270;      //large room
      end;
    2:
      begin
        g:= 0.8 ;
        room:= 100;     // small room
      end;


  else
      begin
        g:= 0.7 ;
        room:= 200;
      end;


  end;
end;




procedure TForm_1.CalculateClick(Sender: TObject);
var
i : Integer  ;
begin
  Output_Waveform.Series[0].Clear;
    begin
    for i := 0 to High(AudiodataFinal) do
    Output_Waveform.Series[0].AddXY(i/Samplerate,AudiodataFinal[i]);
    end;


Output_Waveform.Axes[0].SetMinMax(0, Length(Audiodata)*4/Samplerate);
Output_Waveform.Axes[1].SetMinMax(-1, 1);


end;

 procedure TForm_1.Calculate2Click(Sender: TObject);
 var
 i: Integer;
 begin
 Input_Waveform.Series[0].Clear;
    begin
    for i := 0 to High(Audiodata) do
    Input_Waveform.Series[0].AddXY(i/Samplerate,Audiodata[i]);
    end;

 Input_Waveform.Axes[0].SetMinMax(0, Length(Audiodata)*4/Samplerate);
 Input_Waveform.Axes[1].SetMinMax(-1, 1);

 end;

end.

