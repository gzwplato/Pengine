unit ModelDefine;

interface

uses
  Classes, SysUtils, VectorGeometry, Lists, TextureManager, VAOManager, Shaders, dglOpenGL, GLEnums, Color, CustomVAOs,
  Camera, AdvancedFileStream, InputHandler;

{
  Basic Model file stucture in two steps:
    (1) Structure File with Texture-Indices
        > *.rms (Raw Model Structure)
    (2) Model file with structure and definition, which Texture-Indice represents which Texture (filename)
        > *.tmd (Typed Model Data)

    *.tmd Files have Data on what type of model they represent
    Model Types:
    0 - Default
        > no extra data
    1 - Block
        > each face has a bound side to hide if that side is solid in context with a second block
        > 6-bit bitfield for each side, that the block is solid
            2 rest bits unused for now
        >
    2 - Animated Mesh
        > bones and stuff, think about it~
}


type

  TPoint = class;
  TFace = class;
  TBaseModel = class;

  TEditablePoint = class;
  TEditableFace = class;
  TEditableModel = class;

  { TPoint }
  // only point data
  TPoint = class
  private
    FPos: TGVector3;
  public
    constructor Create(APos: TGVector3);
    function GetPos: TGVector3;
  end;

  TFacePoints = array [TTriangleSide] of TPoint;

  { TFace }

  TFace = class
  private
    FPoints: TFacePoints;
    FTexCoords: TFaceTexCoords;
    FTexture: Cardinal;
    FNormals: TFaceNormals;

    function GetPlane: TGPlane;
    function GetTexPlane: TGPlane;
  public
    constructor Create(APoints: TFacePoints; ATexCoords: TFaceTexCoords; ATexture: Cardinal; ANormals: TFaceNormals);

    function GetPos(I: TTriangleSide): TGVector3;
    function GetNormal(I: TTriangleSide): TGVector3;
    function GetTexCoord(I: TTriangleSide): TTexCoord2;
    function GetTexture: Cardinal;

    property Plane: TGPlane read GetPlane;
    property TexPlane: TGPlane read GetTexPlane;

  end;

  TPointArray = TObjectArray<TPoint>;
  TFaceArray = TObjectArray<TFace>;

  { TBaseModel }

  TBaseModel = class
  private
    FPoints: TPointArray;
    FFaces: TFaceArray;

    function GetFace(I: Integer): TFace;
    function GetFaceCount: Integer;

    // Move this to TEditablePoint and TEditableModel
    const
      PointSize = 0.025;
      PointColor: TColorRGB = (R: 1.0; G: 1.0; B: 1.0);

      NormalScale = 0.2;
      NormalWidth = 0.01;
      NormalColor: TColorRGB = (R: 0.2; G: 0.2; B: 1.0);

  public
    constructor Create;
    destructor Destroy; override;

    function AddPoint(APos: TGVector3): TPoint; virtual;
    function AddFace(APoints: TFacePoints; ATexCoords: TFaceTexCoords; ANormals: TFaceNormals; ATexture: Cardinal): TFace; virtual;

    function LoadFromFile(AFilename: String): Boolean; virtual;

    property Faces[I: Integer]: TFace read GetFace;
    property FaceCount: Integer read GetFaceCount;

    function GetFaceAtCursor(ACamera: TCamera; AInput: TInputHandler; AModelLocation: TLocation = nil): TFace;
    function GetFaceIDAtCursor(ACamera: TCamera; AInput: TInputHandler;
      out ADistance: Single; AModelLocation: TLocation = nil): Integer; overload;
    function GetFaceIDAtCursor(ACamera: TCamera; AInput: TInputHandler;
      AModelLocation: TLocation = nil): Integer; overload;

    const
      FileExtension = '.rms';
  end;

  { TEditablePoint }
  // extends data with modifying functions
  TEditablePoint = class (TPoint)
  private
    type

      { TFindAtPos }

      TFindAtPos = class (TFindFunctionClass<TPoint>)
      private
        FPos: TGVector3;
      protected
        function Find(AElement: TPoint): Boolean; override;
      public
        constructor Create(APos: TGVector3);
      end;

      { TFindCursorLine }

      TFindCursorLine = class (TFindFunctionClass<TPoint>)
      private
        FCursorLine: TGLine;
        FCamera: TCamera;
        FRange: Single;
      protected
        function Find(APoint: TPoint): Boolean; override;
      public
        constructor Create(ACursorLine: TGLine; ACamera: TCamera; ARange: Single);
      end;

  private
    FChanged: Boolean;
    FModel: TEditableModel;

    FFaceRefs: TFaceArray;
    FCamDistance: Single;

    procedure SetPos(AValue: TGVector3);

  public
    constructor Create(APos: TGVector3; AModel: TEditableModel);
    destructor Destroy; override;

    procedure AddFaceRef(AFace: TFace);
    procedure DelFaceRef(AFace: TFace);

    property Pos: TGVector3 read FPos write SetPos;
    property FaceRefs: TFaceArray read FFaceRefs;
    function Changed: Boolean;

    class function CompareDistance(A, B: TObject): Boolean;

    class function FindAtPos(APos: TGVector3): TFindAtPos;
    class function FindCursorLine(ACursorLine: TGLine; ACamera: TCamera; ARange: Single): TFindCursorLine;

    property CamDistance: Single read FCamDistance write FCamDistance;

  end;

  { TEditableFace }

  TEditableFace = class (TFace)
  private
    type

      { TFindAtPoints }

      TFindAtPoints = class (TFindFunctionClass<TFace>)
      private
        FPoints: TFacePoints;
      protected
        function Find(AFace: TFace): Boolean; override;
      public
        constructor Create(APoints: TFacePoints);
      end;

      { TFindCursorLine }

      TFindCursorLine = class (TFindFunctionClass<TFace>)
      private
        FCursorLine: TGLine;
      protected
        function Find(AFace: TFace): Boolean; override;
      public
        constructor Create(ACursorLine: TGLine);
      end;
  private
    FCamDistance: Single;

    procedure SetNormal(I: TTriangleSide; AValue: TGVector3);
    procedure SetTexCoord(I: TTriangleSide; AValue: TTexCoord2);

  public
    constructor Create(APoints: TFacePoints; ATexCoords: TFaceTexCoords; ATexture: Cardinal; ANormals: TFaceNormals);
    destructor Destroy; override;

    property TexCoords[I: TTriangleSide]: TTexCoord2 read GetTexCoord write SetTexCoord;
    property Normals[I: TTriangleSide]: TGVector3 read GetNormal write SetNormal;
    property Texture: Cardinal read FTexture write FTexture;

    property Points: TFacePoints read FPoints;

    property CamDistance: Single read FCamDistance write FCamDistance;

    class function FindAtPoints(APoints: TFacePoints): TFindAtPoints;
    class function FindCursorLine(ACursorLine: TGLine): TFindCursorLine;
  end;

  { TEditableModel }
  // same unit > access to private data fields
  TEditableModel = class (TBaseModel)
  private
    type
      TData = record
        Pos: TGVector3;
        Tex: TTexCoord2;
        Normal: TGVector3;
      end;
  private
    FModelModeLocation: Integer;
    FPointShader: TShader;
    FNormalShader: TShader;

    FFrontActive: Boolean;
    FBackActive: Boolean;
    FPointVAO: TPointVAO;
    FNormalVAO: TLineVAO;

    FChanged: Boolean;

    FCamera: TCamera;

    FModelShader: TShader;

    FModelVAO: TVAO;
    FTexturePage: TTexturePage;

    procedure InitModelVAO;
    procedure InitPointsVAO;
    procedure InitNormalsVAO;

    procedure FinalizePointsVAO;
    procedure FinalizeNormalsVAO;
    procedure FinalizeModelVAO;

    procedure BuildVAOs;
    procedure BuildModelVAO;
    procedure BuildPointsVAO;
    procedure BuildNormalsVAO;

    function GetModelActive: Boolean;
    function GetNormalsActive: Boolean;
    function GetPointsActive: Boolean;

    function GetPos(AFace: TEditableFace; APoint: TTriangleSide): TGVector3; inline;
    function GetTex(AFace: TFace; APoint: TTriangleSide): TTexCoord2; inline;
    function GetNormal(AFace: TFace; APoint: TTriangleSide): TGVector3; inline;

  public
    constructor Create(ATexturePage: TTexturePage; ACamera: TCamera);
    destructor Destroy; override;

    function AddPoint(APos: TGVector3): TPoint; override; // TEditablePoint
    function AddFace(APoints: TFacePoints; ATexCoords: TFaceTexCoords; ANormals: TFaceNormals;
      ATexture: Cardinal): TFace; override; // TEditableFace
    function AddFaceAuto(APoints: TFacePoints; ATexture: Cardinal): TEditableFace;

    function TryAddPoint(APos: TGVector3): Boolean;
    procedure DelPoint(APoint: TPoint); overload;
    procedure DelPoint(APos: TGVector3); overload;

    function GetPointIndex(APoint: TPoint): Integer;
    function GetPoint(APos: TGVector3): TPoint; overload;
    function GetPoint(APointIndex: Integer): TPoint; overload;
    function PointExists(APos: TGVector3): Boolean;
    function PointStillExists(APoint: TPoint): Boolean;
    function GetPoints(ACursorLine: TGLine; FCamera: TCamera; ARange: Single): TPointArray;
    function GetClosestPoint(ACursorLine: TGLine; ACamera: TCamera; ARange: Single): TPoint;

    function TryAddFace(APoints: TFacePoints; ATexture: Cardinal): TEditableFace;
    procedure DelFace(AFace: TEditableFace);
    function GetFaceIndex(AFace: TEditableFace):  Integer;

    function GetFace(APoints: TFacePoints): TFace;
    function FaceExists(APoints: TFacePoints): Boolean; // Check 3 possibilities for rotating points
    function FaceStillExists(AFace: TEditableFace): Boolean;
    function GetFaces(ACursorLine: TGLine): TFaceArray;
    function GetClosestFace(ACursorLine: TGLine; ACamera: TCamera): TEditableFace;

    procedure ChangeTexCoord(AFace: TEditableFace; ACoordID: TTriangleSide; ACoord: TTexCoord2);
    procedure ChangeTexture(AFace: TEditableFace; ATexture: Integer);

    procedure ActivateFrontFaces(AShader: TShader);
    procedure ActivateBackFaces(AShader: TShader);
    procedure ActivatePoints(AShader: TShader);
    procedure ActivateNormals(AShader: TShader);

    procedure DeactivateFrontFaces;
    procedure DeactivateBackFaces;
    procedure DeactivatePoints;
    procedure DeactivateNormals;

    property FrontActive: Boolean read FFrontActive;
    property BackActive: Boolean read FBackActive;

    property ModelActive: Boolean read GetModelActive;
    property PointsActive: Boolean read GetPointsActive;
    property NormalsActive: Boolean read GetNormalsActive;

    procedure Render;

    procedure SmoothNormals(AMaxAngle: Single);

    function LoadFromFile(AFilename: String): Boolean; override;
    function SaveToFile(AFilename: String): Boolean;

    procedure GenerateSphere(Sphere: TSphere; ATexture: Cardinal; StepsX: Integer); overload;
    procedure GenerateSphere(Sphere: TSphere; ATexture: Cardinal; StepsX: Integer; StepsY: Integer); overload;

  end;

const
  AttribNamePos = 'vpos';
  AttribNameTexCoord = 'vtexcoord';
  AttribNameNormal = 'vnormal';

  UniformModelMode = 'mode';
  UniformNameTexture = 'tex';

  ModelModeFront = 0;
  ModelModeBack = 1;
  ModelModeNoLight = 2;

implementation

uses
  Math;

{ TEditableFace }

procedure TEditableFace.SetNormal(I: TTriangleSide; AValue: TGVector3);
begin
  FNormals[I] := AValue;
end;

procedure TEditableFace.SetTexCoord(I: TTriangleSide; AValue: TTexCoord2);
begin
  FTexCoords[I] := AValue;
end;

constructor TEditableFace.Create(APoints: TFacePoints; ATexCoords: TFaceTexCoords; ATexture: Cardinal;
  ANormals: TFaceNormals);
var
  P: TEditablePoint;
begin
  inherited Create(APoints, ATexCoords, ATexture, ANormals);
  for TObject(P) in APoints do
    P.AddFaceRef(Self);
end;

destructor TEditableFace.Destroy;
var
  I: TTriangleSide;
begin
  for I := 0 to 2 do
    TEditablePoint(FPoints[I]).DelFaceRef(Self);
  inherited Destroy;
end;

class function TEditableFace.FindAtPoints(APoints: TFacePoints): TFindAtPoints;
begin
  Result := TFindAtPoints.Create(APoints);
end;

class function TEditableFace.FindCursorLine(ACursorLine: TGLine): TFindCursorLine;
begin
  Result := TFindCursorLine.Create(ACursorLine);
end;

{ TEditablePoint }

constructor TEditablePoint.Create(APos: TGVector3; AModel: TEditableModel);
begin
  inherited Create(APos);
  FModel := AModel;
  FFaceRefs := TFaceArray.Create(True);
end;

destructor TEditablePoint.Destroy;
var
  Current: TObject;
begin
  // Also remove all linked faces
  for Current in FFaceRefs do
    FModel.DelFace(TEditableFace(Current));
  FFaceRefs.Free;
  inherited Destroy;
end;

procedure TEditablePoint.SetPos(AValue: TGVector3);
begin
  if FPos = AValue then
    Exit;
  FPos := AValue;
  FChanged := True;
end;

procedure TEditablePoint.AddFaceRef(AFace: TFace);
begin
  FFaceRefs.Add(AFace);
end;

procedure TEditablePoint.DelFaceRef(AFace: TFace);
begin
  FFaceRefs.DelObject(AFace);
end;

function TEditablePoint.Changed: Boolean;
begin
  Result := FChanged;
  FChanged := False;
end;

class function TEditablePoint.CompareDistance(A, B: TObject): Boolean;
begin
  Result := TEditablePoint(A).CamDistance > TEditablePoint(B).CamDistance;
end;

class function TEditablePoint.FindAtPos(APos: TGVector3): TFindAtPos;
begin
  Result := TFindAtPos.Create(APos);
end;

class function TEditablePoint.FindCursorLine(ACursorLine: TGLine; ACamera: TCamera; ARange: Single): TFindCursorLine;
begin
  Result := TFindCursorLine.Create(ACursorLine, ACamera, ARange);
end;

{ TEditableFace.TFindCursorLine }

function TEditableFace.TFindCursorLine.Find(AFace: TFace): Boolean;
var
  Data: TGPlane.TLineIntsecData;
begin
  if not (AFace is TEditableFace) then
    raise Exception.Create('Face must be editable!');
  Result := TEditableFace(AFace).Plane.LineInTri(FCursorLine, Data);
  TEditableFace(AFace).CamDistance := Data.Distance;
end;

constructor TEditableFace.TFindCursorLine.Create(ACursorLine: TGLine);
begin
  FCursorLine := ACursorLine;
end;

{ TEditablePoint.TFindCursorLine }

function TEditablePoint.TFindCursorLine.Find(APoint: TPoint): Boolean;
var
  Data: TGPlane.TLineIntsecData;
  Offset: TGVector3;
begin
  if not (APoint is TEditablePoint) then
    raise Exception.Create('Point must be editable!');
  Offset := FCamera.Location.RealPosition.VectorTo(TEditablePoint(APoint).Pos).Normalize;
  Offset := Offset / FCamera.Location.Look.GetCosAngle(Offset);

  if TGPlane.Create(TEditablePoint(APoint).Pos - Offset * FRange,
                    FCamera.Location.Right * FRange,
                    FCamera.Location.Up * FRange).LineInCircle(FCursorLine, Data) then
  begin
    TEditablePoint(APoint).CamDistance := Data.Distance;
    Exit(Data.Distance > FCamera.NearClip);
  end;
  Result := False;
end;

constructor TEditablePoint.TFindCursorLine.Create(ACursorLine: TGLine; ACamera: TCamera; ARange: Single);
begin
  FCursorLine := ACursorLine;
  FCamera := ACamera;
  FRange := ARange;
end;

{ TEditableFace.TFindAtPoints }

function TEditableFace.TFindAtPoints.Find(AFace: TFace): Boolean;
var
  A, B: Integer;
  AllEqual: Boolean;
begin
  if not (AFace is TEditableFace) then
    raise Exception.Create('Face must be editable!');Result := False;
  for A := 0 to 2 do // test each point offset for each point
  begin
    AllEqual := True;
    for B := 0 to 2 do
    begin
      if Pointer(TEditableFace(AFace).FPoints[(A + B) mod 3]) <> Pointer(FPoints[B mod 3]) then
      begin
        AllEqual := False;
        Break;
      end;
    end;
    if AllEqual then
      Exit(True);
  end;
end;

constructor TEditableFace.TFindAtPoints.Create(APoints: TFacePoints);
begin
  FPoints := APoints;
end;

{ TEditablePoint.TFindAtPos }

function TEditablePoint.TFindAtPos.Find(AElement: TPoint): Boolean;
begin
  if not (AElement is TEditablePoint) then
    raise Exception.Create('Point must be editable!');
  Result := TEditablePoint(AElement).Pos = FPos;
end;

constructor TEditablePoint.TFindAtPos.Create(APos: TGVector3);
begin
  FPos := APos;
end;

{ TFace }

function TFace.GetNormal(I: TTriangleSide): TGVector3;
begin
  Result := FNormals[I];
end;

function TFace.GetPos(I: TTriangleSide): TGVector3;
begin
  Result := FPoints[I].GetPos;
end;

function TFace.GetTexCoord(I: TTriangleSide): TTexCoord2;
begin
  Result := FTexCoords[I];
end;

function TFace.GetTexture: Cardinal;
begin
  Result := FTexture;
end;

function TFace.GetPlane: TGPlane;
begin
  Result.SV :=  FPoints[0].GetPos;
  Result.DVS := FPoints[1].GetPos - Result.SV;
  Result.DVT := FPoints[2].GetPos - Result.SV;
end;

function TFace.GetTexPlane: TGPlane;
begin
  Result.SV := FTexCoords[0];
  Result.DVS := FTexCoords[1] - Result.SV;
  Result.DVT := FTexCoords[2] - Result.SV;
end;

constructor TFace.Create(APoints: TFacePoints; ATexCoords: TFaceTexCoords; ATexture: Cardinal; ANormals: TFaceNormals);
var
  I: TTriangleSide;
begin
  for I := Low(TTriangleSide) to High(TTriangleSide) do
  begin
    FPoints[I] := APoints[I];
    FTexCoords[I] := ATexCoords[I];
    FNormals[I] := ANormals[I];
  end;
  FTexture := ATexture;
end;

{ TEditableModel }

procedure TEditableModel.InitModelVAO;
begin
  FModelVAO := TVAO.Create(FModelShader);
  FModelModeLocation := FModelShader.UniformLocation[UniformModelMode];
end;

procedure TEditableModel.InitPointsVAO;
begin
  FPointVAO := TPointVAO.Create(FPointShader);
end;

procedure TEditableModel.InitNormalsVAO;
begin
  FNormalVAO := TLineVAO.Create(FNormalShader, FCamera);
end;

procedure TEditableModel.FinalizePointsVAO;
begin
  FPointVAO.Free;
end;

procedure TEditableModel.FinalizeNormalsVAO;
begin
  FNormalVAO.Free;
end;

procedure TEditableModel.FinalizeModelVAO;
begin
  FModelVAO.Free;
end;

procedure TEditableModel.BuildModelVAO;
var
  Data: TData;
  Face: TEditableFace;
  P: Integer;
begin
  with FModelVAO do
  begin
    Generate(3 * FFaces.Count, buStaticDraw);
    Map(baWriteOnly);
    for TObject(Face) in FFaces do
    begin
      for P := 0 to 2 do
      begin
        Data.Pos := GetPos(Face, P);
        Data.Tex := GetTex(Face, P);
        Data.Normal := GetNormal(Face, P);
        AddVertex(Data);
      end;
    end;
    Unmap;
  end;
end;

procedure TEditableModel.BuildVAOs;
begin
  if ModelActive then
    BuildModelVAO;
  if PointsActive then
    BuildPointsVAO;
  if NormalsActive then
    BuildNormalsVAO;
  FChanged := False;
end;

procedure TEditableModel.BuildPointsVAO;
var
  P: TPoint;
begin
  FPointVAO.DelAll;
  for TObject(P) in FPoints do
    FPointVAO.AddPoint(P.GetPos, PointColor, PointSize);
end;

procedure TEditableModel.BuildNormalsVAO;
var
  F: TEditableFace;
  I: TTriangleSide;
begin
  FNormalVAO.DelAll;
  for TObject(F) in FFaces do
    for I := Low(TTriangleSide) to High(TTriangleSide) do
      FNormalVAO.AddLine(F.GetPos(I), F.GetPos(I) + F.Normals[I] * NormalScale, NormalColor, NormalWidth);
end;

function TEditableModel.GetModelActive: Boolean;
begin
  Result := FModelShader <> nil;
end;

function TEditableModel.GetNormalsActive: Boolean;
begin
  Result := FNormalShader <> nil;
end;

function TEditableModel.GetPointsActive: Boolean;
begin
  Result := FPointShader <> nil;
end;

function TEditableModel.GetPos(AFace: TEditableFace; APoint: TTriangleSide): TGVector3;
begin
  Result := AFace.Points[APoint].GetPos;
end;

function TEditableModel.GetTex(AFace: TFace; APoint: TTriangleSide): TTexCoord2;
begin
  Result := FTexturePage.GetTexCoord(Format('Tex%d', [AFace.GetTexture]), AFace.GetTexCoord(APoint));
end;

function TEditableModel.GetNormal(AFace: TFace; APoint: TTriangleSide): TGVector3;
begin
  Result := AFace.GetNormal(APoint);
end;

constructor TEditableModel.Create(ATexturePage: TTexturePage; ACamera: TCamera);
begin
  inherited Create;
  FTexturePage := ATexturePage;
  FCamera := ACamera;
end;

destructor TEditableModel.Destroy;
begin
  DeactivateFrontFaces;
  DeactivateBackFaces;
  DeactivatePoints;
  DeactivateNormals;
  inherited Destroy;
end;

function TEditableModel.AddPoint(APos: TGVector3): TPoint;
begin
  Result := TEditablePoint.Create(APos, Self);
  FPoints.Add(Result);
  FChanged := True;
end;

function TEditableModel.AddFace(APoints: TFacePoints; ATexCoords: TFaceTexCoords; ANormals: TFaceNormals;
  ATexture: Cardinal): TFace;
begin
  Result := TEditableFace.Create(APoints, ATexCoords, ATexture, ANormals);
  FFaces.Add(Result);
  FChanged := True;
end;

function TEditableModel.AddFaceAuto(APoints: TFacePoints; ATexture: Cardinal): TEditableFace;
var
  I: TTriangleSide;
  N: TGVector3;
  NAll: TFaceNormals;
  Tex: TFaceTexCoords;
begin
  N := TGPlane.Create(
    APoints[0].FPos,
    APoints[0].FPos.VectorTo(APoints[1].FPos),
    APoints[0].FPos.VectorTo(APoints[2].FPos)
    ).Normal;

  for I := 0 to 2 do
  begin
    NAll[I] := N;
    Tex[I] := TriangleTexCoords[I];
  end;

  Result := TEditableFace(AddFace(APoints, Tex, NAll, ATexture));
end;

function TEditableModel.TryAddPoint(APos: TGVector3): Boolean;
begin
  if PointExists(APos) then
    Exit(False);
  AddPoint(APos);
  Result := True;
end;

procedure TEditableModel.DelPoint(APoint: TPoint);
begin
  FPoints.DelObject(APoint);
  FChanged := True;
end;

procedure TEditableModel.DelPoint(APos: TGVector3);
var
  I: Integer;
begin
  I := FPoints.FindFirstIndex(TEditablePoint.TFindAtPos.Create(APos));
  if I <> -1 then
    FPoints.Del(I);
  FChanged := True;
end;

function TEditableModel.GetPointIndex(APoint: TPoint): Integer;
begin
  Result := FPoints.FindObject(APoint);
end;

function TEditableModel.GetPoint(APos: TGVector3): TPoint;
begin
  Result := FPoints.FindFirst(TEditablePoint.TFindAtPos.Create(APos)) as TPoint;
end;

function TEditableModel.GetPoint(APointIndex: Integer): TPoint;
begin
  Result := TPoint(FPoints[APointIndex]);
end;

function TEditableModel.PointExists(APos: TGVector3): Boolean;
begin
  Result := GetPoint(APos) <> nil;
end;

function TEditableModel.PointStillExists(APoint: TPoint): Boolean;
begin
  Result := FPoints.FindObject(APoint) <> -1;
end;

function TEditableModel.GetPoints(ACursorLine: TGLine; FCamera: TCamera; ARange: Single): TPointArray;
begin
  Result := FPoints.FindAsObjectArray(TEditablePoint.TFindCursorLine.Create(ACursorLine, FCamera, ARange));
end;

function TEditableModel.GetClosestPoint(ACursorLine: TGLine; ACamera: TCamera; ARange: Single): TPoint;
var
  ClosestDistance: Single;
  Current: TEditablePoint;
  All: TPointArray;
begin
  Result := nil;
  ClosestDistance := ACamera.FarClip;
  All := GetPoints(ACursorLine, ACamera, ARange);
  for TObject(Current) in All do
  begin
    if (Current.CamDistance < ClosestDistance) and (Current.CamDistance > ACamera.NearClip) then
    begin
      Result := Current;
      ClosestDistance := Current.CamDistance;
    end;
  end;
  All.Free;
end;

function TEditableModel.TryAddFace(APoints: TFacePoints; ATexture: Cardinal): TEditableFace;
begin
  if FaceExists(APoints) then
    Exit(nil);
  Result := AddFaceAuto(APoints, ATexture);
end;

procedure TEditableModel.DelFace(AFace: TEditableFace);
begin
  FFaces.DelObject(AFace);
  FChanged := True;
end;

function TEditableModel.GetFaceIndex(AFace: TEditableFace): Integer;
begin
  Result := FFaces.FindObject(AFace);
end;

function TEditableModel.GetFace(APoints: TFacePoints): TFace;
begin
  Result := FFaces.FindFirst(TEditableFace.TFindAtPoints.Create(APoints));
end;

function TEditableModel.FaceExists(APoints: TFacePoints): Boolean;
begin
  Result := GetFace(APoints) <> nil;
end;

function TEditableModel.FaceStillExists(AFace: TEditableFace): Boolean;
begin
  Result := FFaces.FindObject(AFace) <> -1;
end;

function TEditableModel.GetFaces(ACursorLine: TGLine): TFaceArray;
begin
  Result := FFaces.FindAsObjectArray(TEditableFace.FindCursorLine(ACursorLine));
end;

function TEditableModel.GetClosestFace(ACursorLine: TGLine; ACamera: TCamera): TEditableFace;
var
  All: TFaceArray;
  ClosestDistance: Single;
  Current: TEditableFace;
begin
  All := FFaces.FindAsObjectArray(TEditableFace.FindCursorLine(ACursorLine));
  Result := nil;
  ClosestDistance := ACamera.FarClip;
  for TObject(Current) in All do
  begin
    if (Current.CamDistance < ClosestDistance) and (Current.CamDistance > ACamera.NearClip) then
    begin
      Result := Current;
      ClosestDistance := Current.CamDistance;
    end;
  end;
  All.Free;
end;

procedure TEditableModel.ChangeTexCoord(AFace: TEditableFace; ACoordID: TTriangleSide; ACoord: TTexCoord2);
begin
  if AFace.TexCoords[ACoordID] = ACoord then
    Exit;
  AFace.TexCoords[ACoordID] := ACoord;
  FChanged := True;
end;

procedure TEditableModel.ChangeTexture(AFace: TEditableFace; ATexture: Integer);
begin
  AFace.Texture := ATexture;
  FChanged := True;
end;

procedure TEditableModel.ActivateFrontFaces(AShader: TShader);
begin
  if FrontActive then
    Exit;
  FModelShader := AShader;
  FFrontActive := True;
  if not BackActive then
    InitModelVAO;

  FTexturePage.Uniform(AShader, UniformNameTexture);
  FChanged := True;
end;

procedure TEditableModel.ActivateBackFaces(AShader: TShader);
begin
  if BackActive then
    Exit;
  FModelShader := AShader;
  FBackActive := True;
  if not FrontActive then
    InitModelVAO;
  FChanged := True;
end;

procedure TEditableModel.ActivatePoints(AShader: TShader);
begin
  if PointsActive then
    Exit;
  FPointShader := AShader;
  InitPointsVAO;
  FChanged := True;
end;

procedure TEditableModel.ActivateNormals(AShader: TShader);
begin
  if NormalsActive then
    Exit;
  FNormalShader := AShader;
  InitNormalsVAO;
  FChanged := True;
end;

procedure TEditableModel.DeactivateFrontFaces;
begin
  if not FrontActive then
   Exit;
  FFrontActive := False;
  if not BackActive then
  begin
    FinalizeModelVAO;
    FModelShader := nil;
  end;
  FChanged := True;
end;

procedure TEditableModel.DeactivateBackFaces;
begin
  if not BackActive then
    Exit;
  FBackActive := False;
  if not FrontActive then
  begin
    FinalizeModelVAO;
    FModelShader := nil;
  end;
  FChanged := True;
end;

procedure TEditableModel.DeactivatePoints;
begin
  if not PointsActive then
    Exit;
  FPointShader := nil;
  FinalizePointsVAO;
  FChanged := True;
end;

procedure TEditableModel.DeactivateNormals;
begin
  if not NormalsActive then
    Exit;
  FNormalShader := nil;
  FinalizeNormalsVAO;
  FChanged := True;
end;

procedure TEditableModel.Render;
begin
  if FChanged then
    BuildVAOs;

  // Points
  if PointsActive then
    FPointVAO.Render;

  // Normals
  if NormalsActive then
    FNormalVAO.Render;

  if FrontActive or BackActive then
    FModelShader.Enable;
  // Front faces
  if FrontActive then
  begin
    glUniform1i(FModelModeLocation, ModelModeFront);
    FModelVAO.Render;
  end;
  // Back faces
  if BackActive then
  begin
    glUniform1i(FModelModeLocation, ModelModeBack);
    glFrontFace(GL_CW);
    FModelVAO.Render;
    glFrontFace(GL_CCW);
  end;
end;

procedure TEditableModel.SmoothNormals(AMaxAngle: Single);
var
  Face1, Face2: TEditableFace;
  Point: TEditablePoint;
  I: TTriangleSide;
  Normals: array of TGVector3;
  N: TGVector3;
  FinalNormal: TGVector;
  SkipNormal: Boolean;
  Test: Single;

  procedure AddNormal(ANormal: TGVector3);
  begin
    SetLength(Normals, Length(Normals) + 1);
    Normals[Length(Normals) - 1] := ANormal;
  end;

begin
  for TObject(Face1) in FFaces do
  begin
    for I := 0 to 2 do
    begin
      Point := TEditablePoint(Face1.Points[I]);

      SetLength(Normals, 0);
      for TObject(Face2) in Point.FaceRefs do
      begin
        if Face1.Plane.AngleTo(Face2.Plane) <= AMaxAngle then
        begin
          SkipNormal := False;
          for N in Normals do
          begin
            Test := N.AngleTo(Face2.Plane.Normal);
            if Test = 0 then
            begin
              SkipNormal := True;
              Break;
            end;
          end;
          if not SkipNormal then
            AddNormal(Face2.Plane.Normal);
        end;
      end;

      FinalNormal := Origin;
      for N in Normals do
      begin
        FinalNormal := FinalNormal + N;
      end;
      Face1.Normals[I] := FinalNormal.Normalize;
    end;
  end;
  FChanged := True;
end;

function TEditableModel.LoadFromFile(AFilename: String): Boolean;
begin
  Result := inherited LoadFromFile(AFilename);
  FChanged := True;
end;

function TEditableModel.SaveToFile(AFilename: String): Boolean;
var
  S: TAdvFileStream;
  P: TEditablePoint;
  F: TEditableFace;
  I: Integer;
begin
  Result := False;
  try
    S := TAdvFileStream.Create(AFilename, omWrite);
    // Write Start
    with S do
    begin
      // VertexCount
      Write(FPoints.Count);

      // Vertex List
      for TObject(P) in FPoints do
        Write(P.Pos);

      // FaceList
      Write(FFaces.Count);
      for TObject(F) in FFaces do
      begin
        for I := Low(TTriangleSide) to High(TTriangleSide) do
        begin
          // Points
          Write(FPoints.FindObject(F.FPoints[I]));
          // Normals
          Write(F.Normals[I]);
          // TexCoords
          Write(F.TexCoords[I]);
        end;
        // Texture
        Write(F.Texture);
      end;
    end;
    // Write End
    Result := True;
  finally
    S.Free;
  end;
end;

procedure TEditableModel.GenerateSphere(Sphere: TSphere; ATexture: Cardinal; StepsX: Integer);
begin
  GenerateSphere(Sphere, ATexture, StepsX, Ceil(StepsX / 2));
end;

procedure TEditableModel.GenerateSphere(Sphere: TSphere; ATexture: Cardinal; StepsX: Integer; StepsY: Integer);
var
  P, T, StartIndex, I: Integer;
  C: array [0 .. 3] of Integer;
  Pts: TFacePoints;
  Face: TEditableFace;
begin
  StartIndex := FPoints.Count;

  StepsX := Ceil(StepsX);
  StepsY := Ceil(StepsY / 2);

  for P := StepsY downto -StepsY do
    for T := 0 to StepsX - 1 do
      AddPoint(Sphere.GetPoint(TGDirection.Create(T * 360 / StepsX, P * 180 / StepsY)));

  for P := 0 to StepsY * 2 - 1 do
    for T := 0 to StepsX - 1 do
    begin

      C[0] := StartIndex + (P * StepsX) + T mod StepsX;
      C[1] := StartIndex + (P * StepsX)+ (T + 1) mod StepsX;
      C[2] := StartIndex + ((P + 1) * StepsX) + T mod StepsX;
      C[3] := StartIndex + ((P + 1) * StepsX) + (T + 1) mod StepsX;

      Pts[0] := TPoint(FPoints[C[1]]);
      Pts[1] := TPoint(FPoints[C[0]]);
      Pts[2] := TPoint(FPoints[C[2]]);
      Face := TEditableFace(AddFaceAuto(Pts, ATexture));
      for I := 0 to 2 do
        Face.TexCoords[I] := QuadTexCoords[I];

      Pts[0] := TPoint(FPoints[C[2]]);
      Pts[1] := TPoint(FPoints[C[3]]);
      Pts[2] := TPoint(FPoints[C[1]]);
      Face := TEditableFace(AddFaceAuto(Pts, ATexture));
      for I := 0 to 2 do
        Face.TexCoords[I] := QuadTexCoords[I + 3];

    end;
end;

{ TBaseModel }

function TBaseModel.GetFaceCount: Integer;
begin
  Result := FFaces.Count;
end;

function TBaseModel.GetFace(I: Integer): TFace;
begin
  Result := TFace(FFaces[I]);
end;

constructor TBaseModel.Create;
begin
  FPoints := TPointArray.Create;
  FFaces := TFaceArray.Create;
end;

destructor TBaseModel.Destroy;
begin
  FFaces.Free;
  FPoints.Free;
  inherited;
end;

function TBaseModel.AddPoint(APos: TGVector3): TPoint;
begin
  Result := TPoint.Create(APos);
  FPoints.Add(Result);
end;

function TBaseModel.AddFace(APoints: TFacePoints; ATexCoords: TFaceTexCoords; ANormals: TFaceNormals;
  ATexture: Cardinal): TFace;
begin
  Result := TFace.Create(APoints, ATexCoords, ATexture, ANormals);
  FFaces.Add(Result);
end;

function TBaseModel.LoadFromFile(AFilename: String): Boolean;
var
  S: TAdvFileStream;
  I: Integer;
  J: TTriangleSide;
  Points: TFacePoints;
  Normals: TFaceNormals;
  TexCoords: TFaceTexCoords;
  Texture: Cardinal;
begin
  Result := False;
  try
    S := TAdvFileStream.Create(AFilename, omRead);
    // Read Start
    with S do
    begin
      FFaces.DelAll;
      FPoints.DelAll;

      // Vertex List
      for I := 0 to ReadInteger - 1 do
        AddPoint(ReadVector3);

      // FaceList
      for I := 0 to ReadInteger - 1 do
      begin
        for J := Low(TTriangleSide) to High(TTriangleSide) do
        begin
          // Points
          Points[J] := TPoint(FPoints[ReadInteger]);
          // Normals
          Normals[J] := ReadVector3;
          // TexCoords
          TexCoords[J] := ReadVector2;
        end;
        // Texture
        Texture := ReadCardinal;

        AddFace(Points, TexCoords, Normals, Texture);
      end;
    end;
    // Read End
    Result := True;
  except
    FFaces.DelAll;
    FPoints.DelAll;
  end;
  S.Free;
end;

function TBaseModel.GetFaceAtCursor(ACamera: TCamera; AInput: TInputHandler; AModelLocation: TLocation): TFace;
var
  I: Integer;
begin
  I := GetFaceIDAtCursor(ACamera, AInput, AModelLocation);
  if I = -1 then
    Exit(nil);
  Result := TFace(FFaces[I]);
end;

function TBaseModel.GetFaceIDAtCursor(ACamera: TCamera; AInput: TInputHandler; out ADistance: Single;
  AModelLocation: TLocation): Integer;
var
  I: Integer;
  CursorLine: TGLine;
  Data: TGPlane.TLineIntsecData;
begin
  CursorLine := ACamera.GetCursorLine(AInput.MousePos);
  if AModelLocation <> nil then
  begin
    CursorLine.SV := AModelLocation.InvMatrix * CursorLine.SV.ToVec4;
    CursorLine.DV := AModelLocation.InvRotMatrix * CursorLine.DV;
  end;
  ADistance := ACamera.FarClip;
  Result := -1;
  for I := 0 to FaceCount - 1 do
    if Faces[I].Plane.LineInTri(CursorLine, Data) and
       (Data.Distance < ADistance) and (Data.Distance > ACamera.NearClip) then
    begin
      ADistance := Data.Distance;
      Result := I;
    end;
end;

function TBaseModel.GetFaceIDAtCursor(ACamera: TCamera; AInput: TInputHandler; AModelLocation: TLocation): Integer;
var
  D: Single;
begin
  Result := GetFaceIDAtCursor(ACamera, AInput, D, AModelLocation);
end;

{ TPoint }

constructor TPoint.Create(APos: TGVector3);
begin
  FPos := APos;
end;

function TPoint.GetPos: TGVector3;
begin
  Result := FPos;
end;

end.

