unit umain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, Menus,uprocessos,uglobal,uproxy,Process;

type

  { TFmain }

  TFmain = class(TForm)
    Button1: TButton;
    CheckBox1: TCheckBox;
    Image1: TImage;
    Image2: TImage;
    Image3: TImage;
    ImageList1: TImageList;
    MainMenu1: TMainMenu;
    MenuItem1: TMenuItem;
    MenuItem10: TMenuItem;
    MenuItem11: TMenuItem;
    MenuItem12: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    MenuItem7: TMenuItem;
    MenuItem8: TMenuItem;
    MenuItem9: TMenuItem;
    Panel1: TPanel;
    Panel2: TPanel;
    procedure Button1Click(Sender: TObject);
    procedure CheckBox1Change(Sender: TObject);
   // procedure CheckBox2Change(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Image1Click(Sender: TObject);
    procedure Image2Click(Sender: TObject);
    procedure Image3Click(Sender: TObject);
    procedure Image4Click(Sender: TObject);
    procedure Label1Click(Sender: TObject);
    procedure Label4Click(Sender: TObject);
    procedure Label5Click(Sender: TObject);
    procedure Label7Click(Sender: TObject);
    procedure MenuItem12Click(Sender: TObject);
    procedure MenuItem1Click(Sender: TObject);
    procedure MenuItem4Click(Sender: TObject);
    procedure MenuItem8Click(Sender: TObject);
    procedure MenuItem9Click(Sender: TObject);
    procedure Panel1Click(Sender: TObject);
    procedure ToggleBox1Change(Sender: TObject);
  private
    cmd_args : TstringList;
    proc : RunnableScripts;
    count_img: integer;
  public

  end;
  GUIThread = class(TThread)
  private
    str_msg: string;
    //    proc : RunnableScripts;

    ref_outproc: Tmemo;
    //ref_progressbar: TProgressBar;
    ref_proc: TProcess;
    args: TStringList;
    StrTemp: string;
  public
    constructor Create(mymemo: tmemo; cargs: TStringList);
      reintroduce;
    procedure Sincronize();
    procedure SinFim();
    procedure Execute; override;
  end;

var
  Fmain: TFmain;

implementation

{$R *.lfm}

{GUI TREAD}
procedure GUIThread.Execute;
var
  i, exitCode, exitStatus, ReadCount: integer;
  debug: boolean;
  CharBuffer: array [0..511] of char;
begin
  i := 0;
  //   inherited;
  if (flag_stop) then;         //a thread cria um processo em grava o output em uma string
  begin
    ref_proc.Executable := '/bin/bash';
  //  ref_proc.Parameters.Add(uglobal.BRIDGE_ROOT); //caminho do script bridge
    ref_proc.Parameters.Add(uglobal.LAMW_MAIN_SCRIPT );
    while (i < (args.Count)) do
    begin
      Write(args[i] + ' ');
      ref_proc.Parameters.Add(args[i]);
      i := i + 1;
    end;
    writeln('');
    ref_proc.Options := ref_proc.Options + [poUsePipes, poNoConsole];
    // poNewConsole  é para terminais
    ref_proc.Execute;         // Execute o comando
    exitCode := ref_proc.ExitCode;
    exitStatus := ref_proc.ExitStatus;
    while (ref_proc.Running) or (ref_proc.Output.NumBytesAvailable > 0) do
    begin
      if (ref_proc.Output.NumBytesAvailable > 0) then
        // while (ref_proc.Output.NumBytesAvailable > 0 ) do
      begin
        ReadCount := Min(512, ref_proc.Output.NumBytesAvailable);
        //Read up to buffer, not more
        ref_proc.Output.Read(CharBuffer, ReadCount);
        strTemp := Copy(CharBuffer, 0, ReadCount);
        //strTemp:= StrTemp.Replace(sLineBreak);
        Write(strTemp);
        Sleep(2);
        Self.Synchronize(@Self.Sincronize);
        // sincroniza com a thread principal o estado de memo
        // Memo1.Lines.Add(strTemp);
        // progressbar1.Smooth:=true;

      end;
    end;
    if (ref_proc.Running = False) then        //verifica se o processo acabou
      {e inicia os procedimentos para encerrar  a thread }
    begin
      ref_proc.Free;
      // StrTemp:='fim de execução';
      // OnTerminate:=Self.Synchronize(@Self.Sincronize);
      StrTemp := '----------------------------------------------------' +
        sLineBreak + ' ... ... ... ... ... Fim da execução ... ... ... ... ... ' +
        sLineBreak + '---------------------------------------------------';
      Self.Synchronize(@Self.SinFim);
      //sincroniza  a msg de fim de execução com a thread principal
      //Sleep(1000);
      //owMessage('Feito!');

      flag_stop := False;
      Self.Synchronize(@ref_outproc.Lines.Clear);  //sincroniza a limpeza do tmemo
      Sleep(1000);     //dorme 1 segundo para o usuário perceber que o progressbar1 parou
      FInstall.Close;
      exit;
    end;
  end;
end;


constructor GUIThread.Create(mymemo: tmemo; cargs: TStringList; loadbar: TProgressBar);
begin
  inherited Create(True);
  Self.FreeOnTerminate := True;
  self.ref_outproc := mymemo;
  self.args := cargs;
  self.StrTemp := '';
  self.ref_progressbar := loadbar;
  ref_proc := TProcess.Create(nil);
end;

  {
  Procedimento da thread sincronizada com thread principal para  atualizar o tipo de progress bar
  e atualizar o tmemo
  }
procedure GUIThread.Sincronize();
begin
  //if (self.ref_progressbar.Visible = False) then
 //   self.ref_progressbar.Visible := True;
  //if (self.ref_progressbar.Style = pbstNormal) then
  //self.ref_progressbar.Style := pbstMarquee;

  Self.ref_outproc.Lines.Add(self.StrTemp);
end;

{
Essa função faz a sincronização final, escreve a última linha no tmemo e muda o tipo de progress bar
}
procedure GUIThread.SinFim();
begin
  ref_outproc.Lines.Add(StrTemp);
  //if (self.ref_progressbar.Style = pbstMarquee) then
    //self.ref_progressbar.Style := pbstNormal;
  Sleep(1000);
end;
{ TFmain }

procedure TFmain.Image1Click(Sender: TObject);
begin
      self.cmd_args := TStringList.Create;
      self.cmd_args.add(uglobal.LAMW_MAIN_SCRIPT);
      if (uglobal.CLEAN_INSTALL_FLAG = true)
      then
         self.cmd_args.add('reinstall')
      else
         self.cmd_args.add('install');
      if (  uglobal.USE_PROXY ) then
         self.cmd_args.Add('--use_proxy');
      self.proc := RunnableScripts.Create(cmd_args);
      self.proc.RunProcessAsConsole();
      self.proc.Free;
      self.cmd_args.Free;

end;

procedure TFmain.FormCreate(Sender: TObject);
begin
     image3.Width:=2205;
     image3.Height:=1654;
     self.count_img:= 0;
end;

procedure TFmain.CheckBox1Change(Sender: TObject);
begin
       if (self.CheckBox1.Checked)
       then
           uglobal.CLEAN_INSTALL_FLAG:= true
       else
          uglobal.CLEAN_INSTALL_FLAG:=false;
end;

procedure TFmain.Button1Click(Sender: TObject);
var aux: TImage;
  rect : TRect;
begin
   if  ( self.count_img = imagelist1.Count ) then
       self.count_img:= 0;
   aux := TImage.Create(nil);
    imagelist1.GetBitmap(self.count_img,image3.Picture.Bitmap);
    //image3.Proportional:=true;
    //aux.canvas.Draw(661,496,image3.Picture.Bitmap);

    //image3.Picture.Bitmap.SetSize(661,496);
    //image3.Stretch:=true;
    rect.Bottom:=50;
    rect.top:=50 ;
    rect.Right:=10;
    rect.Left:=10;
    aux.Canvas.StretchDraw(rect,image3.Picture.Bitmap);
    Self.count_img:=  Self.count_img +1;
    aux.Destroy;
end;



procedure TFmain.Image2Click(Sender: TObject);
begin
  self.cmd_args := TStringList.Create;
  self.cmd_args.add(uglobal.LAMW_MAIN_SCRIPT);
  self.cmd_args.add('update-lamw');
  if (  uglobal.USE_PROXY ) then
         self.cmd_args.Add('--use_proxy');
  //ShowMessage(self.cmd_args.GetText);
  self.proc := RunnableScripts.Create(cmd_args);
  self.proc.RunProcessAsConsole();
  self.proc.Free;
  self.cmd_args.Free;

end;

procedure TFmain.Image3Click(Sender: TObject);
var
  i : integer;
begin
  i:=0;
  //while ( i < imagelist1.Count ) do
  //begin


  //end;



end;

procedure TFmain.Image4Click(Sender: TObject);
begin

end;

procedure TFmain.Label1Click(Sender: TObject);
begin

end;

procedure TFmain.Label4Click(Sender: TObject);
begin

end;

procedure TFmain.Label5Click(Sender: TObject);
begin

end;

procedure TFmain.Label7Click(Sender: TObject);
begin

end;

procedure TFmain.MenuItem12Click(Sender: TObject);
begin

end;

procedure TFmain.MenuItem1Click(Sender: TObject);
begin

end;

procedure TFmain.MenuItem4Click(Sender: TObject);
begin

end;

procedure TFmain.MenuItem8Click(Sender: TObject);
begin

end;

procedure TFmain.MenuItem9Click(Sender: TObject);
begin
  if ( FormProxy.ShowModal = mrOK ) then
  begin
    //ShowMessage('ok');
    if( FormProxy.CheckBox3.Checked ) then
        Self.MenuItem9.Checked:= true
    else
        Self.MenuItem9.Checked:= False;

  end;

end;

procedure TFmain.Panel1Click(Sender: TObject);
begin

end;

procedure TFmain.ToggleBox1Change(Sender: TObject);
begin

end;

end.

