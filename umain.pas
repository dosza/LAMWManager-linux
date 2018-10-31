unit umain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls,uprocessos,uglobal;

type

  { TFmain }

  TFmain = class(TForm)
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    Image1: TImage;
    Image2: TImage;
    Image3: TImage;
    Image4: TImage;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label7: TLabel;
    procedure CheckBox1Change(Sender: TObject);
    procedure CheckBox2Change(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Image1Click(Sender: TObject);
    procedure Image2Click(Sender: TObject);
    procedure Image3Click(Sender: TObject);
    procedure Image4Click(Sender: TObject);
    procedure Label1Click(Sender: TObject);
    procedure Label4Click(Sender: TObject);
    procedure Label5Click(Sender: TObject);
    procedure Label7Click(Sender: TObject);
  private
    cmd_args : TstringList;
    proc : RunnableScripts;
  public

  end;

var
  Fmain: TFmain;

implementation

{$R *.lfm}

{ TFmain }

procedure TFmain.Image1Click(Sender: TObject);
begin
      self.cmd_args := TStringList.Create;
      self.cmd_args.add(uglobal.LAMW_MAIN_SCRIPT);
      if (uglobal.CLEAN_INSTALL_FLAG = true)
      then
         self.cmd_args.add('clean-install')
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

end;

procedure TFmain.CheckBox1Change(Sender: TObject);
begin
       if (self.CheckBox1.Checked)
       then
           uglobal.CLEAN_INSTALL_FLAG:= true
       else
          uglobal.CLEAN_INSTALL_FLAG:=false;
end;

procedure TFmain.CheckBox2Change(Sender: TObject);
begin
  if (CheckBox2.Checked )then
      //self.cmd_args.add('--use_proxy');
      uglobal.USE_PROXY:= true
  else
     uglobal.USE_PROXY:=false;

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
begin

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

end.

