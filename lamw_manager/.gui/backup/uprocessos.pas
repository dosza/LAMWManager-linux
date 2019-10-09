unit uprocessos;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Process,Math,uglobal,FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls;
type
    {Class RunnableScripts }

    { RunnableScripts }

    RunnableScripts = Class
      private
        args:TStringList;
        exitCode : integer;   //code exit program
        exitStatus : integer; // signal of system kill process, segmentation fault ...
        strError : TStringList;

        debug: boolean;





      public
          strOut: TStringList;
         ref_memo: TMemo;
         procedure RunProcess();
         procedure RunProcessAsConsole();
         procedure RunProcessAsRoot();
         procedure RunProcessAsRootNoConsole();
         procedure RunProcessAsPoliceKit();
         function getExitCode() : integer;
         function getExitStatus():integer;
         function getStrOut(): TstringList;
         function getStrError(): TStringList ;
         constructor Create (c_args:TStringList);
         constructor Create(c_args: TStringList; flag_debug :boolean);
         procedure setStrOut (ref_strout : TStringList);



  end;


implementation
procedure   RunnableScripts.RunProcessAsConsole();
var

    hprocess: TProcess;
    i : integer;

Begin
  i := 0;
  DetectXTerm();  //função importante! Detecta o tipo de emulador de terminal
  try   //tente executar o processo

    hprocess := TProcess.Create(nil);
    hprocess.Executable := '/bin/bash';
    if ( self.args <> nil ) then begin
      while (i < (args.Count) ) do
      begin
        write(args[i] + ' ');
        hprocess.Parameters.Add(args[i]);
        i := i  + 1;
      end;
      writeln('');
     // writeln('Exit CODE = ',hprocess.ExitCode,'EXIT_STATUS = ',hprocess.ExitStatus);
      hprocess.Options:= hprocess.Options + [poWaitOnExit,poUsePipes,poNewConsole];
      // hprocess.Options := hProcess.Options + [poWaitOnExit, poUsePipes, poNewConsole];  // poNewConsole  é para terminais
      hprocess.Execute;         // Execute o comando
      Self.exitCode:= hprocess.ExitCode;
      Self.exitStatus:= hprocess.ExitStatus;
      //Self.strError := TStringList.Create;
      Self.strError.LoadFromStream(hprocess.Stderr);
      Self.strError.SaveToFile('err.txt');
      Self.strOut := TStringList.Create;
      Self.strOut.LoadFromStream(hprocess.Output);
      Self.strOut.SaveToFile('out.txt');
    //  writeln('Exit CODE = ',hprocess.ExitCode,'EXIT_STATUS = ',hprocess.ExitStatus);
       //Sleep(2000);
    end else
        Writeln('args is null');
  finally
    hprocess.Free;
  end;
end;
procedure   RunnableScripts.RunProcess();
var

    hprocess: TProcess;
    i : integer;

Begin
  i := 0;
  DetectXTerm();  //função importante! Detecta o tipo de emulador de terminal
  try   //tente executar o processo

    hprocess := TProcess.Create(nil);
    hprocess.Executable := '/bin/bash';
    if ( self.args <> nil ) then begin
      while (i < (args.Count) ) do
      begin
        write(args[i] + ' ');
        hprocess.Parameters.Add(args[i]);
        i := i  + 1;
      end;
      writeln('');
     // writeln('Exit CODE = ',hprocess.ExitCode,'EXIT_STATUS = ',hprocess.ExitStatus);
      hprocess.Options:= hprocess.Options + [poWaitOnExit,poUsePipes,poNoConsole];
      // hprocess.Options := hProcess.Options + [poWaitOnExit, poUsePipes, poNewConsole];  // poNewConsole  é para terminais
      hprocess.Execute;         // Execute o comando
      Self.exitCode:= hprocess.ExitCode;
      Self.exitStatus:= hprocess.ExitStatus;
      //Self.strError := TStringList.Create;
      Self.strError.LoadFromStream(hprocess.Stderr);
      Self.strError.SaveToFile('err.txt');
      Self.strOut := TStringList.Create;
      Self.strOut.LoadFromStream(hprocess.Output);
      Self.strOut.SaveToFile('out.txt');
    //  writeln('Exit CODE = ',hprocess.ExitCode,'EXIT_STATUS = ',hprocess.ExitStatus);
       //Sleep(2000);
    end else
        Writeln('args is null');
  finally
    hprocess.Free;
  end;
end;
constructor RunnableScripts.Create ( c_args : TStringList);
begin
  //proc := c_proc;
  Self.args := c_args;
  Self.exitCode:= -1;
  Self.exitStatus:= -1;
  Self.strError:= TStringList.Create;
 // Self.strOut := TStringList.Create;
  Self.debug := false;
end;

constructor RunnableScripts.Create(c_args: TStringList; flag_debug: boolean);
begin
  Self.args := c_args;
  Self.debug := flag_debug;
  Self.exitCode := -1;
  Self.exitStatus:= -1;
  Self.strError := nil;
  Self.strOut := nil;
end;

procedure RunnableScripts.setStrOut(ref_strout : TStringList);
begin
  Self.strOut :=ref_strout;
end;

 {
      Procedure para executar processos com o pkexec
      PoliceKit
      No entanto, use esta função apenas se não precisar de $DISPLAY
      $XAUTHORITY
 }
  procedure RunnableScripts.RunProcessAsPoliceKit();
  var
      hprocess: TProcess;
      i : integer;
  begin
    writeln('Running in root mode');
    i := 0;
    DetectXTerm();
    try
      hprocess := TProcess.Create(nil);
      hprocess.Executable := 'pkexec'; //pkexec é o processo com super poderes
      hprocess.Parameters.Add('/bin/bash');
      if ( Self.args <> nil )  then begin  //verifica se args não é nulo
            while (i < (Self.args.Count) ) do begin
                hprocess.Parameters.Add(args[i]);    //adiciona cada um dos parametros de linha de comando
                i := i  + 1;
            end;
            if ( Self.debug = False ) then
               hprocess.Options := hProcess.Options + [poWaitOnExit, poUsePipes, poNoConsole]
           else
               hprocess.Options := hProcess.Options + [poWaitOnExit, poUsePipes, poNewConsole];
            hprocess.Execute;
           Self.strError := TStringList.Create;
            Self.strOut := TStringList.Create;
            Self.exitCode:= hprocess.ExitCode;
            Self.exitStatus:= hprocess.ExitStatus;
            Self.strError.LoadFromStream(hprocess.Stderr);
            Self.strOut.LoadFromStream(hprocess.Output);
            if ( Self.debug = False ) then
            begin
            // if ( Self.strError <> nil ) then
              Self.strError.SaveToFile('err.txt');
              Self.strOut.SaveToFile('out.txt');
            end;
          //hprocess.Free;
    end else
        WriteLn('from from runasRoot : args is null');
    finally
      WriteLn('Terminei o processo');
      hprocess.Free;
    end;

  end;

  function RunnableScripts.getExitCode(): integer;
  begin
    Result:= Self.exitCode;
  end;

  function RunnableScripts.getExitStatus(): integer;
  begin
    Result := Self.exitStatus;
  end;

  function RunnableScripts.getStrOut(): TstringList;
  begin
    Result := Self.strOut;
  end;

  function RunnableScripts.getStrError(): TStringList;
  begin
    Result:= Self.strError;
  end;




  {
        Procedimento para executar o processo em root
        usando uma bridge (ponte)
  }
  procedure RunnableScripts.RunProcessAsRoot();
var
      hprocess: TProcess;
    i : integer;
begin
  i := 0;
  writeln('Run as bridge root');
  DetectXTerm();  //função importante! Detecta o tipo de emulador de terminal
  hprocess := TProcess.Create(nil);
  hprocess.Executable := '/bin/bash';
  hprocess.Parameters.Add(uglobal.BRIDGE_ROOT); //caminho do script bridge
  hprocess.Parameters.Add('/bin/bash');
  while (i < (args.Count) ) do begin
    write(args[i] + ' ');
    hprocess.Parameters.Add(args[i]);
    i := i  + 1;
   end;
  writeln('');
   if ( Self.debug = False ) then
               hprocess.Options := hProcess.Options + [poWaitOnExit, poUsePipes, poNoConsole]
           else
               hprocess.Options := hProcess.Options + [poWaitOnExit, poUsePipes, poNewConsole]; //poNewConsole é par terminais;
   hprocess.Execute;         // Execute o comando
   if ( hprocess.Running = false ) then
      writeln('Terminei de executar');
   Self.exitCode:= hprocess.ExitCode;
   Self.exitStatus:= hprocess.ExitStatus;
  //Self.strError := TStringList.Create;
  Self.strError.LoadFromStream(hprocess.Stderr);
  Self.strError.SaveToFile('err.txt');
  Self.strOut := TStringList.Create;
  Self.strOut.LoadFromStream(hprocess.Output);
  Self.strOut.SaveToFile('out.txt');
   hprocess.Free;
end;

    procedure RunnableScripts.RunProcessAsRootNoConsole();
 var
      hprocess: TProcess;
    i : integer;
  CharBuffer: array [0..511] of char;
   p, ReadCount: integer;
   strExt, strTemp: string;
begin
  i := 0;
  writeln('Run as bridge root');
  DetectXTerm();  //função importante! Detecta o tipo de emulador de terminal
  hprocess := TProcess.Create(nil);
  hprocess.Executable := '/bin/bash';
  hprocess.Parameters.Add(uglobal.BRIDGE_ROOT); //caminho do script bridge
  hprocess.Parameters.Add('/bin/bash');
  while (i < (args.Count) ) do begin
    write(args[i] + ' ');
    hprocess.Parameters.Add(args[i]);
    i := i  + 1;
   end;
  writeln('');
   hprocess.Options := hProcess.Options + [poWaitOnExit, poUsePipes, poNoConsole];  // poNewConsole  é para terminais
   hprocess.Execute;         // Execute o comando
   Self.exitCode:= hprocess.ExitCode;
   Self.exitStatus:= hprocess.ExitStatus;
   while ( hprocess.Running ) do
   begin
     while (hprocess.Output.NumBytesAvailable > 0 ) do
     begin
      ReadCount := Min(512, hprocess.Output.NumBytesAvailable); //Read up to buffer, not more
          hprocess.Output.Read(CharBuffer, ReadCount);
          strTemp:= Copy(CharBuffer, 0, ReadCount);
     end
   end;

   //Sleep(2000);
   hprocess.Free;
end;

end.

