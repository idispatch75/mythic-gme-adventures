; Script generated by the Inno Setup Script Wizard.
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

#define MyAppName "Mythic GME Adventures"
#define MyAppPublisher "IDispatch"
#define MyAppURL "https://idispatch75.github.io/mythic-gme-adventures/"
#define MyAppExeName "Mythic_GME_Adventures.exe"
#define MyAppVersion GetVersionNumbersString(AddBackslash(SourcePath) + "..\build\windows\x64\runner\Release\" + MyAppExeName)
#define MyOutputBaseFileName "Setup_" + StringChange(MyAppName, " ", "_") + "-" + MyAppVersion
#define MyOutputDir "..\build\windows"
#define MyBuildDir MyOutputDir + "\x64\runner\Release"

#include "CodeDependencies.iss"

[Setup]
AppId={{38BD51FC-CC02-4ABB-A9EB-162F5B60F3BC}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DisableProgramGroupPage=yes
PrivilegesRequiredOverridesAllowed=dialog
OutputDir={#MyOutputDir}
OutputBaseFilename={#MyOutputBaseFileName}
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "{#MyBuildDir}\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#MyBuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Code]
function InitializeSetup: Boolean;
begin
  Dependency_AddVC2015To2022;

  Result := True;
end;

