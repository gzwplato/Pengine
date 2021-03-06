unit ParticleManager;

interface

uses
  Classes, SysUtils, VectorGeometry, Camera, Shaders, VAOManager, GLEnums, Color, TextureManager, Sorting, Matrix,
  dglOpenGL;

type

  TParticleSystemMode = (
    psmNormal,
    psmAdditive
  );

  TObjectArray = array of TObject;

  EParticleSystemException = class (Exception)
  end;

  { EPSGeneratorNotFound }

  EPSGeneratorNotFound = class (EParticleSystemException)
    constructor Create;
  end;

  { EPSGeneratorOutOfRange }

  EPSGeneratorOutOfRange = class (EParticleSystemException)
    constructor Create(AIndex, AMax: Integer);
  end;

  TParticleAttributes = (
    paPosition, // the middle position of the particle
    paColor,    // the color you can blend the current texture or else
    paCorner,   // the 4 corners of the particle [-x,-x]-[+x,+x]
    paTexCoord  // the on particle coordinates ranging from 0-1
    // calculate Size with Camera Up and Right and TexCoord to get 3D location of edges
  );
  TParticleAttribNames = array [TParticleAttributes] of PChar;

  { TBasicParticle }

  TBasicParticle = class abstract
  private
    FMVPMatrix: TMatrix4;
    FDepth: Single;

    function GetDataStart: Pointer;
  protected
    FActive: Boolean;
  public
    // order important!
    FPosition: TGVector3;
    FColor: TColorRGBA;

    FSize: Single;

    procedure SetMVP(AMVPMatrix: TMatrix4);

    function GetTexCoord(T: TTexCoord): TTexCoord; virtual;
    function GetCorner(C: TTexCoord): TTexCoord; virtual;
    procedure Update(DeltaTime: Single); virtual; abstract;
    procedure UpdateDepth;

    procedure Generate;
    procedure Remove;

    property DataStart: Pointer read GetDataStart;
    property Active: Boolean read FActive;
  end;

  TParticleClass = class of TBasicParticle;

  { TParticleSorter }

  TParticleSorter = class (TQuickSorter)
  protected
    class function Compare(A, B: TObject): Boolean; override;
  end;

  { TBasicParticleGenerator }
  // Generates Particles
  TBasicParticleGenerator = class
  private
    FCamera: TCamera;
  protected
    FParticles: array of TBasicParticle;
    FMaxParticles: Integer;

    FNext: Integer;

    function Update(DeltaTime: Single): Integer; virtual;
  public
    constructor Create(AParticleType: TParticleClass; AMaxParticles: Integer);
    destructor Destroy; override;

    function Generate: TBasicParticle;

    procedure AddParticlesToArray(var Data: TObjectArray);

    property MaxParticles: Integer read FMaxParticles;

    procedure SetCamera(ACamera: TCamera);
  end;

  { TTexturedParticle }

  TTexturedParticle = class (TBasicParticle)
  protected
    FTexturePage: TTexturePage;
  public
    FTexID: Integer;

    procedure SetTexturePage(ATexturePage: TTexturePage);

    function GetTexCoord(T: TTexCoord): TTexCoord; override;
  end;

  { TTexturedParticleGenerator }

  TTexturedParticleGenerator = class (TBasicParticleGenerator)
  private
    //FTexturePage: TTexturePage;
  public
    procedure SetTexturePage(ATexturePage: TTexturePage);
    function Generate: TTexturedParticle;
  end;


  { TParticleSystem }
  // Handels muliple Particle Generators
  // Sort Order must be achieved across Generators
  TParticleSystem = class
  private
    FGenerators: array of TBasicParticleGenerator;
    FCamera: TCamera;
    FShader: TShader;
    FVAO: TVAO;

    FMode: TParticleSystemMode;

    FMaxSize: Integer;

    FParticleCount: Integer;

    procedure SetMaxSize(AValue: Integer);

    property MaxSize: Integer read FMaxSize write SetMaxSize;

    function GetGeneratorCount: Integer;
    procedure AddToVAO(AParticle: TBasicParticle);

    procedure InitVAO(AAttribNames: TParticleAttribNames);
  public
    constructor Create(ACamera: TCamera; AShader: TShader; AAttribNames: TParticleAttribNames;
      AMode: TParticleSystemMode);
    destructor Destroy; override;

    property GeneratorCount: Integer read GetGeneratorCount;

    procedure Update(DeltaTime: Single);
    procedure Render;

    procedure AddGenerator(AGenerator: TBasicParticleGenerator);
    procedure RemoveGenerator(AIndex: Integer); overload;
    procedure RemoveGenerator(AGenerator: TBasicParticleGenerator); overload;

    function GetGeneratorIndex(AGenerator: TBasicParticleGenerator): Integer;

    property ParticleCount: Integer read FParticleCount;
    property MaxParticles: Integer read FMaxSize;
  end;

  { TTexturedParticleSystem }

  TTexturedParticleSystem = class (TParticleSystem)
  private
    FTexturePage: TTexturePage;
  public
    constructor Create(ACamera: TCamera; AShader: TShader; AAttribNames: TParticleAttribNames; AMode: TParticleSystemMode;
      AUniformName: PAnsiChar);

    procedure AddGenerator(AGenerator: TTexturedParticleGenerator);
    procedure Render;

    procedure AddTexture(AFilename: String);
    procedure Generate(AGridSize: Integer);
  end;

implementation

{ TTexturedParticle }

procedure TTexturedParticle.SetTexturePage(ATexturePage: TTexturePage);
begin
  FTexturePage := ATexturePage;
end;

function TTexturedParticle.GetTexCoord(T: TTexCoord): TTexCoord;
begin
  Result := FTexturePage.GetTexCoord(FTexID, T);
end;

{ TTexturedParticleGenerator }

procedure TTexturedParticleGenerator.SetTexturePage(ATexturePage: TTexturePage);
var
  I: Integer;
begin
  //FTexturePage := ATexturePage;
  for I := 0 to FMaxParticles - 1 do
    TTexturedParticle(FParticles[I]).SetTexturePage(ATexturePage);
end;

function TTexturedParticleGenerator.Generate: TTexturedParticle;
begin
  Result := TTexturedParticle(inherited Generate);
end;

{ TTexturedParticleSystem }

constructor TTexturedParticleSystem.Create(ACamera: TCamera; AShader: TShader; AAttribNames: TParticleAttribNames;
  AMode: TParticleSystemMode; AUniformName: PAnsiChar);
begin
  inherited Create(ACamera, AShader, AAttribNames, AMode);
  FTexturePage := TTexturePage.Create(AShader.UniformLocation(AUniformName));
end;

procedure TTexturedParticleSystem.AddGenerator(AGenerator: TTexturedParticleGenerator);
begin
  inherited AddGenerator(AGenerator);
  AGenerator.SetTexturePage(FTexturePage);
end;

procedure TTexturedParticleSystem.Render;
begin
  FTexturePage.Bind;
  inherited Render;
end;

procedure TTexturedParticleSystem.AddTexture(AFilename: String);
begin
  FTexturePage.AddTexture(AFilename);
end;

procedure TTexturedParticleSystem.Generate(AGridSize: Integer);
begin
  FTexturePage.BuildPage(AGridSize);
  FTexturePage.Generate;
end;

{ TParticleSorter }

class function TParticleSorter.Compare(A, B: TObject): Boolean;
begin
  Result := TBasicParticle(A).FDepth < TBasicParticle(B).FDepth;
end;

{ EPSGeneratorOutOfRange }

constructor EPSGeneratorOutOfRange.Create(AIndex, AMax: Integer);
begin
  inherited Create(Format('Particle Generator Index %d is out of range. Max: ', [AIndex, AMax]));
end;

{ EPSGeneratorNotFound }

constructor EPSGeneratorNotFound.Create;
begin
  inherited Create('Particle Generator not found');
end;

{ TBasicParticle }

function TBasicParticle.GetDataStart: Pointer;
begin
  Result := @FPosition.X;
end;

procedure TBasicParticle.SetMVP(AMVPMatrix: TMatrix4);
begin
  FMVPMatrix := AMVPMatrix;
end;

procedure TBasicParticle.Generate;
begin
  FActive := True;
end;

function TBasicParticle.GetTexCoord(T: TTexCoord): TTexCoord;
begin
  Result := T;
end;

function TBasicParticle.GetCorner(C: TTexCoord): TTexCoord;
begin
  Result := FSize * C;
end;

procedure TBasicParticle.UpdateDepth;
begin
  FDepth := (FMVPMatrix.Transpose * FPosition.ToVec4).Z;
end;

procedure TBasicParticle.Remove;
begin
  FActive := False;
end;

{ TParticleSystem }

procedure TParticleSystem.SetMaxSize(AValue: Integer);
begin
  FMaxSize := AValue;
  FVAO.Generate(FMaxSize * 6, buDynamicDraw); // 6 vertices per "quad"
end;

function TParticleSystem.GetGeneratorCount: Integer;
begin
  Result := Length(FGenerators);
end;

procedure TParticleSystem.AddToVAO(AParticle: TBasicParticle);

  type
    TData = record
      PX, PY, PZ, R, G, B, A, DX, DY, S, T: Single;
    end;

const
  Corners: array [0 .. 5] of TTexCoord = (
    (S: -1; T: -1),
    (S: +1; T: -1),
    (S: +1; T: +1),
    (S: +1; T: +1),
    (S: -1; T: +1),
    (S: -1; T: -1)
  );

  TexCoord: array [0 .. 5] of TTexCoord = (
    (S: 0; T: 0),
    (S: 1; T: 0),
    (S: 1; T: 1),
    (S: 1; T: 1),
    (S: 0; T: 1),
    (S: 0; T: 0)
  );

var
  Data: TData;
  I: Byte;
  T: TTexCoord;
begin
  Move(AParticle.DataStart^, Data, SizeOf(Single) * 7);
  for I := 0 to 5 do
  begin
    T := AParticle.GetCorner(Corners[I]);
    Move(T, Data.DX, SizeOf(Single) * 2);
    T := AParticle.GetTexCoord(TexCoord[I]);
    Move(T, Data.S, SizeOf(Single) * 2);
    FVAO.AddVertex(Data);
  end;
end;

procedure TParticleSystem.InitVAO(AAttribNames: TParticleAttribNames);
begin
  FVAO := TVAO.Create;
  with FVAO do
  begin
    AddAttribute(3, dtFloat, FShader.AttribLocation(AAttribNames[paPosition]));
    AddAttribute(4, dtFloat, FShader.AttribLocation(AAttribNames[paColor]));
    AddAttribute(2, dtFloat, FShader.AttribLocation(AAttribNames[paCorner]));
    AddAttribute(2, dtFloat, FShader.AttribLocation(AAttribNames[paTexCoord]));

    GenAttributes;
  end;
end;

constructor TParticleSystem.Create(ACamera: TCamera; AShader: TShader; AAttribNames: TParticleAttribNames;
  AMode: TParticleSystemMode);
begin
  FCamera := ACamera;
  FShader := AShader;
  FMode := AMode;
  InitVAO(AAttribNames);
end;

destructor TParticleSystem.Destroy;
begin
  FVAO.Free;
  inherited Destroy;
end;

procedure TParticleSystem.Update(DeltaTime: Single);
var
  I: Integer;
begin
  FParticleCount := 0;
  for I := 0 to GeneratorCount - 1 do
    FParticleCount := FParticleCount + FGenerators[I].Update(DeltaTime);
end;

procedure TParticleSystem.Render;
var
  Data: array of TObject;
  I: Integer;
begin
  FShader.Enable;

  SetLength(Data, 0);

  for I := 0 to GeneratorCount - 1 do
    FGenerators[I].AddParticlesToArray(Data);

  with TParticleSorter.Create do
  begin
    Sort(Data);
    Free;
  end;

  FVAO.Map(baWriteOnly);

  for I := 0 to Length(Data) - 1 do
    AddToVAO(TBasicParticle(Data[I]));

  FVAO.Unmap;

  case FMode of
    psmNormal:
    begin
      glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
      FVAO.Render;
    end;
    psmAdditive:
    begin
      glDepthMask(ToByteBool(blFalse));
      glBlendFunc(GL_SRC_ALPHA, GL_ONE);
      FVAO.Render;
      glDepthMask(ToByteBool(blTrue));
    end;
  end;
end;

procedure TParticleSystem.AddGenerator(AGenerator: TBasicParticleGenerator);
var
  I: Integer;
begin
  I := GeneratorCount;
  SetLength(FGenerators, I + 1);
  FGenerators[I] := AGenerator;
  FGenerators[I].SetCamera(FCamera);
  if FGenerators[I].InheritsFrom(TTexturedParticleGenerator) then

  MaxSize := MaxSize + AGenerator.MaxParticles;
end;

procedure TParticleSystem.RemoveGenerator(AIndex: Integer);
begin
  if AIndex >= GeneratorCount then
    raise EPSGeneratorOutOfRange.Create(AIndex, GeneratorCount);
  MaxSize := MaxSize - FGenerators[AIndex].MaxParticles;
  Move(FGenerators[AIndex + 1], FGenerators[AIndex], SizeOf(FGenerators[AIndex]) * (GeneratorCount - AIndex - 1));
  SetLength(FGenerators, GeneratorCount - 1);
end;

procedure TParticleSystem.RemoveGenerator(AGenerator: TBasicParticleGenerator);
begin
  RemoveGenerator(GetGeneratorIndex(AGenerator));
end;

function TParticleSystem.GetGeneratorIndex(AGenerator: TBasicParticleGenerator): Integer;
var
  I: Integer;
begin
  for I := 0 to GeneratorCount - 1 do
    if Pointer(FGenerators[I]) = Pointer(AGenerator) then
      Exit(I);
  raise EPSGeneratorNotFound.Create;
end;

{ TBasicParticleGenerator }

constructor TBasicParticleGenerator.Create(AParticleType: TParticleClass; AMaxParticles: Integer);
var
  I: Integer;
begin
  FMaxParticles := AMaxParticles;
  SetLength(FParticles, FMaxParticles);
  for I := 0 to Length(FParticles) - 1 do
  begin
    FParticles[I] := AParticleType.Create;
  end;
end;

destructor TBasicParticleGenerator.Destroy;
var
  I: Integer;
begin
  for I := 0 to MaxParticles - 1 do
    FParticles[I].Free;
  inherited Destroy;
end;

function TBasicParticleGenerator.Generate: TBasicParticle;
begin
  FParticles[FNext].Generate;
  Result := FParticles[FNext];
  FNext := (FNext + 1) mod MaxParticles;
end;

function TBasicParticleGenerator.Update(DeltaTime: Single): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to MaxParticles - 1 do
    if FParticles[I].Active then
    begin
      FParticles[I].SetMVP(FCamera.Matrix[mtMVP]);
      FParticles[I].Update(DeltaTime);
      Inc(Result);
    end;
end;

procedure TBasicParticleGenerator.AddParticlesToArray(var Data: TObjectArray);
var
  Start, NewLength, I, D: Integer;
begin
  Start := Length(Data);

  NewLength := Start;
  for I := 0 to MaxParticles - 1 do
    if FParticles[I].Active then
      Inc(NewLength);

  SetLength(Data, NewLength);
  D := 0;
  for I := 0 to MaxParticles - 1 do
  begin
    if FParticles[I].Active then
    begin;
      Data[Start + D] := FParticles[I];
      FParticles[I].UpdateDepth;
      Inc(D);
    end;
  end;
end;

procedure TBasicParticleGenerator.SetCamera(ACamera: TCamera);
begin
  FCamera := ACamera;
end;

end.

