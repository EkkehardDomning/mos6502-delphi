program C64Emu;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

uses
  {$IFnDEF FPC}
  Vcl.Forms,
  {$ELSE}
  Forms, Interfaces,
  {$ENDIF }
  FormC64 in 'FormC64.pas' {FrmC64},
  C64 in 'C64.pas',
  MOS6502 in '..\..\Source\MOS6502.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFrmC64, FrmC64);
  Application.Run;
end.
