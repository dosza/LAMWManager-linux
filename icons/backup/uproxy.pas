unit uproxy;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    CheckBox1: TCheckBox;
    Edit1: TEdit;
    Edit2: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    procedure CheckBox1Change(Sender: TObject);
    procedure Edit1Change(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Label2Click(Sender: TObject);
  private
    ref_anterior: TForm;

  public
    procedure setFrameAnterior( ref : Tform);

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.CheckBox1Change(Sender: TObject);
begin

end;

procedure TForm1.Edit1Change(Sender: TObject);
begin

end;

procedure TForm1.FormCreate(Sender: TObject);
begin

end;

procedure TForm1.Label2Click(Sender: TObject);
begin

end;

procedure TForm1.setFrameAnterior(ref: Tform);
begin
  if  ( ref <> nil ) then
  begin
     self.ref_anterior := ref;
     self.ref_anterior.Visible:=false;
  end;
end;

end.

