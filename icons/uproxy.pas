unit uproxy;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, UTF8Process, Forms, Controls, Graphics, Dialogs,
  StdCtrls, Buttons, uglobal, process;

type

  { TFormProxy }

  TFormProxy = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    CheckBox3: TCheckBox;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Edit4: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    procedure Button2Click(Sender: TObject);
    procedure CheckBox1Change(Sender: TObject);
    procedure CheckBox2Change(Sender: TObject);
    procedure Edit1Change(Sender: TObject);
    procedure Edit3Change(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure Label2Click(Sender: TObject);
    procedure CheckBox3Change(Sender: TObject);

  private
    ref_anterior: TForm;

  public
    procedure setFrameAnterior( ref : Tform);

  end;

var
  FormProxy: TFormProxy;

implementation

{$R *.lfm}

{ TFormProxy }

procedure TFormProxy.CheckBox1Change(Sender: TObject);
begin
  if (self.CheckBox1.Checked) then
    ShowMessage('Transparent Proxy not supported')
end;

procedure TFormProxy.Button2Click(Sender: TObject);
begin

end;

procedure TFormProxy.CheckBox2Change(Sender: TObject);
begin
  if ( Self.CheckBox2.Checked ) then
  begin
     uglobal.AUTENTICATION_PROXY_FLAG:= true;
     self.Edit3.ReadOnly:= false;
     self.Edit4.ReadOnly:= false;
  end
  else
  begin
    uglobal.AUTENTICATION_PROXY_FLAG:= false;
    self.Edit3.ReadOnly:= true;
     self.Edit4.ReadOnly:= true;
  end;
end;
procedure TFormProxy.CheckBox3Change(Sender: TObject);
begin
  if (CheckBox3.Checked )then
      //self.cmd_args.add('--use_proxy');
      uglobal.USE_PROXY:= true
  else
     uglobal.USE_PROXY:=false;

end;

procedure TFormProxy.Edit1Change(Sender: TObject);
begin

end;

procedure TFormProxy.Edit3Change(Sender: TObject);
begin
end;

procedure TFormProxy.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin

end;

procedure TFormProxy.FormCreate(Sender: TObject);
begin

end;

procedure TFormProxy.Label2Click(Sender: TObject);
begin

end;

procedure TFormProxy.setFrameAnterior(ref: Tform);
begin
  if  ( ref <> nil ) then
  begin
     self.ref_anterior := ref;
     self.ref_anterior.Visible:=false;
  end;
end;

end.

