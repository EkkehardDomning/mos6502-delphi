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

  TVC20MemKind = (mkUnimplemented,mkRAM,mkRegister,mkROM);
  TV20MemRange = record
    MemKind : TVC20MemKind;
    MemStartAddr : Word;
    MemStopAddr : Word;
    MemDescr : String;
  end;
  TV20MemRangeArr = array of TV20MemRange;

  { TVC20 }

  TVC20 = class(TMOS6502)
  private
    Thread: TVC20Thread;
    TimerHandle: Integer;
    LastKey: Char;
    FMemoryMap : TV20MemRangeArr;
    procedure BusWrite(Adr: Word; Value: Byte);
    function BusRead(Adr: Word): Byte;
    function GetMemoryMapKind(Index : Integer): TVC20MemKind;
    function KeyRead: Byte;
    function GetMemKind(AMemAddr : Word) : TVC20MemKind;
    procedure SetMemoryMapKind(Index : Integer; AValue: TVC20MemKind);
  protected
    KeyMatrix: Array[0 .. 7, 0 .. 7] of Byte;
    Memory: PByte;
    InterruptRequest: Boolean;
    procedure SetupMemoryMap;virtual;
    function GetMemoryMapItemCount : Integer;
    function GetMemoryMapItems(Index : Integer) : TV20MemRange;
    function GetMemoryMapKinds(Index : Integer) : TVC20MemKind;
    procedure SetMemoryMapKinds(Index : Integer; Value : TVC20MemKind);
  public
    WndHandle: THandle;
    property MemKind[AMemAddr : Word] : TVC20MemKind read GetMemKind;
    property MemoryMapItemCount : Integer read GetMemoryMapItemCount;
    property MemoryMapItems[Index : Integer] : TV20MemRange read GetMemoryMapItems;
    property MemoryMapKinds[Index : Integer] : TVC20MemKind read GetMemoryMapKind write SetMemoryMapKind;
    constructor Create;
    destructor Destroy; override;
    procedure LoadROM(Filename: String; Addr: Word);
    procedure Add3KRAMExt;
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
var
  memk : TVC20MemKind;
begin
  Result := Memory[Adr];
  memk := MemKind[Adr];
  if memk = mkUnimplemented then
    Result := $FF;
end;

function TVC20.GetMemoryMapKind(Index : Integer): TVC20MemKind;
begin

end;

procedure TVC20.BusWrite(Adr: Word; Value: Byte);
var
  memk : TVC20MemKind;
begin
  memk := MemKind[Adr];

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

  if (memk = mkROM) or
     (memk = mkUnimplemented) then
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

  SetupMemoryMap;

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

function TVC20.GetMemKind(AMemAddr: Word): TVC20MemKind;
var
  i : Integer;
begin
  Result := mkUnimplemented;
  for i := 0 to High(FMemoryMap) do
  begin
    if (AMemAddr >= FMemoryMap[i].MemStartAddr) and (AMemAddr <= FMemoryMap[i].MemStopAddr) then
    begin
      Result := FMemoryMap[i].MemKind;
      Exit;
    end;
  end;
end;

procedure TVC20.SetMemoryMapKind(Index : Integer; AValue: TVC20MemKind);
begin

end;

procedure TVC20.SetupMemoryMap;
begin
  SetLength(FMemoryMap,15);
  // 0000-03FF 0-1023 Zero Page, 1K Ram
  FMemoryMap[0].MemDescr:= 'ZERO - System Variables';
  FMemoryMap[0].MemKind:= mkRAM;
  FMemoryMap[0].MemStartAddr:= $0000;
  FMemoryMap[0].MemStopAddr:=  $03FF;
  // 0400-0FFF 1024-4095 Optional 3K Extension, 3K
  FMemoryMap[1].MemDescr:= 'EXT2K - Expansion';
  FMemoryMap[1].MemKind:= mkUnimplemented;
  FMemoryMap[1].MemStartAddr:= $0400;
  FMemoryMap[1].MemStopAddr:=  $0FFF;
  // 1000-1DFF 4096-7679 Default User Basic memory, 3584 Bytes
  FMemoryMap[2].MemDescr:= 'BASICUSR - Default Basic Mem';
  FMemoryMap[2].MemKind:= mkRAM;
  FMemoryMap[2].MemStartAddr:= $1000;
  FMemoryMap[2].MemStopAddr:=  $1DFF;
  // 1E00-1FFF 7680-8191 Default Screen Memory, 512 Bytes (used 22*23 = 506)
  FMemoryMap[3].MemDescr:= 'SCREEN - Screen Mem';
  FMemoryMap[3].MemKind:= mkRAM;
  FMemoryMap[3].MemStartAddr:= $1E00;
  FMemoryMap[3].MemStopAddr:=  $1FFF;
  // 2000-3FFF 	8192-16383 BLK 1 – 8K expansion RAM/ROM block 1
  FMemoryMap[4].MemDescr:= 'BLK1 - 8K Optional RAM/ROM';
  FMemoryMap[4].MemKind:= mkUnimplemented;
  FMemoryMap[4].MemStartAddr:= $2000;
  FMemoryMap[4].MemStopAddr:=  $3FFF;
  // 4000-5FFF 	16384-24575 BLK 2 – 8K expansion RAM/ROM block 2
  FMemoryMap[5].MemDescr:= 'BLK2 - 8K Optional RAM/ROM';
  FMemoryMap[5].MemKind:= mkUnimplemented;
  FMemoryMap[5].MemStartAddr:= $4000;
  FMemoryMap[5].MemStopAddr:=  $5FFF;
  // 6000-7FFF 	24576-32767 BLK 3 – 8K expansion RAM/ROM block 3
  FMemoryMap[6].MemDescr:= 'BLK3 - 8K Optional RAM/ROM';
  FMemoryMap[6].MemKind:= mkUnimplemented;
  FMemoryMap[6].MemStartAddr:= $6000;
  FMemoryMap[6].MemStopAddr:=  $7FFF;
  // 8000-8FFF 	32768-36863 4K Character generator ROM
  FMemoryMap[7].MemDescr:= 'CHARACTER - 4K ROM';
  FMemoryMap[7].MemKind:= mkUnimplemented;
  FMemoryMap[7].MemStartAddr:= $8000;
  FMemoryMap[7].MemStopAddr:=  $8FFF;
  // 9000-93FF 	36864-37887 	I/O BLOCK 0 (VIC, VIA)
  FMemoryMap[8].MemDescr:= 'IOBLK0 - VIC, VIA';
  FMemoryMap[8].MemKind:= mkRegister;
  FMemoryMap[8].MemStartAddr:= $8000;
  FMemoryMap[8].MemStopAddr:=  $8FFF;
  // 9400-97FF 	37888-38911 	I/O BLOCK 1 (COLOR Nibbles)
  FMemoryMap[9].MemDescr:= 'IOBLK1 - Color Nibbles';
  FMemoryMap[9].MemKind:= mkRAM;
  FMemoryMap[9].MemStartAddr:= $8000;
  FMemoryMap[9].MemStopAddr:=  $8FFF;
  // 9800-9BFF 	38912-39935 	I/O BLOCK 2
  FMemoryMap[10].MemDescr:= 'IOBLK2';
  FMemoryMap[10].MemKind:= mkUnimplemented;
  FMemoryMap[10].MemStartAddr:= $8000;
  FMemoryMap[10].MemStopAddr:=  $8FFF;
  // 9C00-9FFF 	39936-40959 	I/O BLOCK 3
  FMemoryMap[11].MemDescr:= 'IOBLK3';
  FMemoryMap[11].MemKind:= mkUnimplemented;
  FMemoryMap[11].MemStartAddr:= $8000;
  FMemoryMap[11].MemStopAddr:=  $8FFF;
  // A000-BFFF 	40960-49152 	BLK 4 – ROM expansion (cartridges)
  FMemoryMap[12].MemDescr:= 'BLK4 - 8K Optional ROM';
  FMemoryMap[12].MemKind:= mkUnimplemented;
  FMemoryMap[12].MemStartAddr:= $8000;
  FMemoryMap[12].MemStopAddr:=  $8FFF;
  // C000-DFFF 149152-57343 	BASIC – 8K ROM
  FMemoryMap[13].MemDescr:= 'BASICSYS – 8K ROM';
  FMemoryMap[13].MemKind:= mkUnimplemented; // Will be set to mkROM in the LoadROM method
  FMemoryMap[13].MemStartAddr:= $C000;
  FMemoryMap[13].MemStopAddr:=  $DFFF;
  // E000-FFFF 157344-65535 	KERNAL – 8K ROM
  FMemoryMap[14].MemDescr:= 'KERNAL – 8K ROM'; // Will be set to mkROM in the LoadROM method
  FMemoryMap[14].MemKind:= mkUnimplemented;
  FMemoryMap[14].MemStartAddr:= $E000;
  FMemoryMap[14].MemStopAddr:=  $FFFF;
end;

function TVC20.GetMemoryMapItemCount: Integer;
begin
  Result := Length(FMemoryMap);
end;

function TVC20.GetMemoryMapItems(Index: Integer): TV20MemRange;
begin
  Result := FMemoryMap[Index];
end;

function TVC20.GetMemoryMapKinds(Index: Integer): TVC20MemKind;
begin
  Result := FMemoryMap[Index].MemKind;
end;

procedure TVC20.SetMemoryMapKinds(Index: Integer; Value: TVC20MemKind);
begin
  FMemoryMap[Index].MemKind := Value;
end;

procedure TVC20.LoadROM(Filename: String; Addr: Word);
var
  Stream: TFileStream;
  i : Integer;
  addrstop : Word;
begin
  Stream := TFileStream.Create(Filename, fmOpenRead);
  try
    Stream.Read(Memory[Addr], Stream.Size);
    addrstop := Addr+Stream.Size-1;
    for i := 0 to High(FMemoryMap) do
    begin
      if (FMemoryMap[i].MemStartAddr = Addr) and
         (FMemoryMap[i].MemStopAddr = addrstop) then
      begin
        FMemoryMap[i].MemKind:= mkROM;
        Break;
      end;
    end;
  finally
    Stream.Free;
  end;
end;

procedure TVC20.Add3KRAMExt;
var
  i : Integer;
begin
  for i := 0 to High(FMemoryMap) do
  begin
    if (FMemoryMap[i].MemStartAddr = $0400)  then
    begin
      FMemoryMap[i].MemKind:= mkRAM;
      Break;
    end;
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
