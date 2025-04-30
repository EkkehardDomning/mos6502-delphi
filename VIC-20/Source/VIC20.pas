unit VIC20;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
{$IFnDEF FPC}
  WinApi.Messages, System.Classes,
{$ELSE}
  Windows, Classes,
{$ENDIF}
  MOS6502;

const
  WM_SCREEN_WRITE = WM_USER + 0;

  CIA1 = $9120;   // $DC00;

  // VIC-20 keyboard matrix
{
  Found at: https://www.lemon64.com/forum/viewtopic.php?t=68210

  VIC20 Keyboard Matrix

  Write to Port B($9120)column
  Read from Port A($9121)row

       7   6   5   4   3   2   1   0
      --------------------------------
    7| F7  F5  F3  F1  CDN CRT RET DEL    CRT=Cursor-Right, CDN=Cursor-Down
     |
    6| HOM UA  =   RSH /   ;   *   BP     BP=British Pound, RSH=Should be Right-SHIFT,
     |                                    UA=Up Arrow
    5| -   @   :   .   ,   L   P   +
     |
    4| 0   O   K   M   N   J   I   9
     |
    3| 8   U   H   B   V   G   Y   7
     |
    2| 6   T   F   C   X   D   R   5
     |
    1| 4   E   S   Z   LSH A   W   3      LSH=Should be Left-SHIFT
     |
    0| 2   Q   CBM SPC STP CTL LA  1      LA=Left Arrow, CTL=Should be CTRL, STP=RUN/STOP
     |                                    CBM=Commodore key

  C64/VIC20 Keyboard Layout

    LA  1  2  3  4  5  6  7  8  9  0  +  -  BP HOM DEL    F1
    CTRL Q  W  E  R  T  Y  U  I  O  P  @  *  UA RESTORE   F3
  STOP SL A  S  D  F  G  H  J  K  L  :  ;  =  RETURN      F5
  C= SHIFT Z  X  C  V  B  N  M  ,  .  /  SHIFT  CDN CRT   F7
           [        SPACE BAR       ]

  Keyboard Connector
  Pin  Desc.
  1    Ground
  2    [key]
  3    RESTORE key
  4    +5 volts
  5    Column 7, Joy 3
  6    Column 6
  7    Column 5
  8    Column 4
  9    Column 3, Tape Write(E5)
  10   Column 2
  11   Column 1
  12   Column 0
  13   Row 7
  14   Row 6
  15   Row 5
  16   Row 4
  17   Row 3
  18   Row 2
  19   Row 1
  20   Row 0
}
  KEY_TRANSLATION = '2'+'q'+#00+' '+#27+#00+#00+'1'+  // $00..$07  0
                    '4'+'e'+'s'+'z'+#00+'a'+'w'+'3'+  // $08..$0f
                    '6'+'t'+'f'+'c'+'x'+'d'+'r'+'5'+  // $10..$17
                    '8'+'u'+'h'+'b'+'v'+'g'+'y'+'7'+  // $18..$1f
                    '0'+'o'+'k'+'m'+'n'+'j'+'i'+'9'+  // $20..$27
                    '-'+'@'+':'+'.'+','+'l'+'p'+'+'+  // $28..$2f

                    #00+#00+'='+#00+'/'+';'+'*'+#00+  // $30..$37 // '£' is not working
                    #00+#00+#00+#00+#00+#00+#13+#08+  // $38..$3f  63

                    '"'+#00+#00+#00+#00+#00+#00+'!'+  // $40..$47  64
                    '$'+#00+#00+#00+#00+#00+#00+'#'+  // $48..$4f
                    '&'+#00+#00+#00+#00+#00+#00+'%'+  // $50..$57
                    '('+#00+#00+#00+#00+#00+#00+''''+ // $58..$5f
                    '0'+#00+#00+#00+#00+#00+#00+')'+  // $60..$67
                    '_'+#00+'['+'>'+'<'+'l'+#00+#00+  // $68..$6f
                    #00+#00+'='+#00+'?'+']'+#00+#00+  // $70..$77
                    #00+#00+#00+#00+#00+#00+#13+#08;  // $78..$7f  127

type
  TVC20 = class;

  TVC20Thread = class(TThread)
  private
    VC20: TVC20;
  protected
  public
    procedure Execute; override;
    constructor Create(VC20Instance: TVC20);
  end;

  TVC20 = class(TMOS6502)
  private
    Thread: TVC20Thread;
    TimerHandle: Integer;
    LastKey: Char;
    procedure BusWrite(Adr: Word; Value: Byte);
    function BusRead(Adr: Word): Byte;
    function KeyRead: Byte;
  protected
    KeyMatrix: Array[0 .. 7, 0 .. 7] of Byte;
    Memory: PByte;
    InterruptRequest: Boolean;
  public
    WndHandle: THandle;
    constructor Create;
    destructor Destroy; override;
    procedure LoadROM(Filename: String; Addr: Word);
    procedure Exec;
    procedure SetKey(Key: Char; Value: Byte);
  end;

implementation

uses
{$IFnDEF FPC}
  Winapi.Windows, System.SysUtils, WinApi.MMSystem;
{$ELSE}
  SysUtils, MMSystem;
{$ENDIF}


{ TVC20 }

procedure TimerProcedure(TimerID, Msg: Uint; dwUser, dw1, dw2: DWORD); pascal;
var
  VC20: TVC20;
begin
  VC20 := TVC20(dwUser);

  if VC20.Status and VC20.INTERRUPT = 0 then // if IRQ allowed then set irq
    VC20.InterruptRequest := True;
end;


function TVC20.BusRead(Adr: Word): Byte;
begin
  Result := Memory[Adr];
end;

procedure TVC20.BusWrite(Adr: Word; Value: Byte);
begin
  // test for I/O requests
  case Adr of
    CIA1:
      begin
        // Handle keyboard reading
        Memory[Adr] := Value;
        Memory[CIA1 + 1] := KeyRead;
      end;

    CIA1 + 5: // Timer
     if TimerHandle = 0 then
       TimerHandle := TimeSetEvent(34, 2, @TimerProcedure, DWORD(Self), TIME_PERIODIC);
  end;

  if (Adr >= $2000) then // $A000  // treat anything above as ROM
    Exit;

  Memory[Adr] := Value;

  // video RAM
  if (Adr >= $1E00) and (Adr <= $1FF9) then   // $400 - $07E7
    PostMessage(WndHandle, WM_SCREEN_WRITE, Adr - $1E00, Value);  // $400
end;

constructor TVC20.Create;
begin
  inherited Create(BusRead, BusWrite);

  // create 64kB memory table
  GetMem(Memory, 65536);

  Thread := TVC20Thread.Create(Self);
end;

destructor TVC20.Destroy;
begin
  if TimerHandle <> 0 then
    Timekillevent(TimerHandle);
  Thread.Terminate;
  Thread.WaitFor;
  Thread.Free;
  FreeMem(Memory);
  inherited;
end;

procedure TVC20.Exec;
begin
  Reset;
  Thread.Start;
end;

function TVC20.KeyRead: Byte;
var
  Row, Col, Cols: Byte;
begin
  Result := 0;
  Cols := Memory[CIA1];
  for Col := 0 to 7 do
  begin
    if Cols and (1 shl Col) = 0 then  // a 0 indicates a column read
    begin
      for Row := 0 to 7 do
      begin
        if KeyMatrix[7 - Col, Row] = 1 then
          Result := Result + (1 shl Row);
      end;
    end;
  end;
  Result := not Result;
end;

procedure TVC20.LoadROM(Filename: String; Addr: Word);
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(Filename, fmOpenRead);
  try
    Stream.Read(Memory[Addr], Stream.Size);
  finally
    Stream.Free;
  end;
end;

procedure TVC20.SetKey(Key: Char; Value: Byte);
var
  KeyPos: Integer;
begin
  KeyPos := Pos(Key, KEY_TRANSLATION) - 1;
  if KeyPos >= 0 then
  begin
    // always release last key on keypress
    if Value = 1 then
    begin
      SetKey(LastKey, 0);
      LastKey := Key;
    end;

    if KeyPos > 63 then  // set right shift on/off
    begin
      KeyMatrix[3, 6] := Value;   // 1, 4
      Dec(KeyPos, 64);
    end;

    KeyMatrix[KeyPos mod 8, KeyPos div 8] := Value;
  end;
end;

{ TVC20Thread }

constructor TVC20Thread.Create(VC20Instance: TVC20);
begin
  inherited Create(True);
  VC20 := VC20Instance;
end;

procedure TVC20Thread.Execute;
begin
  while (not Terminated) do
  begin
    if VC20.InterruptRequest then
    begin
      VC20.InterruptRequest := False;
      VC20.IRQ;
    end;
    VC20.Step;
    Sleep(0);
  end;
end;

end.
