unit uglobal;

{$mode objfpc}{$H+}

interface

uses
          Classes, SysUtils,IniFiles;
//  ;

var
 // LAMW_SETTINGS: TIniFile;
  //LAMW_MANAGER : TINIPROPE

  // FILE CONFIGURATION NAME
  LAMW_SETTINGS_PATH: String = 'lamw4linuxconfi.ini';
  LAMW_SETTINGS_SECTION : String = 'LAMWManagerSettings';

  // LAMW MANAGER DATA
  BRIDGE_ROOT : string = 'bridge-root.sh';
  LAMW_MAIN_SCRIPT : string = 'lamw-manager';
  LAMW_PACKAGE_SCRIPT:string = 'lamw-package';
  CLEAN_INSTALL_FLAG : boolean = false;
  INSTALL_STATE : boolean = False;
  USE_OLD_SDK : boolean = false;

  // PROXY SETTINGS
  PROXY_SERVER : string  = '';
  PORT_SERVER : integer = 3128;
  USE_AUTH_PROXY : boolean = false;
  PASSWORD_PROXY : string ='';

  //PROXY FLAGS
  USE_PROXY : boolean = false;
  TRANSPARENT_PROXY_FLAG : boolean  = false;
  ALTERNATIVE_PROXY_SET_FLAG : boolean = false;
  AUTENTICATION_PROXY_FLAG : boolean = false;





implementation
  {procedure initLAMWSettings;
  var
  aux : TStringList;
  begin

              if ( FileExists(GetCurrentDir + '/'  + LAMW_SETTINGS_PATH) ) then
              begin   //carregar configurações
                      writeln('exists');
                      aux := TStringList.Create;
                      LAMW_SETTINGS :=TIniFile.Create(GetCurrentDir + '/'  + LAMW_SETTINGS_PATH);
//                      LAMW_SETTINGS.FileName();
                      LAMW_SETTINGS.ReadSection(LAMW_SETTINGS_SECTION,aux);
                      writeln(aux.ToString());

              end
              else begin
                writeln('not exists');

              end;
  end;
  }
End.
