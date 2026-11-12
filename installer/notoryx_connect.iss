; Inno Setup script for the NOTORYX Connect Windows installer.
; Built by .github/workflows/windows-build.yml with
;   ISCC /DAppVersion=1.0.0-13 /DSourceDir=<flutter Release folder> /DOutputDir=<dist>

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif
#ifndef SourceDir
  #define SourceDir "..\build\windows\x64\runner\Release"
#endif
#ifndef OutputDir
  #define OutputDir "..\dist"
#endif

[Setup]
; Keep this AppId forever: Windows uses it to upgrade and uninstall.
AppId={{dcbc6967-37e9-406a-a023-bfa6f7366999}
AppName=NOTORYX Connect
AppVersion={#AppVersion}
AppPublisher=NOTORYX
AppComments=Independent app for LoRa mesh radios running Meshtastic firmware. Not affiliated with Meshtastic LLC.
DefaultDirName={autopf}\NOTORYX Connect
DefaultGroupName=NOTORYX Connect
DisableProgramGroupPage=yes
; Installs for the current user without admin rights; the dialog offers all users.
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
LicenseFile=..\LICENSE
OutputDir={#OutputDir}
OutputBaseFilename=NOTORYX-Connect-{#AppVersion}-Windows-x64-setup
UninstallDisplayIcon={app}\notoryx_connect.exe
UninstallDisplayName=NOTORYX Connect
Compression=lzma2
SolidCompression=yes
WizardStyle=modern

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\NOTORYX Connect"; Filename: "{app}\notoryx_connect.exe"
Name: "{autodesktop}\NOTORYX Connect"; Filename: "{app}\notoryx_connect.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\notoryx_connect.exe"; Description: "{cm:LaunchProgram,NOTORYX Connect}"; Flags: nowait postinstall skipifsilent
