program LAMWManager;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
    cthreads,
    cmem, // the c memory manager is on some systems much faster for multi-threading
    {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, umain, uglobal, uproxy
  { you can add units after this };

{$R *.res}

begin
  Application.Title:='LAMW Manager';
  RequireDerivedFormResource:=True;
  Application.Initialize;
  Application.CreateForm(TFmain, Fmain);
  Application.CreateForm(TFormProxy, FormProxy);
  Application.Run;
end.

