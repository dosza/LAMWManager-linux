unit umain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, SynHighlighterIni, Forms, Controls, Graphics,
  Dialogs, ExtCtrls, StdCtrls, Menus, IniPropStorage, uprocessos, uglobal,
  uproxy, Process, XMLConf, Math;



  { TFmain }

  type TFmain = class(TForm)
    Button1: TButton;
    CheckBox1: TCheckBox;
    Image1: TImage;
    Image2: TImage;
    Image3: TImage;
    LAMWManagerSettings: TIniPropStorage;
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
    UGLOBAL_SETTINGS: TSynIniSyn;
    procedure Button1Click(Sender: TObject);
    procedure CheckBox1Change(Sender: TObject);
   // procedure CheckBox2Change(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Image1Click(Sender: TObject);
    procedure Image1DblClick(Sender: TObject);
    procedure Image2Click(Sender: TObject);
    procedure Image3Click(Sender: TObject);
    procedure Image4Click(Sender: TObject);
    procedure LAMWManagerSettingsRestoreProperties(Sender: TObject);
    procedure Label1Click(Sender: TObject);
    procedure Label4Click(Sender: TObject);
    procedure Label5Click(Sender: TObject);
    procedure Label7Click(Sender: TObject);
    procedure MenuItem10Click(Sender: TObject);
    procedure MenuItem11Click(Sender: TObject);
    procedure MenuItem12Click(Sender: TObject);
  //  procedure MenuItem13Click(Sender: TObject);
    procedure MenuItem1Click(Sender: TObject);
    procedure MenuItem2Click(Sender: TObject);
    procedure MenuItem4Click(Sender: TObject);
    procedure MenuItem6Click(Sender: TObject);
    procedure MenuItem7Click(Sender: TObject);
    procedure MenuItem8Click(Sender: TObject);
    procedure MenuItem9Click(Sender: TObject);
    procedure Panel1Click(Sender: TObject);
    procedure Panel2Click(Sender: TObject);
    procedure ToggleBox1Change(Sender: TObject);
  private
    cmd_args : TstringList;
    proc : RunnableScripts;
    count_img: integer;
    max_images: integer;
    current_image_index:integer;
   // MeuProcesso : GUIThread;
  public
    procedure showLAMWtutorial;
  end;


var
  //flag_stop: boolean = True;
  Fmain: TFmain;
  mthread : TThread;
  //global_memo : TMemo;

//  mthread: GUIThread;

implementation

{$R *.lfm}

{GUIThead class}

{ TFmain }

procedure TFmain.Image1Click(Sender: TObject);
var str_action : string ='';
begin
     // parsing ...
      self.cmd_args := TStringList.Create;
      self.cmd_args.Add(uglobal.LAMW_MAIN_SCRIPT);
     if ( uglobal.CLEAN_INSTALL_FLAG ) then
     begin
//           WriteLn('');
           str_action:='--reset';
     end
     else begin
            //WriteLn('');
            str_action := '';
     end;


     self.cmd_args.Add(str_action);
     if ( uglobal.USE_PROXY) then
        self.cmd_args.Add('--use-proxy');

      self.proc := RunnableScripts.Create(cmd_args);
      self.proc.RunProcessAsConsole();
      self.proc.Free;
      self.cmd_args.Free;


end;

procedure TFmain.Image1DblClick(Sender: TObject);
begin

end;

procedure TFmain.FormCreate(Sender: TObject);
begin
     image3.Width:=2205;
     image3.Height:=1654;
     self.count_img:= 0;
     image3.Picture.Jpeg.LoadFromFile(GetCurrentDir+'/images/UserGuide-gmp/UserGuideSample-up-01-gmp.jpg');
     self.max_images:= 32;
     self.current_image_index:=1;
     cmd_args:= TStringList.Create();
     cmd_args.Add(uglobal.LAMW_PACKAGE_SCRIPT);
     self.proc:=RunnableScripts.Create(cmd_args);
     self.proc.RunProcess();
     //Self.MenuItem13.Checked := True;
     if (proc.getExitStatus() = 0 ) then
        self.MenuItem7.Caption:='Uninstall'
     else self.MenuItem7.Caption:='Install';

    // showMessage(Integer.ToString(proc.getExitStatus()));
     self.proc.Free;
     self.cmd_args.Free;
    //uglobal.initLAMWSettings;


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
   //if  ( self.count_img = imagelist1.Count ) then
     //  self.count_img:= 0;
   //aux := TImage.Create(nil);
    //imagelist1.GetBitmap(self.count_img,image3.Picture.Bitmap);
    //image3.Proportional:=true;
    //aux.canvas.Draw(661,496,image3.Picture.Bitmap);

    //image3.Picture.Bitmap.SetSize(661,496);
    //image3.Stretch:=true;
end;



procedure TFmain.Image2Click(Sender: TObject);
begin
 WriteLn('Cliquei no botão de atualizar');
 // ShowMessage('Cliquei no botão de atualizar');
  self.cmd_args := TStringList.Create;
  self.cmd_args.add(uglobal.LAMW_MAIN_SCRIPT);
  self.cmd_args.add('--update-lamw');
  //mthread := TThread.Create(True);
  //mthread.ExecuteInThread(fmain.showLAMWtutorial);
  //TThreadExecuteCallBack(Self.showLAMWtutorial);



  //ShowMessage(self.cmd_args.GetText);
  self.proc := RunnableScripts.Create(cmd_args);
  self.proc.RunProcessAsConsole();
  self.proc.Free;
  self.cmd_args.Free;


end;

procedure TFmain.Image3Click(Sender: TObject);
var
  i : integer;
  //max_images : integer = 30;
  aux : string ;
  filename: string = 'UserGuideSample-up-';
begin
  writeln('current_index=',current_image_index);
 if ( current_image_index < max_images  ) then
    begin
           if ( current_image_index <  max_images ) then
           begin
                 if ( current_image_index < 10) then
                    aux := filename + '0' + Integer.ToString(current_image_index) +  '-gmp.jpg'
                 else
                  aux := filename + Integer.ToString(current_image_index) +  '-gmp.jpg';

                current_image_index:= current_image_index + 1;
                 //current
           end;

           //ShowMessage(GetCurrentDir);
        writeln(aux);
        image3.Picture.Jpeg.LoadFromFile(GetCurrentDir+'/images/UserGuide-gmp/'+ aux);
          // Sleep(5000);
    end
 else
        current_image_index:= 1;



end;

procedure TFmain.Image4Click(Sender: TObject);
begin

end;

procedure TFmain.LAMWManagerSettingsRestoreProperties(Sender: TObject);
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

procedure TFmain.MenuItem10Click(Sender: TObject);
begin

end;

procedure TFmain.MenuItem11Click(Sender: TObject);
begin
        ShowMessage('This feature is still in development');
end;


procedure TFmain.MenuItem12Click(Sender: TObject);
begin
        showMessage(uglobal.LAMW_MGR_VERSION);
end;
{
procedure TFmain.MenuItem13Click(Sender: TObject);
begin
        Self.MenuItem13.Checked := True;
        uglobal.USE_OLD_SDK:= self.MenuItem13.Checked;
        if (uglobal.USE_OLD_SDK = true) then
           ShowMessage('Android SDK Tools with  always Support Apache Ant® and Gradle!')
        else
            ShowMessage('You have chosen to install Android SDK Tools for Gradle only') ;

end;
      }
procedure TFmain.MenuItem1Click(Sender: TObject);
begin

end;

procedure TFmain.MenuItem2Click(Sender: TObject);
begin

end;

procedure TFmain.MenuItem4Click(Sender: TObject);
begin
        //just update-lamw
  self.cmd_args := TStringList.Create;
  self.cmd_args.add(uglobal.LAMW_MAIN_SCRIPT);
  self.cmd_args.add('--update-lamw');
  //mthread := TThread.Create(True);
  //mthread.ExecuteInThread(fmain.showLAMWtutorial);
  //TThreadExecuteCallBack(Self.showLAMWtutorial);



  //ShowMessage(self.cmd_args.GetText);
  self.proc := RunnableScripts.Create(cmd_args);
  self.proc.RunProcessAsConsole();
  self.proc.Free;
  self.cmd_args.Free;
end;

procedure TFmain.MenuItem6Click(Sender: TObject);
var str_action: string;
begin    //clean and install
         self.cmd_args := TStringList.Create;
         //self.CheckBox1.Checked=true;
         uglobal.CLEAN_INSTALL_FLAG:=true;
      self.cmd_args.Add(uglobal.LAMW_MAIN_SCRIPT);
     if ( uglobal.CLEAN_INSTALL_FLAG ) then
     begin
//           WriteLn('');
           str_action:='--reset';
     end
     else begin
            //WriteLn('');
            str_action := '';
     end;


     self.cmd_args.Add(str_action);
     if ( uglobal.USE_PROXY) then
        self.cmd_args.Add('--use-proxy');

      self.proc := RunnableScripts.Create(cmd_args);
      self.proc.RunProcessAsConsole();
      self.proc.Free;
      self.cmd_args.Free;

end;

procedure TFmain.MenuItem7Click(Sender: TObject);
var str_action :string;
begin
     uglobal.CLEAN_INSTALL_FLAG:=false;
        self.cmd_args := TStringList.Create;
      self.cmd_args.Add(uglobal.LAMW_MAIN_SCRIPT);
     if ( uglobal.CLEAN_INSTALL_FLAG ) then
     begin
//           WriteLn('');
           str_action:='--reset';
     end
     else begin
            //WriteLn('');
            str_action := '';
     end;


     self.cmd_args.Add(str_action);
     if ( uglobal.USE_PROXY) then
        self.cmd_args.Add('--use-proxy');

      self.proc := RunnableScripts.Create(cmd_args);
      self.proc.RunProcessAsConsole();
      self.proc.Free;
      self.cmd_args.Free;
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

procedure TFmain.Panel2Click(Sender: TObject);
begin

end;

procedure TFmain.ToggleBox1Change(Sender: TObject);
begin

end;

procedure TFmain.showLAMWtutorial;
var
  i : integer;
  //max_images : integer = 30;
  aux : string ;
  filename: string = 'UserGuideSample-up-';
begin
  i:=1;
  while ( i < max_images ) do
  begin
         if ( i <  max_images ) then
         begin
               if ( i < 10) then
               aux := filename + '0' + Integer.ToString(i) +  '-gmp.jpg'
               else
                   aux := filename + Integer.ToString(i) +  '-gmp.jpg';
               i := i + 1;
         end
         else i:=0;
         //ShowMessage(GetCurrentDir);
         image3.Picture.Jpeg.LoadFromFile(GetCurrentDir+'/images/UserGuide-gmp/'+ aux);
  end;
end;

end.
