unit Particles;

interface

uses
  Classes, SysUtils, Lists, TextureManager, VAOManager, Shaders, GLEnums, VectorGeometry, Color, Camera, OpenGLContext;

type

  TParticleMode = (
    pmBinaryAlpha,
    pmRealAlpha,
    pmAdditive
  );

  { TBasicParticle }

  TBasicParticle = class abstract
  private
    type

      { TData }

      TData = record
        Pos: TGVector3;
        Rotation: Single;
        Offset: TGVector2;
        Color: TColorRGBA;
        Texcoord: TTexCoord2;
      end;

  protected
    FPos: TGVector3;
    FRotation: Single;
    FSize: TGVector2;
    FColor: TColorRGBA;
    FTexture: PChar;

    FRemoveFlag: Boolean;

    FCamDistance: Single;
    FCamLine: PGLine;

  public
    constructor Create(APos: TGVector3; ARotation: Single; ASize: TGVector2; AColor: TColorRGBA; ATexture: PChar);

    class function CompareDistance(A, B: TObject): Boolean; static;

    class function GetMode: TParticleMode; virtual; abstract;

    procedure SetCamLine(const ACamLine: TGLine);
    procedure Update(ADeltaTime: Single); virtual;

    procedure AddToVAO(FVAO: TVAO; FTexturePage: TTexturePage);

    property Pos: TGVector3 read FPos;
    property Rotation: Single read FRotation;
    property Color: TColorRGBA read FColor;
    property Size: TGVector2 read FSize;
    property Texture: PChar read FTexture;

    property RemoveFlag: Boolean read FRemoveFlag;
    procedure Remove;
  end;

  TParticleSystem = class;

  { TBasicParticleGen }

  TBasicParticleGen = class abstract
  private
    FParticleSystem: TParticleSystem;
  public
    procedure Update(ADeltaTime: Single); virtual; abstract;
    procedure AddParticle(AParticle: TBasicParticle);
  end;

  { TParticleSystem }
  // Render this as far back as possible
  TParticleSystem = class
  private
    FVAOs: array [TParticleMode] of TVAO;
    FCamera: TCamera;
    FOpenGL: TOpenGLContext;

    FTexturePage: TTexturePage;

    FParticles: array [TParticleMode] of TObjectList;
    FParticleGenerators: TObjectList;

    function GetParticleCount: Cardinal;

    procedure BuildVAOs;
  public
    constructor Create(AShader: TShader; ACamera: TCamera; AOpenGL: TOpenGLContext);
    destructor Destroy; override;

    procedure AddParticle(AParticle: TBasicParticle);
    procedure AddGenerator(AParticleGen: TBasicParticleGen);
    procedure AddTextureFromFile(AFileName: String; AName: String = '');
    procedure AddTextureFromResource(AResourceName: String; AName: String = '');
    procedure BuildTexturePage(ASegmentResolution: Cardinal);

    procedure Update(ADeltaTime: Single);

    property ParticleCount: Cardinal read GetParticleCount;

    procedure Render;
  end;

implementation

{ TBasicParticleGen }

procedure TBasicParticleGen.AddParticle(AParticle: TBasicParticle);
begin
  FParticleSystem.AddParticle(AParticle);
end;

{ TBasicParticle }

constructor TBasicParticle.Create(APos: TGVector3; ARotation: Single; ASize: TGVector2; AColor: TColorRGBA;
  ATexture: PChar);
begin
  FPos := APos;
  FRotation := ARotation;
  FSize := ASize;
  FColor := AColor;
  FTexture := ATexture;
end;

class function TBasicParticle.CompareDistance(A, B: TObject): Boolean;
begin
  Result := TBasicParticle(A).FCamDistance < TBasicParticle(B).FCamDistance;
end;

procedure TBasicParticle.SetCamLine(const ACamLine: TGLine);
begin
  FCamLine := @ACamLine;
end;

procedure TBasicParticle.Update(ADeltaTime: Single);
begin
  if FCamLine <> nil then
    FCamDistance := FCamLine.OrthoProjDistance(Pos);
end;

procedure TBasicParticle.AddToVAO(FVAO: TVAO; FTexturePage: TTexturePage);
var
  Data: TData;
  S: TQuadSide;
begin
  Data.Pos := Pos;
  Data.Color := Color;
  Data.Rotation := Rotation / 180 * Pi;
  for S := Low(TQuadSide) to High(TQuadSide) do
  begin
    Data.Offset := QuadMiddleCoords[S] * Size / 2;
    Data.Texcoord := FTexturePage.GetTexCoord(Texture, QuadTexCoords[S]);
    FVAO.AddVertex(Data);
  end
end;

procedure TBasicParticle.Remove;
begin
  FRemoveFlag := True;
end;

{ TParticleSystem }

constructor TParticleSystem.Create(AShader: TShader; ACamera: TCamera; AOpenGL: TOpenGLContext);
var
  M: TParticleMode;
begin
  for M := Low(TParticleMode) to High(TParticleMode) do
  begin
    FVAOs[M] := TVAO.Create(AShader);
    FParticles[M] := TObjectList.Create;
  end;
  FCamera := ACamera;

  FTexturePage := TTexturePage.Create;
  FTexturePage.Uniform(AShader, 'tex');
  FParticleGenerators := TObjectList.Create;

  FOpenGL := AOpenGL;
end;

destructor TParticleSystem.Destroy;
var
  M: TParticleMode;
begin
  FTexturePage.Free;
  for M := Low(TParticleMode) to High(TParticleMode) do
  begin
    FVAOs[M].Free;
    FParticles[M].Free;
  end;
  FParticleGenerators.Free;
  inherited Destroy;
end;

procedure TParticleSystem.AddParticle(AParticle: TBasicParticle);
begin
  FParticles[AParticle.GetMode].Add(AParticle);
end;

procedure TParticleSystem.AddGenerator(AParticleGen: TBasicParticleGen);
begin
  FParticleGenerators.Add(AParticleGen);
  AParticleGen.FParticleSystem := Self;
end;

procedure TParticleSystem.AddTextureFromFile(AFileName, AName: String);
begin
  if AName = '' then
    FTexturePage.AddTexture(AFileName)
  else
    FTexturePage.AddTexture(AFileName, AName);
end;

procedure TParticleSystem.AddTextureFromResource(AResourceName, AName: String);
begin
  if AName = '' then
    FTexturePage.AddTextureFromResource(AResourceName)
  else
    FTexturePage.AddTextureFromResource(AResourceName, AName);
end;

procedure TParticleSystem.BuildTexturePage(ASegmentResolution: Cardinal);
begin
  FTexturePage.BuildPage(ASegmentResolution);
end;

procedure TParticleSystem.Update(ADeltaTime: Single);
var
  ParticleGen: TBasicParticleGen;
  CamLine: TGLine;
  M: TParticleMode;
begin
  for TObject(ParticleGen) in FParticleGenerators do
    ParticleGen.Update(ADeltaTime);

  CamLine := FCamera.GetCursorLine(Origin);

  for M := Low(TParticleMode) to High(TParticleMode) do
    with FParticles[M].GetEnumerator(True) do while MoveNext do
    begin
      if TBasicParticle(Current).GetMode = pmRealAlpha then
        TBasicParticle(Current).SetCamLine(CamLine);
      TBasicParticle(Current).Update(ADeltaTime);
      if TBasicParticle(Current).RemoveFlag then
        RemoveCurrent;
    end;

  FParticles[pmRealAlpha].Sort(TBasicParticle.CompareDistance);
end;

procedure TParticleSystem.Render;
begin
  BuildVAOs;

  FCamera.ResetModelLocation;
  FCamera.Render;

  FVAOs[pmBinaryAlpha].Render;

  FOpenGL.Push;

  FOpenGL.State.BlendFactorSrc := bfsSrcAlpha;
  FOpenGL.State.BlendFactorDest := bfdOne;
  FOpenGL.State.DepthTest := False;
  FVAOs[pmAdditive].Render;

  FOpenGL.Pop;

  FOpenGL.Push;

  FOpenGL.State.DepthMask := False;
  FVAOs[pmRealAlpha].Render;

  FOpenGL.Pop;
end;

function TParticleSystem.GetParticleCount: Cardinal;
var
  M: TParticleMode;
begin
  Result := 0;
  for M := Low(TParticleMode) to High(TParticleMode) do
    Result := Result + FParticles[M].Count;
end;

procedure TParticleSystem.BuildVAOs;
var
  Particle: TBasicParticle;
  M: TParticleMode;
begin
  for M := Low(TParticleMode) to High(TParticleMode) do
  begin
    FVAOs[M].Generate(FParticles[M].Count * 6, buStreamDraw);
    FVAOs[M].Map(baWriteOnly);
    for TObject(Particle) in FParticles[M] do
      Particle.AddToVAO(FVAOs[M], FTexturePage);
    FVAOs[M].Unmap;
  end;
end;

end.

