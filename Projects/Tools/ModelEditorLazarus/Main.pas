unit Main;

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, OpenGLContext, GUI, Shaders, FontManager, Color,
  SkyDome, ControlledCamera;

type

  { TfrmMain }

  TfrmMain = class(TGLForm)
  private
    // Shader
    FGUIShader: TShader;
    FSkyDomeShader: TShader;

    // Font
    FFont: TBMPFontItem;

    // GUI
    FGUI: TGUI;

    // SkyDome
    FSkyDome: TSkyDome;

    // Camera
    FCamera: TSmoothControlledCamera;

  public
    procedure Init; override;
    procedure Finalize; override;

    procedure ResizeFunc; override;

    procedure RenderFunc; override;
    procedure UpdateFunc; override;
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.Init;
begin
  FGUIShader := TShader.Create;
  FGUIShader.VertexFragmentShaderFromResource('GUI_SHADER');
  FGUIShader.AddAttribute(3, 'vpos');
  FGUIShader.AddAttribute(2, 'vtexcoord');
  FGUIShader.AddAttribute(4, 'vcolor');
  FGUIShader.AddAttribute(2, 'vborderlow');
  FGUIShader.AddAttribute(2, 'vborderhigh');

  FSkyDomeShader := TShader.Create;
  FSkyDomeShader.VertexFragmentShaderFromResource('SKYDOME_SHADER');
  FSkyDomeShader.AddAttribute(3, 'vpos');
  FSkyDomeShader.AddAttribute(1, 'vpitch');

  //FCamera := TSmoothControlledCamera.Create(60, Aspect, 0.1, 100, Self);

  //FSkyDome := TSkyDome.Create(Self, FCamera, FSkyDomeShader);

  FFont := TBMPFontItem.Create;
  FFont.LoadFromPNGResource('FONT');

  FGUI := TGUI.Create(FGUIShader, Self, FFont);
  FGUI.AddTextureFromResource('STONE_BUTTON', 'button');

  with TGLButton.Create(FGUI) do
  begin
    Height := 0.2;
    Caption := 'Hi';
  end;
end;

procedure TfrmMain.Finalize;
begin
  FGUI.Free;
  FGUIShader.Free;
  FSkyDomeShader.Free;
  FFont.Free;
end;

procedure TfrmMain.ResizeFunc;
begin
  FGUI.Aspect := Aspect;
end;

procedure TfrmMain.RenderFunc;
begin
  FGUI.Render;
end;

procedure TfrmMain.UpdateFunc;
begin
  if MustUpdateFPS then
    Caption := Format('ModelEditor - FPS: %d', [FPSInt]);

  FGUI.Update;
end;

end.

