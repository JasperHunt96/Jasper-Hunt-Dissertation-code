unit Wav_File_Procedure_var_type;

interface

uses
  Classes, SysUtils,MMsystem, Dialogs;     //MMsystem is for Windows playback of Audio

type     // DEFINE type TWavHeader Help from Chat GPT
  TWavHeader = packed record
    ChunkID: array[0..3] of AnsiChar;   // "RIFF"
    ChunkSize: LongWord;                // File size - 8
    Format: array[0..3] of AnsiChar;    // "WAVE"
    SubChunk1ID: array[0..3] of AnsiChar;  // "fmt "
    SubChunk1Size: LongWord;            // 16 for PCM
    AudioFormat: Word;                  // 1 for PCM
    NumChannels: Word;                  // Number of channels (1 = mono, 2 = stereo)
    SampleRate: LongWord;               // Sampling rate
    ByteRate: LongWord;                 // (SampleRate * NumChannels * BitsPerSample) / 8
    BlockAlign: Word;                   // (NumChannels * BitsPerSample) / 8
    BitsPerSample: Word;                // Bits per sample (8, 16, 24, 32)
    SubChunk2ID: array[0..3] of AnsiChar;  // "data"
    SubChunk2Size: LongWord;            // Number of bytes of audio data
  end;

var   // Define variables Globally
  Header: TWavHeader;        // Define header variable to be called later
  AudioData: array of smallInt;  // Define a Dynamic Array variable to hold audio data OG
  AudioDataPadded : array of smallInt;  //array of original wav data with zero padding at the end
  AudioDataFinal: array of smallInt;
  FileStream: TFileStream;   // Define file stream
  AudioData2: array of smallInt ; // Define a Dynamic Array variable to hold audio data copy
  AudioData3: array of smallInt ;
  AudioData4: array of smallInt ;
  AudioData5: array of smallInt ;
  DelArray1: array of smallInt ;
  DelArray2: array of smallInt ;
  DelArray3: array of smallInt ;
  DelArray4: array of smallInt ;
  DelArray5: array of smallInt ;
  DelArray6: array of smallInt ;
  DelArray7: array of smallInt ;
  DelArray8: array of smallInt ;
  DelArray9: array of smallInt ;
  DelArray10: array of smallInt ;
  WavFilePath: string;
  Magnitude_array: array of Double;




  i : Integer;   //integer used for looping variable for copying Audiodata to Audiodata2
  j : Integer ;
  Memorystream:TMemorystream ;  //Define memory stream
  SampleValue: Integer;  //variable used for audiodata2 volume reduction
  SampleValue1: Integer;
  DelaySample: Integer;
  SampleRate: integer;
  Delay_Output : array of byte ;
  Delay_IR : array of byte;
  b : real;
  g : real ;
  k : integer;
  a : real ;
  delayed : integer;
  Bitspersample : Word ;
  wetDryMix : real ;
  random_delay_offset : integer ;
  all_pass_delay: array[0..4] of integer;
  room : integer ;
  pre_delay: real;



procedure Read_Wav_File1(const FileName: string);     //Define all procedures Globally
procedure Play_File1();
procedure Play_File2();
procedure delaying1(var AudioData2: array of smallInt;var AudioDataPadded: array of smallInt;var g:real;var delayed:integer);
procedure sumdelays();
procedure Phaseshift(var AudioData3: array of smallInt;var AudioData2: array of smallInt);
procedure Wetdry(var AudioDataFinal: array of smallInt ; var AudioData3: array of smallInt;var AudioData: array of smallInt; wetDryMix : real );
procedure Predelay();
procedure ClearArrays();





implementation

//{$R *.dfm}

//Help from Chat GPT

procedure Read_Wav_File1(const FileName: string);  // procedure to read wav file into Audio Data


begin
   //clear Audiodata from any previous calls.
    SetLength(AudioData, 0);  // Clear previous audio data
    SetLength(AudioDataPadded, 0);



 // Open WAV file for reading
  FileStream := TFileStream.Create(WavFilePath, fmOpenRead);
  try
    // Read WAV header
    FileStream.Read(Header, SizeOf(TWavHeader));
     //reads sample rate into sample rate var
     SampleRate := Header.SampleRate;

      // Read the audio data into an array
    SetLength(AudioData, Header.SubChunk2Size);
    FileStream.Read(AudioData[0], Header.SubChunk2Size);


    // zero padding: create a new array with double the length
    SetLength(AudioDataPadded,Length(AudioData)*2);


    // zero padding: populate zero padded array with zeros
    for i := 0 to High(AudiodataPadded) do
    AudioDataPadded[i] := 0;


    // Copy original audio into first half of the new array
    for i := 0 to High(AudioData) do
    AudioDataPadded[i] := AudioData[i];


     // ? Update WAV header for new size
    Header.SubChunk2Size := Header.SubChunk2Size*2 ;
    Header.ChunkSize := Header.SubChunk2Size + Header.Chunksize  ;


    // copy Audiodata to Audiodata 2
    SetLength(AudioData2, Length(AudioDataPadded));
    SetLength(Audiodata3,Length(AudioDataPadded));
    SetLength(AudiodataFinal, Length(AudioDataPadded));



     //make sure all Audiodata is cleared incase a previous wav file has been played
     for i:= 0 to High(AudiodataPadded) do
     begin
       Audiodata2[i]:= 0;
       Audiodata3[i]:= 0;

     end;



    //move audiodatapadded into Audiodata2
    for i  := 0 to High(Audiodata) do
      begin
        Audiodata2[i] := AudiodataPadded[i];
      end;

  finally
    FileStream.Free;
  end;











 end;


 //Help from Chat GPT
procedure Play_File1();
begin
  // Stop any currently playing sound
  PlaySound(nil, 0, SND_PURGE);

  // Create a memory stream to hold both the WAV header and audio data
  MemoryStream := TMemoryStream.Create;
  try
    // Clear the memory stream to ensure no leftover data
    MemoryStream.Clear;

    // Write the header into the memory stream
    MemoryStream.Write(Header, SizeOf(Header));

    // Write the audio data into the memory stream
    MemoryStream.Write(AudioDataPadded[0], Length(AudioDataPadded) );

    // Play the sound from memory (using SND_MEMORY to indicate that sound is in memory)
    PlaySound(MemoryStream.Memory, 0, SND_ASYNC or SND_MEMORY);
  finally
    // Free memory stream after use
    MemoryStream.Free;
  end;
end;


//Help from Chat GPT
 procedure Play_File2();


  begin

  // Create a memory stream to hold both the WAV header and audio data
  MemoryStream := TMemoryStream.Create;
  try
    // Write the header into the memory stream
    MemoryStream.Write(Header, SizeOf(Header));

    // Write the audio data into the memory stream
    MemoryStream.Write(AudioDataFinal[0], Length(AudioDataFinal));

    // Play the sound from memory (using SND_MEMORY to indicate that sound is in memory)
    PlaySound(MemoryStream.Memory, 0, SND_ASYNC or SND_MEMORY);
  finally
    MemoryStream.Free;
  end;


 end;





procedure delaying1(var AudioData2: array of smallInt;var AudioDataPadded: array of smallInt;var g:real;var delayed:integer);

begin
b:=0.96 - g ;  // potentially change this line to a different relationship
for i:= delayed to length(AudiodataPadded)-1 do
        begin
         Audiodata2[i] := AudiodataPadded[i] - round(g*AudiodataPadded[i-1]) + round(g*Audiodata2[i-1]) + round(b*Audiodata2[i-delayed]);
        end;






 end;




procedure sumdelays();
begin

SetLength(Delarray1,Length(AudioDataPadded));
SetLength(Delarray2,Length(AudioDataPadded));
SetLength(Delarray3,Length(AudioDataPadded));
SetLength(Delarray4,Length(AudioDataPadded));
SetLength(Delarray5,Length(AudioDataPadded));
SetLength(Delarray6,Length(AudioDataPadded));
SetLength(Delarray7,Length(AudioDataPadded));
SetLength(Delarray8,Length(AudioDataPadded));
SetLength(Delarray9,Length(AudioDataPadded));
SetLength(Delarray10,Length(AudioDataPadded));






Setlength(Audiodata4,length(AudiodataPadded));
Setlength(Audiodata5,length(AudiodataPadded));

// room:= 200 ;


//g:= 0.7;      //adjust
delayed:= round((room * 0.53)/1000*  SampleRate) ;
delaying1(Delarray1, AudioDataPadded ,g,delayed);  // Delay 1



//g:=0.87;
delayed:= round((room * 0.58)/1000*  SampleRate) ;
delaying1(Delarray2, AudioDataPadded, g,delayed);  // Delay 2


//g:=0.83;
delayed:= round((room * 0.63)/1000*  SampleRate) ;
delaying1(Delarray3, AudioDataPadded, g,delayed);  // Delay 3

//g:=0.832;
delayed:= round((room * 0.65)/1000*  SampleRate) ;
delaying1(Delarray4, AudioDataPadded, g,delayed);  // Delay 4

//g:=0.821;
delayed:= round((room * 0.67)/1000*  SampleRate) ;
delaying1(Delarray5, AudioDataPadded, g,delayed);  // Delay 5


//g:= 0.813;
delayed:=  round((room * 0.69)/1000*  SampleRate) ;
delaying1(Delarray6, AudioDataPadded, g,delayed);  // Delay 6

//g:= 0.807;
delayed:= round((room * 0.77)/1000*  SampleRate) ;
delaying1(Delarray7, AudioDataPadded, g,delayed);  // Delay 7

//g:= 0.8;
delayed:=round((room * 0.81)/1000*  SampleRate) ;
delaying1(Delarray8, AudioDataPadded, g,delayed);  // Delay 8

//g:= 0.88;
delayed:=round((room * 0.85)/1000*  SampleRate) ;
delaying1(Delarray9, AudioDataPadded, g,delayed);  // Delay 9

//g:= 0.9;
delayed:=round(room /1000*  SampleRate) ;
delaying1(Delarray10, AudioDataPadded, g,delayed);  // Delay 10



for i:= 0 to length(Audiodata2)-1 do
begin
Audiodata2[i] := (round(Delarray1[i]) + round(Delarray2[i])+ round(Delarray3[i]) )div 3;
end;

for i:= 0 to length(Audiodata2)-1 do
begin
Audiodata5[i] := (round(Delarray4[i]) + round(Delarray5[i])+ round(Delarray6[i])+ round(Delarray7[i])+ round(Delarray8[i])+ round(Delarray9[i])+ round(Delarray10[i]) )div 7;
end;





end;


procedure Phaseshift(var AudioData3: array of smallInt;var AudioData2: array of smallInt);






begin
a:= 0.7 ;     //gain suggested in dsp 2024
all_pass_delay[0] := round ((23/1000) * Samplerate);
all_pass_delay[1] := round ((37/1000) * Samplerate);
all_pass_delay[2] := round ((47/1000) * Samplerate);
all_pass_delay[3] := round ((97/1000) * Samplerate);
all_pass_delay[4] := round ((134/1000) * Samplerate);
for i  := 0 to High(Audiodata3) do
      begin
        Audiodata4[i] := 0 ;
      end;


for j := 0 to 3 do
begin
delayed := all_pass_delay[j];

        for i:= delayed to length(Audiodata)-1 do
        begin
        Audiodata4[i] :=round(a* Audiodata5[i]) + Audiodata5[i-delayed] - round(a*Audiodata4[i-delayed]);
        end;
        for i := 0 to length(Audiodata)-1 do
        begin
        Audiodata5[i] := Audiodata4[i] ;
        end;
end;



//sum ealry and late reflections
for i:= 0 to length(Audiodata2)-1 do
begin
Audiodata3[i] := (round(0.25*Audiodata4[i]) + (round(1*Audiodata2[i])))div 2;
end;











 end;


procedure Predelay();

begin
Delaysample:= round(pre_delay/1000* SampleRate) ;
begin
for i := 0 to High(AudioData3) do

  if i < Delaysample then
      Audiodata3[i] := 0
  else
     Audiodata3[i] :=  Audiodata3[i] ;
end;



end;


procedure Wetdry(var AudioDataFinal: array of smallInt ; var AudioData3: array of smallInt;var AudioData: array of smallInt; wetDryMix : real );






begin
  for i := 0 to High(AudioDataFinal) do
  begin
   AudioDataFinal[i] := Round(AudioData3[i] * wetDryMix + AudioDataPadded[i] * (1 - wetDryMix));


  end;


end;






Procedure ClearArrays ();

begin
  for i := 0 to High(AudiodataFinal) do
    Audiodatafinal[i]:= 0;
    Audiodata[i]:= 0;
    Audiodata2[i]:= 0 ;
    Audiodata3[i]:= 0 ;
    AudioData4[i]:= 0 ;
    AudioData5[i]:= 0 ;
    DelArray1[i]:= 0;
    DelArray2[i]:= 0;
    DelArray3[i]:= 0;
    DelArray4[i]:= 0;
    DelArray5[i]:= 0;
    DelArray6[i]:= 0;
    DelArray7[i]:= 0;
    DelArray8[i]:= 0;
    DelArray9[i]:= 0;
    DelArray10[i]:= 0;
    AudioDataPadded[i]:= 0;


end;

end.






