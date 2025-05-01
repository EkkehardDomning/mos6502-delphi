{ MOS6502 v1.0 - a MOS 6502 CPU emulator
  for Delphi 10.1 Berlin+ by Dennis Spreen
  http://blog.spreendigital.de/2017/03/09/mos6502-delphi/

  MIT License

  Copyright (c) 2017 Gianluca Ghettini (C++ implementation)
  Copyright (c) 2017 Dennis D. Spreen <dennis@spreendigital.de> (Delphi implementation)

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
}
unit MOS6502;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

type

  { TMOS6502 }

  TMOS6502 = class
    const
      // Status bits
      NEGATIVE_FLAG  = $80;
      OVERFLOW_FLAG  = $40;
      CONSTANT       = $20;
      BREAK_CMD      = $10;
      DECIMAL_FLAG   = $08;
      INTERRUPT_FLAG = $04;
      ZERO_FLAG      = $02;
      CARRY_FLAG     = $01;

      // IRQ, reset, NMI vectors
      IRQVECTORH: Word = $FFFF;
      IRQVECTORL: Word = $FFFE;
      RSTVECTORH: Word = $FFFD;
      RSTVECTORL: Word = $FFFC;
      NMIVECTORH: Word = $FFFB;
      NMIVECTORL: Word = $FFFA;

    type
      TCodeExec = procedure(Src: Word) of object;
      TAddrExec = function: Word of object;

      TInstr = record
        Addr: TAddrExec;
        Code: TCodeExec;
        Cycles : Byte;
      end;
      PInstr = ^TInstr;

      TBusWrite = procedure(Adr: Word; Value: Byte) of object;
      TBusRead = function(Adr: Word): Byte of object;
      TClockCycle = procedure(Sender : TObject) of object;

    procedure SET_NEGATIVE(const Value: Boolean); inline;
    procedure SET_OVERFLOW(const Value: Boolean); inline;
    procedure SET_CONSTANT(const Value: Boolean); inline;
    procedure SET_BREAK(const Value: Boolean); inline;
    procedure SET_DECIMAL(const Value: Boolean); inline;
    procedure SET_INTERRUPT(const Value: Boolean); inline;
    procedure SET_ZERO(const Value: Boolean); inline;
    procedure SET_CARRY(const Value: Boolean); inline;
    function IF_NEGATIVE: Boolean; inline;
    function IF_OVERFLOW: Boolean; inline;
    function IF_CONSTANT: Boolean; inline;
    function IF_BREAK: Boolean; inline;
    function IF_DECIMAL: Boolean; inline;
    function IF_INTERRUPT: Boolean; inline;
    function IF_ZERO: Boolean; inline;
    function IF_CARRY: Byte; inline;

  private
    procedure Exec(Instr : TInstr);

    // addressing modes
    function Addr_ACC: Word; // ACCUMULATOR
    function Addr_IMM: Word; // IMMEDIATE
    function Addr_ABS: Word; // ABSOLUTE
    function Addr_ZER: Word; // ZERO_FLAG PAGE
    function Addr_ZEX: Word; // INDEXED-X ZERO_FLAG PAGE
    function Addr_ZEY: Word; // INDEXED-Y ZERO_FLAG PAGE
    function Addr_ABX: Word; // INDEXED-X ABSOLUTE
    function Addr_ABY: Word; // INDEXED-Y ABSOLUTE
    function Addr_IMP: Word; // IMPLIED
    function Addr_REL: Word; // RELATIVE
    function Addr_INX: Word; // INDEXED-X INDIRECT
    function Addr_INY: Word; // INDEXED-Y INDIRECT
    function Addr_ABI: Word; // ABSOLUTE INDIRECT

    // opcodes (grouped as per datasheet)
    procedure Op_ADC(Src: Word);
    procedure Op_AND(Src: Word);
    procedure Op_ASL(Src: Word);
    procedure Op_ASL_ACC(Src: Word);
    procedure Op_BCC(Src: Word);
    procedure Op_BCS(Src: Word);

    procedure Op_BEQ(Src: Word);
    procedure Op_BIT(Src: Word);
    procedure Op_BMI(Src: Word);
    procedure Op_BNE(Src: Word);
    procedure Op_BPL(Src: Word);

    procedure Op_BRK(Src: Word);
    procedure Op_BVC(Src: Word);
    procedure Op_BVS(Src: Word);
    procedure Op_CLC(Src: Word);
    procedure Op_CLD(Src: Word);

    procedure Op_CLI(Src: Word);
    procedure Op_CLV(Src: Word);
    procedure Op_CMP(Src: Word);
    procedure Op_CPX(Src: Word);
    procedure Op_CPY(Src: Word);

    procedure Op_DEC(Src: Word);
    procedure Op_DEX(Src: Word);
    procedure Op_DEY(Src: Word);
    procedure Op_EOR(Src: Word);
    procedure Op_INC(Src: Word);

    procedure Op_INX(Src: Word);
    procedure Op_INY(Src: Word);
    procedure Op_JMP(Src: Word);
    procedure Op_JSR(Src: Word);
    procedure Op_LDA(Src: Word);

    procedure Op_LDX(Src: Word);
    procedure Op_LDY(Src: Word);
    procedure Op_LSR(Src: Word);
    procedure Op_LSR_ACC(Src: Word);
    procedure Op_NOP(Src: Word);
    procedure Op_ORA(Src: Word);

    procedure Op_PHA(Src: Word);
    procedure Op_PHP(Src: Word);
    procedure Op_PLA(Src: Word);
    procedure Op_PLP(Src: Word);
    procedure Op_ROL(Src: Word);
    procedure Op_ROL_ACC(Src: Word);

    procedure Op_ROR(Src: Word);
    procedure Op_ROR_ACC(Src: Word);
    procedure Op_RTI(Src: Word);
    procedure Op_RTS(Src: Word);
    procedure Op_SBC(Src: Word);
    procedure Op_SEC(Src: Word);
    procedure Op_SED(Src: Word);

    procedure Op_SEI(Src: Word);
    procedure Op_STA(Src: Word);
    procedure Op_STX(Src: Word);
    procedure Op_STY(Src: Word);
    procedure Op_TAX(Src: Word);

    procedure Op_TAY(Src: Word);
    procedure Op_TSX(Src: Word);
    procedure Op_TXA(Src: Word);
    procedure Op_TXS(Src: Word);
    procedure Op_TYA(Src: Word);

    procedure Op_ILLEGAL(Src: Word);

    // stack operations
    procedure StackPush(const Value: Byte); inline;
    function StackPop: Byte; inline;

  protected
    // consumed clock cycles
    FCycles: Cardinal;

    InstrTable: Array [0 .. 255] of TInstr;

    // read/write/ClockCycle callbacks
    FBusReadEvent: TBusRead;
    FBusWriteEvent: TBusWrite;
    FClockCycleEvent: TClockCycle;

    // register reset values
    FResetA : Byte;
    FResetX : Byte;
    FResetY : Byte;
    FResetSP : Byte;
    FResetStatus : Byte;

    // program counter
    FPC: Word;

    // registers
    FA: Byte; // accumulator
    FX: Byte; // X-index
    FY: Byte; // Y-index

    // stack pointer
    FSP: Byte;

    // status register
    FStatus: Byte;

    FIllegalOpcode: Boolean;
  public
    type
      TCycleMethod = (INST_COUNT,CYCLE_COUNT);

    constructor Create(R: TBusRead; W: TBusWrite; C: TClockCycle = Nil); overload; virtual;

    procedure NMI; virtual;
    procedure IRQ; virtual;
    procedure Reset; virtual;
    procedure Step; virtual;deprecated 'Please use Run or RunEternally';
    procedure Run(Cycles : Cardinal;
                  var CycleCount : UInt64;
                  CycleMethod : TCycleMethod = CYCLE_COUNT);
    procedure RunEternally; // until it encounters FA illegal opcode
    			// useful when running e.g. WOZ Monitor
    			// no need to worry about cycle exhaustion
    {
    property BusReadEvent: TBusRead read FBusReadEvent write FBusReadEvent;
    property BusWriteEvent: TBusWrite read FBusWriteEvent write FBusWriteEvent;
    property ClockCycleEvent: TClockCycle read FClockCycleEvent write FClockCycleEvent;
    }

    property PC : Word read FPC; // ProgramCounter
    property SP : Byte read FSP; // StacPointer
    property Status : Byte read FStatus; //ProcessorStatusRegister "P" in mos6502.h/.c
    property A : Byte read FA;
    property X : Byte read FX;
    property Y : Byte read FY;
    property ResetA : Byte read FResetA write FResetA;
    property ResetX : Byte read FResetX write FResetX;
    property ResetY : Byte read FResetY write FResetY;
    property ResetSP : Byte read FResetSP write FResetSP;
    property ResetStatus : Byte read FResetStatus write FResetStatus;
    property IllegalOpcode: Boolean read FIllegalOpcode write FIllegalOpcode;

  end;

implementation

{ TMOS6502 }

constructor TMOS6502.Create(R: TBusRead; W: TBusWrite; C: TClockCycle = Nil);
var
  Instr: TInstr;
  I: Integer;
begin
  inherited Create;
  FResetA := $00;
  FResetX := $00;
  FResetY := $00;
  FResetSP := $FD;
  FResetStatus := CONSTANT;

  FBusWriteEvent := W;
  FBusReadEvent := R;
  FClockCycleEvent := C;

  // fill jump table with ILLEGALs
  Instr.Addr := Addr_IMP;
  Instr.code := Op_ILLEGAL;
  for I := 0 to 256 - 1 do
    InstrTable[I] := Instr;

  // insert opcodes
  Instr.Addr := Addr_IMM;
  Instr.Code := Op_ADC;
  Instr.Cycles := 2;
  InstrTable[$69] := Instr;
  Instr.Addr := Addr_ABS;
  Instr.Code := Op_ADC;
  Instr.Cycles := 4;
  InstrTable[$6D] := Instr;
  Instr.Addr := Addr_ZER;
  Instr.Code := Op_ADC;
  Instr.Cycles := 3;
  InstrTable[$65] := Instr;
  Instr.Addr := Addr_INX;
  Instr.Code := Op_ADC;
  Instr.Cycles := 6;
  InstrTable[$61] := Instr;
  Instr.Addr := Addr_INY;
  Instr.Code := Op_ADC;
  Instr.Cycles := 6;
  InstrTable[$71] := Instr;
  Instr.Addr := Addr_ZEX;
  Instr.Code := Op_ADC;
  Instr.Cycles := 4;
  InstrTable[$75] := Instr;
  Instr.Addr := Addr_ABX;
  Instr.Code := Op_ADC;
  Instr.Cycles := 4;
  InstrTable[$7D] := Instr;
  Instr.Addr := Addr_ABY;
  Instr.Code := Op_ADC;
  Instr.Cycles := 4;
  InstrTable[$79] := Instr;

  Instr.Addr := Addr_IMM;
  Instr.Code := Op_AND;
  Instr.Cycles := 2;
  InstrTable[$29] := Instr;
  Instr.Addr := Addr_ABS;
  Instr.Code := Op_AND;
  Instr.Cycles := 4;
  InstrTable[$2D] := Instr;
  Instr.Addr := Addr_ZER;
  Instr.Code := Op_AND;
  Instr.Cycles := 3;
  InstrTable[$25] := Instr;
  Instr.Addr := Addr_INX;
  Instr.Code := Op_AND;
  Instr.Cycles := 6;
  InstrTable[$21] := Instr;
  Instr.Addr := Addr_INY;
  Instr.Code := Op_AND;
  Instr.Cycles := 5;
  InstrTable[$31] := Instr;
  Instr.Addr := Addr_ZEX;
  Instr.Code := Op_AND;
  Instr.Cycles := 4;
  InstrTable[$35] := Instr;
  Instr.Addr := Addr_ABX;
  Instr.Code := Op_AND;
  Instr.Cycles := 4;
  InstrTable[$3D] := Instr;
  Instr.Addr := Addr_ABY;
  Instr.Code := Op_AND;
  Instr.Cycles := 4;
  InstrTable[$39] := Instr;

  Instr.Addr := Addr_ABS;
  Instr.Code := Op_ASL;
  Instr.Cycles := 6;
  InstrTable[$0E] := Instr;
  Instr.Addr := Addr_ZER;
  Instr.Code := Op_ASL;
  Instr.Cycles := 5;
  InstrTable[$06] := Instr;
  Instr.Addr := Addr_ACC;
  Instr.Code := Op_ASL_ACC;
  Instr.Cycles := 2;
  InstrTable[$0A] := Instr;
  Instr.Addr := Addr_ZEX;
  Instr.Code := Op_ASL;
  Instr.Cycles := 6;
  InstrTable[$16] := Instr;
  Instr.Addr := Addr_ABX;
  Instr.Code := Op_ASL;
  Instr.Cycles := 7;
  InstrTable[$1E] := Instr;

  Instr.Addr := Addr_REL;
  Instr.Code := Op_BCC;
  Instr.Cycles := 2;
  InstrTable[$90] := Instr;

  Instr.Addr := Addr_REL;
  Instr.Code := Op_BCS;
  Instr.Cycles := 2;
  InstrTable[$B0] := Instr;

  Instr.Addr := Addr_REL;
  Instr.Code := Op_BEQ;
  Instr.Cycles := 2;
  InstrTable[$F0] := Instr;

  Instr.Addr := Addr_ABS;
  Instr.Code := Op_BIT;
  Instr.Cycles := 4;
  InstrTable[$2C] := Instr;
  Instr.Addr := Addr_ZER;
  Instr.Code := Op_BIT;
  Instr.Cycles := 3;
  InstrTable[$24] := Instr;

  Instr.Addr := Addr_REL;
  Instr.Code := Op_BMI;
  Instr.Cycles := 2;
  InstrTable[$30] := Instr;

  Instr.Addr := Addr_REL;
  Instr.Code := Op_BNE;
  Instr.Cycles := 2;
  InstrTable[$D0] := Instr;

  Instr.Addr := Addr_REL;
  Instr.Code := Op_BPL;
  Instr.Cycles := 2;
  InstrTable[$10] := Instr;

  Instr.Addr := Addr_IMP;
  Instr.Code := Op_BRK;
  Instr.Cycles := 7;
  InstrTable[$00] := Instr;

  Instr.Addr := Addr_REL;
  Instr.Code := Op_BVC;
  Instr.Cycles := 2;
  InstrTable[$50] := Instr;

  Instr.Addr := Addr_REL;
  Instr.Code := Op_BVS;
  Instr.Cycles := 2;
  InstrTable[$70] := Instr;

  Instr.Addr := Addr_IMP;
  Instr.Code := Op_CLC;
  Instr.Cycles := 2;
  InstrTable[$18] := Instr;

  Instr.Addr := Addr_IMP;
  Instr.Code := Op_CLD;
  Instr.Cycles := 2;
  InstrTable[$D8] := Instr;

  Instr.Addr := Addr_IMP;
  Instr.Code := Op_CLI;
  Instr.Cycles := 2;
  InstrTable[$58] := Instr;

  Instr.Addr := Addr_IMP;
  Instr.Code := Op_CLV;
  Instr.Cycles := 2;
  InstrTable[$B8] := Instr;

  Instr.Addr := Addr_IMM;
  Instr.Code := Op_CMP;
  Instr.Cycles := 2;
  InstrTable[$C9] := Instr;
  Instr.Addr := Addr_ABS;
  Instr.Code := Op_CMP;
  Instr.Cycles := 4;
  InstrTable[$CD] := Instr;
  Instr.Addr := Addr_ZER;
  Instr.Code := Op_CMP;
  Instr.Cycles := 3;
  InstrTable[$C5] := Instr;
  Instr.Addr := Addr_INX;
  Instr.Code := Op_CMP;
  Instr.Cycles := 6;
  InstrTable[$C1] := Instr;
  Instr.Addr := Addr_INY;
  Instr.Code := Op_CMP;
  Instr.Cycles := 3;
  InstrTable[$D1] := Instr;
  Instr.Addr := Addr_ZEX;
  Instr.Code := Op_CMP;
  Instr.Cycles := 4;
  InstrTable[$D5] := Instr;
  Instr.Addr := Addr_ABX;
  Instr.Code := Op_CMP;
  Instr.Cycles := 4;
  InstrTable[$DD] := Instr;
  Instr.Addr := Addr_ABY;
  Instr.Code := Op_CMP;
  Instr.Cycles := 4;
  InstrTable[$D9] := Instr;

  Instr.Addr := Addr_IMM;
  Instr.Code := Op_CPX;
  Instr.Cycles := 2;
  InstrTable[$E0] := Instr;
  Instr.Addr := Addr_ABS;
  Instr.Code := Op_CPX;
  Instr.Cycles := 4;
  InstrTable[$EC] := Instr;
  Instr.Addr := Addr_ZER;
  Instr.Code := Op_CPX;
  Instr.Cycles := 3;
  InstrTable[$E4] := Instr;

  Instr.Addr := Addr_IMM;
  Instr.Code := Op_CPY;
  Instr.Cycles := 2;
  InstrTable[$C0] := Instr;
  Instr.Addr := Addr_ABS;
  Instr.Code := Op_CPY;
  Instr.Cycles := 4;
  InstrTable[$CC] := Instr;
  Instr.Addr := Addr_ZER;
  Instr.Code := Op_CPY;
  Instr.Cycles := 3;
  InstrTable[$C4] := Instr;

  Instr.Addr := Addr_ABS;
  Instr.Code := Op_DEC;
  Instr.Cycles := 6;
  InstrTable[$CE] := Instr;
  Instr.Addr := Addr_ZER;
  Instr.Code := Op_DEC;
  Instr.Cycles := 5;
  InstrTable[$C6] := Instr;
  Instr.Addr := Addr_ZEX;
  Instr.Code := Op_DEC;
  Instr.Cycles := 6;
  InstrTable[$D6] := Instr;
  Instr.Addr := Addr_ABX;
  Instr.Code := Op_DEC;
  Instr.Cycles := 7;
  InstrTable[$DE] := Instr;

  Instr.Addr := Addr_IMP;
  Instr.Code := Op_DEX;
  Instr.Cycles := 2;
  InstrTable[$CA] := Instr;

  Instr.Addr := Addr_IMP;
  Instr.Code := Op_DEY;
  Instr.Cycles := 2;
  InstrTable[$88] := Instr;

  Instr.Addr := Addr_IMM;
  Instr.Code := Op_EOR;
  Instr.Cycles := 2;
  InstrTable[$49] := Instr;
  Instr.Addr := Addr_ABS;
  Instr.Code := Op_EOR;
  Instr.Cycles := 4;
  InstrTable[$4D] := Instr;
  Instr.Addr := Addr_ZER;
  Instr.Code := Op_EOR;
  Instr.Cycles := 3;
  InstrTable[$45] := Instr;
  Instr.Addr := Addr_INX;
  Instr.Code := Op_EOR;
  Instr.Cycles := 6;
  InstrTable[$41] := Instr;
  Instr.Addr := Addr_INY;
  Instr.Code := Op_EOR;
  Instr.Cycles := 5;
  InstrTable[$51] := Instr;
  Instr.Addr := Addr_ZEX;
  Instr.Code := Op_EOR;
  Instr.Cycles := 4;
  InstrTable[$55] := Instr;
  Instr.Addr := Addr_ABX;
  Instr.Code := Op_EOR;
  Instr.Cycles := 4;
  InstrTable[$5D] := Instr;
  Instr.Addr := Addr_ABY;
  Instr.Code := Op_EOR;
  Instr.Cycles := 4;
  InstrTable[$59] := Instr;

  Instr.Addr := Addr_ABS;
  Instr.Code := Op_INC;
  Instr.Cycles := 6;
  InstrTable[$EE] := Instr;
  Instr.Addr := Addr_ZER;
  Instr.Code := Op_INC;
  Instr.Cycles := 5;
  InstrTable[$E6] := Instr;
  Instr.Addr := Addr_ZEX;
  Instr.Code := Op_INC;
  Instr.Cycles := 6;
  InstrTable[$F6] := Instr;
  Instr.Addr := Addr_ABX;
  Instr.Code := Op_INC;
  Instr.Cycles := 7;
  InstrTable[$FE] := Instr;

  Instr.Addr := Addr_IMP;
  Instr.Code := Op_INX;
  Instr.Cycles := 2;
  InstrTable[$E8] := Instr;

  Instr.Addr := Addr_IMP;
  Instr.Code := Op_INY;
  Instr.Cycles := 2;
  InstrTable[$C8] := Instr;

  Instr.Addr := Addr_ABS;
  Instr.Code := Op_JMP;
  Instr.Cycles := 3;
  InstrTable[$4C] := Instr;
  Instr.Addr := Addr_ABI;
  Instr.Code := Op_JMP;
  Instr.Cycles := 5;
  InstrTable[$6C] := Instr;

  Instr.Addr := Addr_ABS;
  Instr.Code := Op_JSR;
  Instr.Cycles := 6;
  InstrTable[$20] := Instr;

  Instr.Addr := Addr_IMM;
  Instr.Code := Op_LDA;
  Instr.Cycles := 2;
  InstrTable[$A9] := Instr;
  Instr.Addr := Addr_ABS;
  Instr.Code := Op_LDA;
  Instr.Cycles := 4;
  InstrTable[$AD] := Instr;
  Instr.Addr := Addr_ZER;
  Instr.Code := Op_LDA;
  Instr.Cycles := 3;
  InstrTable[$A5] := Instr;
  Instr.Addr := Addr_INX;
  Instr.Code := Op_LDA;
  Instr.Cycles := 6;
  InstrTable[$A1] := Instr;
  Instr.Addr := Addr_INY;
  Instr.Code := Op_LDA;
  Instr.Cycles := 5;
  InstrTable[$B1] := Instr;
  Instr.Addr := Addr_ZEX;
  Instr.Code := Op_LDA;
  Instr.Cycles := 4;
  InstrTable[$B5] := Instr;
  Instr.Addr := Addr_ABX;
  Instr.Code := Op_LDA;
  Instr.Cycles := 4;
  InstrTable[$BD] := Instr;
  Instr.Addr := Addr_ABY;
  Instr.Code := Op_LDA;
  Instr.Cycles := 4;
  InstrTable[$B9] := Instr;

  Instr.Addr := Addr_IMM;
  Instr.Code := Op_LDX;
  Instr.Cycles := 2;
  InstrTable[$A2] := Instr;
  Instr.Addr := Addr_ABS;
  Instr.Code := Op_LDX;
  Instr.Cycles := 4;
  InstrTable[$AE] := Instr;
  Instr.Addr := Addr_ZER;
  Instr.Code := Op_LDX;
  Instr.Cycles := 3;
  InstrTable[$A6] := Instr;
  Instr.Addr := Addr_ABY;
  Instr.Code := Op_LDX;
  Instr.Cycles := 4;
  InstrTable[$BE] := Instr;
  Instr.Addr := Addr_ZEY;
  Instr.Code := Op_LDX;
  Instr.Cycles := 4;
  InstrTable[$B6] := Instr;

  Instr.Addr := Addr_IMM;
  Instr.Code := Op_LDY;
  Instr.Cycles := 2;
  InstrTable[$A0] := Instr;
  Instr.Addr := Addr_ABS;
  Instr.Code := Op_LDY;
  Instr.Cycles := 4;
  InstrTable[$AC] := Instr;
  Instr.Addr := Addr_ZER;
  Instr.Code := Op_LDY;
  Instr.Cycles := 3;
  InstrTable[$A4] := Instr;
  Instr.Addr := Addr_ZEX;
  Instr.Code := Op_LDY;
  Instr.Cycles := 4;
  InstrTable[$B4] := Instr;
  Instr.Addr := Addr_ABX;
  Instr.Code := Op_LDY;
  Instr.Cycles := 4;
  InstrTable[$BC] := Instr;

  Instr.Addr := Addr_ABS;
  Instr.Code := Op_LSR;
  Instr.Cycles := 6;
  InstrTable[$4E] := Instr;
  Instr.Addr := Addr_ZER;
  Instr.Code := Op_LSR;
  Instr.Cycles := 5;
  InstrTable[$46] := Instr;
  Instr.Addr := Addr_ACC;
  Instr.Code := Op_LSR_ACC;
  Instr.Cycles := 2;
  InstrTable[$4A] := Instr;
  Instr.Addr := Addr_ZEX;
  Instr.Code := Op_LSR;
  Instr.Cycles := 6;
  InstrTable[$56] := Instr;
  Instr.Addr := Addr_ABX;
  Instr.Code := Op_LSR;
  Instr.Cycles := 7;
  InstrTable[$5E] := Instr;

  Instr.Addr := Addr_IMP;
  Instr.Code := Op_NOP;
  Instr.Cycles := 2;
  InstrTable[$EA] := Instr;

  Instr.Addr := Addr_IMM;
  Instr.Code := Op_ORA;
  Instr.Cycles := 2;
  InstrTable[$09] := Instr;
  Instr.Addr := Addr_ABS;
  Instr.Code := Op_ORA;
  Instr.Cycles := 4;
  InstrTable[$0D] := Instr;
  Instr.Addr := Addr_ZER;
  Instr.Code := Op_ORA;
  Instr.Cycles := 3;
  InstrTable[$05] := Instr;
  Instr.Addr := Addr_INX;
  Instr.Code := Op_ORA;
  Instr.Cycles := 6;
  InstrTable[$01] := Instr;
  Instr.Addr := Addr_INY;
  Instr.Code := Op_ORA;
  Instr.Cycles := 5;
  InstrTable[$11] := Instr;
  Instr.Addr := Addr_ZEX;
  Instr.Code := Op_ORA;
  Instr.Cycles := 4;
  InstrTable[$15] := Instr;
  Instr.Addr := Addr_ABX;
  Instr.Code := Op_ORA;
  Instr.Cycles := 4;
  InstrTable[$1D] := Instr;
  Instr.Addr := Addr_ABY;
  Instr.Code := Op_ORA;
  Instr.Cycles := 4;
  InstrTable[$19] := Instr;

  Instr.Addr := Addr_IMP;
  Instr.Code := Op_PHA;
  Instr.Cycles := 3;
  InstrTable[$48] := Instr;

  Instr.Addr := Addr_IMP;
  Instr.Code := Op_PHP;
  Instr.Cycles := 3;
  InstrTable[$08] := Instr;

  Instr.Addr := Addr_IMP;
  Instr.Code := Op_PLA;
  Instr.Cycles := 4;
  InstrTable[$68] := Instr;

  Instr.Addr := Addr_IMP;
  Instr.Code := Op_PLP;
  Instr.Cycles := 4;
  InstrTable[$28] := Instr;

  Instr.Addr := Addr_ABS;
  Instr.Code := Op_ROL;
  Instr.Cycles := 6;
  InstrTable[$2E] := Instr;
  Instr.Addr := Addr_ZER;
  Instr.Code := Op_ROL;
  Instr.Cycles := 5;
  InstrTable[$26] := Instr;
  Instr.Addr := Addr_ACC;
  Instr.Code := Op_ROL_ACC;
  Instr.Cycles := 2;
  InstrTable[$2A] := Instr;
  Instr.Addr := Addr_ZEX;
  Instr.Code := Op_ROL;
  Instr.Cycles := 6;
  InstrTable[$36] := Instr;
  Instr.Addr := Addr_ABX;
  Instr.Code := Op_ROL;
  Instr.Cycles := 7;
  InstrTable[$3E] := Instr;

  Instr.Addr := Addr_ABS;
  Instr.Code := Op_ROR;
  Instr.Cycles := 6;
  InstrTable[$6E] := Instr;
  Instr.Addr := Addr_ZER;
  Instr.Code := Op_ROR;
  Instr.Cycles := 5;
  InstrTable[$66] := Instr;
  Instr.Addr := Addr_ACC;
  Instr.Code := Op_ROR_ACC;
  Instr.Cycles := 2;
  InstrTable[$6A] := Instr;
  Instr.Addr := Addr_ZEX;
  Instr.Code := Op_ROR;
  Instr.Cycles := 6;
  InstrTable[$76] := Instr;
  Instr.Addr := Addr_ABX;
  Instr.Code := Op_ROR;
  Instr.Cycles := 7;
  InstrTable[$7E] := Instr;

  Instr.Addr := Addr_IMP;
  Instr.Code := Op_RTI;
  Instr.Cycles := 6;
  InstrTable[$40] := Instr;

  Instr.Addr := Addr_IMP;
  Instr.Code := Op_RTS;
  Instr.Cycles := 6;
  InstrTable[$60] := Instr;

  Instr.Addr := Addr_IMM;
  Instr.Code := Op_SBC;
  Instr.Cycles := 2;
  InstrTable[$E9] := Instr;
  Instr.Addr := Addr_ABS;
  Instr.Code := Op_SBC;
  Instr.Cycles := 4;
  InstrTable[$ED] := Instr;
  Instr.Addr := Addr_ZER;
  Instr.Code := Op_SBC;
  Instr.Cycles := 3;
  InstrTable[$E5] := Instr;
  Instr.Addr := Addr_INX;
  Instr.Code := Op_SBC;
  Instr.Cycles := 6;
  InstrTable[$E1] := Instr;
  Instr.Addr := Addr_INY;
  Instr.Code := Op_SBC;
  Instr.Cycles := 5;
  InstrTable[$F1] := Instr;
  Instr.Addr := Addr_ZEX;
  Instr.Code := Op_SBC;
  Instr.Cycles := 4;
  InstrTable[$F5] := Instr;
  Instr.Addr := Addr_ABX;
  Instr.Code := Op_SBC;
  Instr.Cycles := 4;
  InstrTable[$FD] := Instr;
  Instr.Addr := Addr_ABY;
  Instr.Code := Op_SBC;
  Instr.Cycles := 4;
  InstrTable[$F9] := Instr;

  Instr.Addr := Addr_IMP;
  Instr.Code := Op_SEC;
  Instr.Cycles := 2;
  InstrTable[$38] := Instr;

  Instr.Addr := Addr_IMP;
  Instr.Code := Op_SED;
  Instr.Cycles := 2;
  InstrTable[$F8] := Instr;

  Instr.Addr := Addr_IMP;
  Instr.Code := Op_SEI;
  Instr.Cycles := 2;
  InstrTable[$78] := Instr;

  Instr.Addr := Addr_ABS;
  Instr.Code := Op_STA;
  Instr.Cycles := 4;
  InstrTable[$8D] := Instr;
  Instr.Addr := Addr_ZER;
  Instr.Code := Op_STA;
  Instr.Cycles := 3;
  InstrTable[$85] := Instr;
  Instr.Addr := Addr_INX;
  Instr.Code := Op_STA;
  Instr.Cycles := 6;
  InstrTable[$81] := Instr;
  Instr.Addr := Addr_INY;
  Instr.Code := Op_STA;
  Instr.Cycles := 6;
  InstrTable[$91] := Instr;
  Instr.Addr := Addr_ZEX;
  Instr.Code := Op_STA;
  Instr.Cycles := 4;
  InstrTable[$95] := Instr;
  Instr.Addr := Addr_ABX;
  Instr.Code := Op_STA;
  Instr.Cycles := 5;
  InstrTable[$9D] := Instr;
  Instr.Addr := Addr_ABY;
  Instr.Code := Op_STA;
  Instr.Cycles := 5;
  InstrTable[$99] := Instr;

  Instr.Addr := Addr_ABS;
  Instr.Code := Op_STX;
  Instr.Cycles := 4;
  InstrTable[$8E] := Instr;
  Instr.Addr := Addr_ZER;
  Instr.Code := Op_STX;
  Instr.Cycles := 3;
  InstrTable[$86] := Instr;
  Instr.Addr := Addr_ZEY;
  Instr.Code := Op_STX;
  Instr.Cycles := 4;
  InstrTable[$96] := Instr;

  Instr.Addr := Addr_ABS;
  Instr.Code := Op_STY;
  Instr.Cycles := 4;
  InstrTable[$8C] := Instr;
  Instr.Addr := Addr_ZER;
  Instr.Code := Op_STY;
  Instr.Cycles := 3;
  InstrTable[$84] := Instr;
  Instr.Addr := Addr_ZEX;
  Instr.Code := Op_STY;
  Instr.Cycles := 4;
  InstrTable[$94] := Instr;

  Instr.Addr := Addr_IMP;
  Instr.Code := Op_TAX;
  Instr.Cycles := 2;
  InstrTable[$AA] := Instr;

  Instr.Addr := Addr_IMP;
  Instr.Code := Op_TAY;
  Instr.Cycles := 2;
  InstrTable[$A8] := Instr;

  Instr.Addr := Addr_IMP;
  Instr.Code := Op_TSX;
  Instr.Cycles := 2;
  InstrTable[$BA] := Instr;

  Instr.Addr := Addr_IMP;
  Instr.Code := Op_TXA;
  Instr.Cycles := 2;
  InstrTable[$8A] := Instr;

  Instr.Addr := Addr_IMP;
  Instr.Code := Op_TXS;
  Instr.Cycles := 2;
  InstrTable[$9A] := Instr;

  Instr.Addr := Addr_IMP;
  Instr.Code := Op_TYA;
  Instr.Cycles := 2;
  InstrTable[$98] := Instr;
end;

procedure TMOS6502.SET_NEGATIVE(const Value: Boolean);
begin
  if Value then
    FStatus := FStatus or NEGATIVE_FLAG
  else
    FStatus := FStatus and (not NEGATIVE_FLAG);
end;

procedure TMOS6502.SET_OVERFLOW(const Value: Boolean);
begin
  if Value then
    FStatus := FStatus or OVERFLOW_FLAG
  else
    FStatus := FStatus and (not OVERFLOW_FLAG);
end;

procedure TMOS6502.SET_CONSTANT(const Value: Boolean);
begin
  if Value then
    FStatus := FStatus or CONSTANT
  else
    FStatus := FStatus and (not CONSTANT);
end;

procedure TMOS6502.SET_BREAK(const Value: Boolean);
begin
  if Value then
    FStatus := FStatus or BREAK_CMD
  else
    FStatus := FStatus and (not BREAK_CMD);
end;

procedure TMOS6502.SET_DECIMAL(const Value: Boolean);
begin
  if Value then
    FStatus := FStatus or DECIMAL_FLAG
  else
    FStatus := FStatus and (not DECIMAL_FLAG);
end;

procedure TMOS6502.SET_INTERRUPT(const Value: Boolean);
begin
  if Value then
    FStatus := FStatus or INTERRUPT_FLAG
  else
    FStatus := FStatus and (not INTERRUPT_FLAG);
end;

procedure TMOS6502.SET_ZERO(const Value: Boolean);
begin
  if Value then
    FStatus := FStatus or ZERO_FLAG
  else
    FStatus := FStatus and (not ZERO_FLAG);
end;

procedure TMOS6502.SET_CARRY(const Value: Boolean);
begin
  if Value then
    FStatus := FStatus or CARRY_FLAG
  else
    FStatus := FStatus and (not CARRY_FLAG);
end;


function TMOS6502.IF_NEGATIVE: Boolean;
begin
  Result := ((FStatus and NEGATIVE_FLAG) <> 0);
end;

function TMOS6502.IF_OVERFLOW: Boolean;
begin
  Result := ((FStatus and OVERFLOW_FLAG) <> 0);
end;

function TMOS6502.IF_CONSTANT: Boolean;
begin
  Result := ((FStatus and CONSTANT) <> 0);
end;

function TMOS6502.IF_BREAK: Boolean;
begin
  Result := ((FStatus and BREAK_CMD) <> 0);
end;

function TMOS6502.IF_DECIMAL: Boolean;
begin
  Result := ((FStatus and DECIMAL_FLAG) <> 0);
end;

function TMOS6502.IF_INTERRUPT: Boolean;
begin
  Result := ((FStatus and INTERRUPT_FLAG) <> 0);
end;

function TMOS6502.IF_ZERO: Boolean;
begin
  Result := ((FStatus and ZERO_FLAG) <> 0);
end;

function TMOS6502.IF_CARRY: Byte;
begin
  if (FStatus and CARRY_FLAG) <> 0 then
    Result := 1
  else
    Result := 0;
end;

procedure TMOS6502.Exec(Instr: TInstr);
var
  Src: Word;
begin
  Src := Instr.Addr;
  Instr.Code(Src);
end;

function TMOS6502.Addr_ACC: Word;
begin
  Result := 0; // not used
end;

function TMOS6502.Addr_IMM: Word;
begin
  Result := FPC;
  Inc(FPC);
end;

function TMOS6502.Addr_ABS: Word;
var
  AddrL, AddrH, Addr: Word;
begin
  AddrL := FBusReadEvent(FPC);
  Inc(FPC);
  AddrH := FBusReadEvent(FPC);
  Inc(FPC);

  Addr := AddrL + (AddrH shl 8);

  Result := Addr;
end;

function TMOS6502.Addr_ZER: Word;
begin
  Result := FBusReadEvent(FPC);
  Inc(FPC);
end;

function TMOS6502.Addr_IMP: Word;
begin
  Result := 0; // not used
end;

function TMOS6502.Addr_REL: Word;
var
  Offset, Addr: Word;
begin
  Offset := FBusReadEvent(FPC);
  Inc(FPC);
  if (Offset and $80) <> 0 then
    Offset := Offset or $FF00;

  {$R-}Addr := FPC + Offset;{$R+}
  Result := Addr;
end;

function TMOS6502.Addr_ABI: Word;
var
  AddrL, AddrH, EffL, EffH, Abs, Addr: Word;
begin
  AddrL := FBusReadEvent(FPC);
  Inc(FPC);
  AddrH := FBusReadEvent(FPC);
  Inc(FPC);

  Abs := (AddrH shl 8) or AddrL;
  EffL := FBusReadEvent(Abs);
  EffH := FBusReadEvent((Abs and $FF00) + ((Abs + 1) and $00FF));

  Addr := EffL + $100 * EffH;
  Result := Addr;
end;

function TMOS6502.Addr_ZEX: Word;
var
  Addr: Word;
begin
  Addr := (FBusReadEvent(FPC) + FX) mod 256;
  Inc(FPC);
  Result := Addr;
end;

function TMOS6502.Addr_ZEY: Word;
var
  Addr: Word;
begin
  Addr := (FBusReadEvent(FPC) + FY) mod 256;
  Inc(FPC);
  Result := Addr;
end;

function TMOS6502.Addr_ABX: Word;
var
  AddrL: Word;
  AddrH: Word;
  Addr: Word;
begin
  AddrL := FBusReadEvent(FPC);
  Inc(FPC);
  AddrH := FBusReadEvent(FPC);
  Inc(FPC);

  Addr := AddrL + (AddrH shl 8) + FX;
  Result := Addr;
end;

function TMOS6502.Addr_ABY: Word;
var
  AddrL: Word;
  AddrH: Word;
  Addr: Word;
begin
  AddrL := FBusReadEvent(FPC);
  Inc(FPC);
  AddrH := FBusReadEvent(FPC);
  Inc(FPC);

  Addr := AddrL + (AddrH shl 8) + FY;
  Result := Addr;
end;

function TMOS6502.Addr_INX: Word;
var
  ZeroL, ZeroH: Word;
  Addr: Word;
begin
  ZeroL := (FBusReadEvent(FPC) + FX) mod 256;
  Inc(FPC);
  ZeroH := (ZeroL + 1) mod 256;
  Addr := FBusReadEvent(ZeroL) + (FBusReadEvent(ZeroH) shl 8);
  Result := Addr;
end;

function TMOS6502.Addr_INY: Word;
var
  ZeroL, ZeroH: Word;
  Addr: Word;
begin
  ZeroL := FBusReadEvent(FPC);
  Inc(FPC);

  ZeroH := (ZeroL + 1) mod 256;
  Addr := FBusReadEvent(ZeroL) + (FBusReadEvent(ZeroH) shl 8) + FY;
  Result := Addr;
end;

procedure TMOS6502.Reset;
begin
  FA := $aa;
  FX := $00;
  FY := $00;

  FStatus := BREAK_CMD or INTERRUPT_FLAG OR ZERO_FLAG or CONSTANT;
  FSP := $FD;

  FPC := (FBusReadEvent(RSTVECTORH) shl 8) + FBusReadEvent(RSTVECTORL); // load FPC from reset vector

  FCycles := 6; // according to the datasheet, the reset routine takes 6 clock FCycles
  FIllegalOpcode := false;
end;

procedure TMOS6502.StackPush(const Value: Byte);
begin
  FBusWriteEvent($0100 + FSP, Value);
  if FSP = $00 then
    FSP := $FF
  else
    Dec(FSP);
end;

function TMOS6502.StackPop: Byte;
begin
  if FSP = $FF then
    FSP := $00
  else
    Inc(FSP);

  Result := FBusReadEvent($0100 + FSP);
end;

procedure TMOS6502.IRQ;
begin
  if (not IF_INTERRUPT) then
  begin
    SET_BREAK(False);
    StackPush((FPC shr 8) and $FF);
    StackPush(FPC and $FF);
    StackPush(FStatus);
    SET_INTERRUPT(True);
    FPC := (FBusReadEvent(IRQVECTORH) shl 8) + FBusReadEvent(IRQVECTORL);
  end;
end;

procedure TMOS6502.NMI;
begin
  SET_BREAK(false);
  StackPush((FPC shr 8) and $FF);
  StackPush(FPC and $FF);
  StackPush(FStatus);
  SET_INTERRUPT(True);
  FPC := (FBusReadEvent(NMIVECTORH) shl 8) + FBusReadEvent(NMIVECTORL);
end;

procedure TMOS6502.Step;
(*
var
  Opcode: Byte;
  Instr: PInstr;
  Src: Word;
begin
  // fetch
  Opcode := FBusRead(FPC);
  {$R-}Inc(FPC);{$R+}

  // decode and execute
  Instr := @InstrTable[Opcode];
  Src := Instr.Addr;
  Instr.Code(Src);

  Inc(FCycles);
end;
*)
var
  cc : UInt64;
begin
  cc := 0;
  Run(1,cc,INST_COUNT);
end;

procedure TMOS6502.Run(Cycles: Cardinal; var CycleCount: UInt64;
  CycleMethod: TCycleMethod);
var
  Opcode: Byte;
  Instr: PInstr;
  CyclesRemaining : Cardinal;
  i : Integer;
begin
  CyclesRemaining := Cycles;
  while(CyclesRemaining > 0) and (not FIllegalOpcode) do
  begin
    // fetch
    Opcode := FBusReadEvent(FPC);
    {$R-}Inc(FPC);{$R+}

    // decode and execute
    Instr := @InstrTable[Opcode];
    Exec(Instr^);
    {$R-}
      FCycles := FCycles + Instr^.cycles;
      CycleCount := CycleCount + Instr^.cycles;
    {$R+}
    if CycleMethod = CYCLE_COUNT then
    begin
      if CyclesRemaining >= Instr^.cycles then
        CyclesRemaining := CyclesRemaining - Instr^.cycles
      else
        CyclesRemaining := 0;
    end
    else
      Dec(CyclesRemaining);
    if Assigned(FClockCycleEvent) then
    begin
      for i := 0 to Instr^.cycles-1 do
        FClockCycleEvent(Self);
    end;
  end;
end;


procedure TMOS6502.RunEternally;
var
  Opcode: Byte;
  Instr: PInstr;
  i : Integer;
begin
  while (not FIllegalOpcode) do
  begin
    // fetch
    Opcode := FBusReadEvent(FPC);
    {$R-}Inc(FPC);{$R+}

    // decode and execute
    Instr := @InstrTable[Opcode];
    Exec(Instr^);
    {$R-}FCycles := FCycles + Instr^.cycles;{$R+}
    if Assigned(FClockCycleEvent) then
    begin
      for i := 0 to Instr^.cycles-1 do
        FClockCycleEvent(Self);
    end;
  end;
end;

procedure TMOS6502.Op_ILLEGAL(Src: Word);
begin
  FIllegalOpcode := true;
end;

procedure TMOS6502.Op_AND(Src: Word);
var
  M: Byte;
  Res: Byte;
begin
  M := FBusReadEvent(Src);
  Res := M and FA;
  SET_NEGATIVE((Res and $80) <> 0);
  SET_ZERO(Res = 0);
  FA := Res;
end;

procedure TMOS6502.Op_ASL(Src: Word);
var
  M: Byte;
begin
  M := FBusReadEvent(Src);
  SET_CARRY((M and $80) <> 0);
  {$R-}M := M shl 1;{$R+}
  M := M and $FF;
  SET_NEGATIVE((M and $80) <> 0);
  SET_ZERO(M = 0);
  FBusWriteEvent(Src, M);
end;

procedure TMOS6502.Op_ASL_ACC(Src: Word);
var
  M: Byte;
begin
  M := FA;
  SET_CARRY((M and $80) <> 0);
  {$R-}M := M shl 1;{$R+}
  M := M and $FF;
  SET_NEGATIVE((M and $80) <> 0);
  SET_ZERO(M = 0);
  FA := M;
end;

procedure TMOS6502.Op_BCC(Src: Word);
begin
  if IF_CARRY = 0 then
    FPC := Src;
end;

procedure TMOS6502.Op_BCS(Src: Word);
begin
  if IF_CARRY = 1 then
    FPC := Src;
end;

procedure TMOS6502.Op_BEQ(Src: Word);
begin
  if IF_ZERO then
    FPC := Src;
end;

procedure TMOS6502.Op_BIT(Src: Word);
var
  M: Byte;
  Res: Byte;
begin
  M := FBusReadEvent(Src);
  Res := M and FA;
  SET_NEGATIVE((Res and $80) <> 0);
  FStatus := (FStatus and $3F) or (M and $C0);
  SET_ZERO(Res = 0);
end;

procedure TMOS6502.Op_BMI(Src: Word);
begin
  if IF_NEGATIVE then
    FPC := Src;
end;

procedure TMOS6502.Op_BNE(Src: Word);
begin
  if not (IF_ZERO) then
    FPC := Src;
end;

procedure TMOS6502.Op_BPL(Src: Word);
begin
  if not (IF_NEGATIVE) then
    FPC := Src;
end;

procedure TMOS6502.Op_BRK(Src: Word);
begin
  Inc(FPC);
  StackPush((FPC shr 8) and $FF);
  StackPush(FPC and $FF);
  StackPush(FStatus or BREAK_CMD);
  SET_INTERRUPT(True);
  FPC := (FBusReadEvent(IRQVECTORH) shl 8) + FBusReadEvent(IRQVECTORL);
end;

procedure TMOS6502.Op_BVC(Src: Word);
begin
  if not (IF_OVERFLOW) then
    FPC := Src;
end;

procedure TMOS6502.Op_BVS(Src: Word);
begin
  if IF_OVERFLOW then
    FPC := Src;
end;

procedure TMOS6502.Op_CLC(Src: Word);
begin
  SET_CARRY(False);
end;

procedure TMOS6502.Op_CLD(Src: Word);
begin
  SET_DECIMAL(False);
end;

procedure TMOS6502.Op_CLI(Src: Word);
begin
  SET_INTERRUPT(False);
end;

procedure TMOS6502.Op_CLV(Src: Word);
begin
  SET_OVERFLOW(False);
end;

procedure TMOS6502.Op_CMP(Src: Word);
var
  Tmp: Cardinal;
begin
  {$R-}Tmp := FA - FBusReadEvent(Src);{$R+}
  SET_CARRY(Tmp < $100);
  SET_NEGATIVE((Tmp and $80) <> 0);
  SET_ZERO((Tmp and $FF)=0);
end;

procedure TMOS6502.Op_CPX(Src: Word);
var
  Tmp: Cardinal;
begin
  {$R-}Tmp := FX - FBusReadEvent(Src);{$R+}
  SET_CARRY(Tmp < $100);
  SET_NEGATIVE((Tmp and $80) <> 0);
  SET_ZERO((Tmp and $FF)=0);
end;

procedure TMOS6502.Op_CPY(Src: Word);
var
  Tmp: Cardinal;
begin
  {$R-}Tmp := FY - FBusReadEvent(Src);{$R+}
  SET_CARRY(Tmp < $100);
  SET_NEGATIVE((Tmp and $80) <> 0);
  SET_ZERO((Tmp and $FF)=0);
end;

procedure TMOS6502.Op_DEC(Src: Word);
var
  M: Byte;
begin
  M := FBusReadEvent(Src);
  {$R-}M := M - 1;{$R+}
  SET_NEGATIVE((M and $80) <> 0);
  SET_ZERO(M = 0);
  FBusWriteEvent(Src, M);
end;

procedure TMOS6502.Op_DEX(Src: Word);
var
  M: Byte;
begin
  M := FX;
  {$R-}M := M - 1;{$R+}
  SET_NEGATIVE((M and $80) <> 0);
  SET_ZERO(M = 0);
  FX := M;
end;

procedure TMOS6502.Op_DEY(Src: Word);
var
  M: Byte;
begin
  M := FY;
  {$R-}M := M - 1;{$R+}
  SET_NEGATIVE((M and $80) <> 0);
  SET_ZERO(M = 0);
  FY := M;
end;

procedure TMOS6502.Op_EOR(Src: Word);
var
  M: Byte;
begin
  M := FBusReadEvent(Src);
  {$R-}M := FA xor M;{$R+}
  SET_NEGATIVE((M and $80) <> 0);
  SET_ZERO(M = 0);
  FA := M;
end;

procedure TMOS6502.Op_INC(Src: Word);
var
  M: Byte;
begin
  M := FBusReadEvent(Src);
  {$R-}M := M + 1;{$R+}
  SET_NEGATIVE((M and $80) <> 0);
  SET_ZERO(M = 0);
  FBusWriteEvent(Src, M);
end;

procedure TMOS6502.Op_INX(Src: Word);
var
  M: Byte;
begin
  M := FX;
  {$R-}M := M + 1;{$R+}
  SET_NEGATIVE((M and $80) <> 0);
  SET_ZERO(M = 0);
  FX := M;
end;

procedure TMOS6502.Op_INY(Src: Word);
var
  M: Byte;
begin
  M := FY;
  {$R-}M := M + 1;{$R+}
  SET_NEGATIVE((M and $80) <> 0);
  SET_ZERO(M = 0);
  FY := M;
end;

procedure TMOS6502.Op_JMP(Src: Word);
begin
  FPC := Src;
end;

procedure TMOS6502.Op_JSR(Src: Word);
begin
  Dec(FPC);
  StackPush((FPC shr 8) and $FF);
  StackPush(FPC and $FF);
  FPC := Src;
end;

procedure TMOS6502.Op_LDA(Src: Word);
var
  M: Byte;
begin
  M := FBusReadEvent(Src);
  SET_NEGATIVE((M and $80) <> 0);
  SET_ZERO(M = 0);
  FA := M;
end;

procedure TMOS6502.Op_LDX(Src: Word);
var
  M: Byte;
begin
  M := FBusReadEvent(Src);
  SET_NEGATIVE((M and $80) <> 0);
  SET_ZERO(M = 0);
  FX := M;
end;

procedure TMOS6502.Op_LDY(Src: Word);
var
  M: Byte;
begin
  M := FBusReadEvent(Src);
  SET_NEGATIVE((M and $80) <> 0);
  SET_ZERO(M = 0);
  FY := M;
end;

procedure TMOS6502.Op_LSR(Src: Word);
var
  M: Byte;
begin
  M := FBusReadEvent(Src);
  SET_CARRY((M and $01) <> 0);
  M := M shr 1;
  SET_NEGATIVE(False);
  SET_ZERO(M = 0);
  FBusWriteEvent(Src, M);
end;

procedure TMOS6502.Op_LSR_ACC(Src: Word);
var
  M: Byte;
begin
  M := FA;
  SET_CARRY((M and $01) <> 0);
  M := M shr 1;
  SET_NEGATIVE(False);
  SET_ZERO(M = 0);
  FA := M;
end;

procedure TMOS6502.Op_NOP(Src: Word);
begin
  // no operation
end;

procedure TMOS6502.Op_ORA(Src: Word);
var
  M: Byte;
begin
  M := FBusReadEvent(Src);
  M := FA or M;
  SET_NEGATIVE((M and $80) <> 0);
  SET_ZERO(M = 0);
  FA := M;
end;

procedure TMOS6502.Op_PHA(Src: Word);
begin
  StackPush(FA);
end;

procedure TMOS6502.Op_PHP(Src: Word);
begin
  StackPush(FStatus or BREAK_CMD);
end;

procedure TMOS6502.Op_PLA(Src: Word);
begin
  FA := StackPop;
  SET_NEGATIVE((FA and $80) <> 0);
  SET_ZERO(FA = 0);
end;

procedure TMOS6502.Op_PLP(Src: Word);
begin
  FStatus := StackPop;
  SET_CONSTANT(True);
end;

procedure TMOS6502.Op_ROL(Src: Word);
var
  M: Word;
begin
  M := FBusReadEvent(Src);
  M := M shl 1;
  if IF_CARRY = 1 then
    M := M or $01;
  SET_CARRY(M > $FF);
  M := M and $FF;
  SET_NEGATIVE((M and $80) <> 0);
  SET_ZERO(M = 0);
  FBusWriteEvent(Src, M);
end;

procedure TMOS6502.Op_ROL_ACC(Src: Word);
var
  M: Word;
begin
  M := FA;
  M := M shl 1;
  if IF_CARRY = 1 then
    M := M or $01;
  SET_CARRY(M > $FF);
  M := M and $FF;
  SET_NEGATIVE((M and $80) <> 0);
  SET_ZERO(M = 0);
  FA := M;
end;

procedure TMOS6502.Op_ROR(Src: Word);
var
  M: Word;
begin
  M := FBusReadEvent(Src);
  if IF_CARRY = 1 then
    M := M or $100;
  SET_CARRY((M and $01) <> 0);
  M := M shr 1;
  M := M and $FF;
  SET_NEGATIVE((M and $80) <> 0);
  SET_ZERO(M = 0);
  FBusWriteEvent(Src, M);
end;

procedure TMOS6502.Op_ROR_ACC(Src: Word);
var
  M: Word;
begin
  M := FA;
  if IF_CARRY = 1 then
    M := M or $100;
    SET_CARRY((M and $01) <> 0);
  M := M shr 1;
  M := M and $FF;
  SET_NEGATIVE((M and $80) <> 0);
  SET_ZERO(M = 0);
  FA := M;
end;

procedure TMOS6502.Op_RTI(Src: Word);
var
  Lo, Hi: Byte;
begin
  FStatus := StackPop;

  Lo := StackPop;
  Hi := StackPop;

  FPC := (Hi shl 8) or Lo;
end;

procedure TMOS6502.Op_RTS(Src: Word);
var
  Lo, Hi: Byte;
begin
  Lo := StackPop;
  Hi := StackPop;

  FPC := (Hi shl 8) or Lo + 1;
end;

procedure TMOS6502.Op_ADC(Src: Word);
var
  M: Byte;
  Tmp: Cardinal;
begin
  M := FBusReadEvent(Src);
  Tmp := M + FA + IF_CARRY;

  SET_ZERO((Tmp and $FF)=0);

  if IF_DECIMAL then
  begin
    if (((FA and $F) + (M and $F) + IF_CARRY) > 9) then
      Tmp := Tmp + 6;

    SET_NEGATIVE((Tmp and $80) <> 0);

    SET_OVERFLOW( (((FA xor M) and $80) = 0) and (((FA xor Tmp) and $80) <> 0));

    if Tmp > $99 then
      Tmp := Tmp + $60;

    SET_CARRY(Tmp > $99);
  end
  else
  begin
    SET_NEGATIVE((Tmp and $80) <> 0);
    SET_OVERFLOW( (((FA xor M) and $80)=0) and (((FA xor Tmp) and $80) <> 0));
    SET_CARRY(Tmp > $FF);
  end;

  FA := Tmp and $FF;
end;


procedure TMOS6502.Op_SBC(Src: Word);
var
  M: Byte;
  Tmp: Word;
begin
  M := FBusReadEvent(Src);
  {$R-}Tmp := FA - M - (1-IF_CARRY);{$R+}

  SET_NEGATIVE((Tmp and $80) <> 0);

  SET_ZERO((Tmp and $FF) = 0);

   SET_OVERFLOW( (((FA xor Tmp) and $80) <> 0)  and (((FA xor M) and $80) <> 0));

  if IF_DECIMAL then
  begin
    if (((FA and $0F) - (1-IF_CARRY)) < (M and $0F)) then
      Tmp := Tmp - 6;

    if Tmp > $99 then
      Tmp := Tmp - $60;
  end;

  SET_CARRY(Tmp < $100);
  FA := (Tmp and $FF);
end;

procedure TMOS6502.Op_SEC(Src: Word);
begin
  SET_CARRY(True);
end;

procedure TMOS6502.Op_SED(Src: Word);
begin
  SET_DECIMAL(True);
end;

procedure TMOS6502.Op_SEI(Src: Word);
begin
  SET_INTERRUPT(True);
end;

procedure TMOS6502.Op_STA(Src: Word);
begin
  FBusWriteEvent(Src, FA);
end;

procedure TMOS6502.Op_STX(Src: Word);
begin
  FBusWriteEvent(Src, FX);
end;

procedure TMOS6502.Op_STY(Src: Word);
begin
  FBusWriteEvent(Src, FY);
end;

procedure TMOS6502.Op_TAX(Src: Word);
var
  M: Byte;
begin
  M := FA;
  SET_NEGATIVE((M and $80) <> 0);
  SET_ZERO(M = 0);
  FX := M;
end;

procedure TMOS6502.Op_TAY(Src: Word);
var
  M: Byte;
begin
  M := FA;
  SET_NEGATIVE((M and $80) <> 0);
  SET_ZERO(M = 0);
  FY := M;
end;

procedure TMOS6502.Op_TSX(Src: Word);
var
  M: Byte;
begin
  M := FSP;
  SET_NEGATIVE((M and $80) <> 0);
  SET_ZERO(M = 0);
  FX := M;
end;

procedure TMOS6502.Op_TXA(Src: Word);
var
  M: Byte;
begin
  M := FX;
  SET_NEGATIVE((M and $80) <> 0);
  SET_ZERO(M = 0);
  FA := M;
end;

procedure TMOS6502.Op_TXS(Src: Word);
begin
  FSP := FX;
end;

procedure TMOS6502.Op_TYA(Src: Word);
var
  M: Byte;
begin
  M := FY;
  SET_NEGATIVE((M and $80) <> 0);
  SET_ZERO(M = 0);
  FA := M;
end;

end.
