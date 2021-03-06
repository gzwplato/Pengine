unit FontManager;

interface

uses
  Classes, SysUtils, VAOManager, TextureManager, GLEnums, VectorGeometry, Shaders, Color, Lists, Math;

type

  THAlignment = (haLeft, haRight, haCenter);
  TVAlignment = (vaTop, vaBottom, vaCenter);

  TDisplayMode = (dmBillboard, dm3D, dm2D);
  TVAODisplays = array [TDisplayMode] of TVAO;

  { TBMPFont }
  // A font that can get passed to text displays for rendering
  TBMPFont = class
  private
    // Font Data
    FSize: Integer; // pixel size per letter in 2^i
    FWidths: array [AnsiChar] of Byte;

    FData: TSingleTexture;
    FMaxWidth: Single;

    function GetPixel(I: AnsiChar; X, Y: Integer): TColorRGBA;
    function GetSize: Integer;
    function GetWidth(I: AnsiChar): Single;

    procedure CalculateMaxWidth;

  public
    constructor Create;
    destructor Destroy; override;

    procedure SaveToFile(AFilename: String);
    procedure LoadFromFile(AFilename: String);

    procedure LoadFromPNG(AFilename: String; ASpaceWidth: Single = 0.25);
    procedure LoadFromPNGResource(AResourceName: String; ASpaceWidth: Single = 0.25);

    procedure AutoWidth(ASpace: Single);

    property Pixel[I: AnsiChar; X, Y: Integer]: TColorRGBA read GetPixel;
    property Widths[I: AnsiChar]: Single read GetWidth;
    property Size: Integer read GetSize;
    property MaxWidth: Single read FMaxWidth;

    function GetMonoSpaceOffset(C: AnsiChar): Single;

    procedure Uniform(AShader: TShader); overload;
    procedure Uniform(AShader: TShader; AName: PAnsiChar); overload;

  end;

  { TBMPFontItem }

  TBMPFontItem = class (TBMPFont)
  private
    FTexture: TTextureID;
    FTexturePage: TTexturePage;

  public
    function ConvertTexCoord(ATexCoord: TGVector2): TGVector2;
    function ConvertTexBounds(ABounds: TGBounds2): TGBounds2;
    function HalfPixelInset(ABounds: TGBounds2): TGBounds2;

  end;

  { TBMPFontList }

  TBMPFontList = class
  private
    FFonts: TObjectSet<TBMPFontItem>;
    FPage: TTexturePage;

  public
    constructor Create;
    destructor Destroy; override;

    procedure Add(AFont: TBMPFontItem);
    procedure Del(AFont: TBMPFontItem);
    function FontExists(AFont: TBMPFontItem): Boolean;

    procedure Uniform(AShader: TShader; AName: PAnsiChar);
  end;

  { TBasicTextDisplay }

  TBasicTextDisplay = class abstract
  private
    function GetWidth: Single;
    procedure SetAlignment(AValue: THAlignment);
    procedure SetCharSpacing(AValue: Single);
    procedure SetColor(AValue: TColorRGBA);
    procedure SetCursorPos(AValue: Integer);
    procedure SetCursorVisible(AValue: Boolean);
    procedure SetFont(AValue: TBMPFont);
    procedure SetItalic(AValue: Boolean);
    procedure SetMonoSpaced(AValue: Boolean);
    procedure SetOrigin(AValue: TVAlignment);
    procedure SetHeight(AValue: Single);
    procedure SetText(AValue: AnsiString);
    procedure SetVisible(AValue: Boolean);

  protected
    FChanged: Boolean;

    FVisible: Boolean;

    FText: AnsiString;
    FAlignment: THAlignment;
    FOrigin: TVAlignment;
    FHeight: Single;
    FColor: TColorRGBA;
    FCharSpacing: Single;
    FItalic: Boolean;

    FMonoSpaced: Boolean;

    FFont: TBMPFont;

    FCursorVisible: Boolean;
    FCursorPos: Integer;

    type
      TData = record
        Pos: TGVector3;
        Tex: TTexCoord2;
        Color: TColorRGBA;
        Border: TGBounds2;
      end;

    const
      ItalicAmount = 0.2;


  public
    constructor Create(AFont: TBMPFont = nil);

    function GetMode: TDisplayMode; virtual; abstract;

    property Font: TBMPFont read FFont write SetFont;
    property Text: AnsiString read FText write SetText;
    property XOrigin: THAlignment read FAlignment write SetAlignment;
    property YOrigin: TVAlignment read FOrigin write SetOrigin;
    property Height: Single read FHeight write SetHeight;
    property CharSpacing: Single read FCharSpacing write SetCharSpacing;
    property Color: TColorRGBA read FColor write SetColor;
    property Italic: Boolean read FItalic write SetItalic;
    property Visible: Boolean read FVisible write SetVisible;
    property MonoSpaced: Boolean read FMonoSpaced write SetMonoSpaced;
    property CursorVisible: Boolean read FCursorVisible write SetCursorVisible;
    property CursorPos: Integer read FCursorPos write SetCursorPos;

    property Width: Single read GetWidth;

    function Changed: Boolean; virtual;
    procedure NotifyChanges; virtual;

    function GetVAOSize: Cardinal; virtual;
    procedure AddToVAO(AVAO: TVAO); virtual; abstract;

    function IndexFromOffset(AOffset: Single; ARoundTo: THAlignment = haCenter): Integer;
    function OffsetFromIndex(AIndex: Integer): Single;
    function GetCursorOffset: Single;

  end;

  { TTextDisplay2D }

  TTextDisplay2D = class (TBasicTextDisplay)
  private
    FPos: TGVector2;
    FDepth: Single;

    procedure SetDepth(AValue: Single);
    procedure SetPos(AValue: TGVector2);
    procedure SetX(AValue: Single);
    procedure SetY(AValue: Single);

  public
    property Pos: TGVector2 read FPos write SetPos;
    property X: Single read FPos.X write SetX;
    property Y: Single read FPos.Y write SetY;
    property Depth: Single read FDepth write SetDepth;

    function GetMode: TDisplayMode; override;
    procedure AddToVAO(AVAO: TVAO); override;

    function GetHBounds: TGBounds1;
    function GetVBounds: TGBounds1;
    function GetBounds: TGBounds2;

  end;

  { TBilldboardTextDisplay }

  TBilldboardTextDisplay = class (TBasicTextDisplay)
  private
    FPos: TGVector3;

    procedure SetPos(AValue: TGVector3);

  public
    property Pos: TGVector3 read FPos write SetPos;

    function GetMode: TDisplayMode; override;
    procedure AddToVAO(AVAO: TVAO); override;

  end;

  { TTextDisplay3D }

  TTextDisplay3D = class (TBasicTextDisplay)
  private
    FLocation: TLocation;

  public
    constructor Create(AFont: TBMPFont);
    destructor Destroy; override;

    property Location: TLocation read FLocation;

    function Changed: Boolean; override;
    procedure NotifyChanges; override;

    function GetMode: TDisplayMode; override;
    procedure AddToVAO(AVAO: TVAO); override;

  end;

  { TFontSystem }
  // A system that allows you to add and remove various different TextDisplays that all get rendered with the same
  // BMPFont into one VAO to get good performance
  TFontSystem = class
  private
    FVAOs: TVAODisplays;
    FShaders: array [TDisplayMode] of TShader;
    FFont: TBMPFont;
    FTextDisplays: TObjectArray<TBasicTextDisplay>;
    FUniformName: PAnsiChar;

    FChanged: Boolean;

    procedure InitVAO(AMode: TDisplayMode);

    function GetTextDisplayCount: Integer;

  public
    constructor Create; overload;
    constructor Create(AUniformName: PAnsiChar); overload;
    destructor Destroy; override;

    procedure SetShader(AMode: TDisplayMode; AShader: TShader);

    procedure LoadFontFromFile(AFileName: String);
    procedure LoadFontFromPNG(AFileName: String; ASpaceWidth: Single = 0.25);

    procedure Render;

    property TextDisplayCount: Integer read GetTextDisplayCount;

    procedure AddTextDisplay(ATextDisplay: TBasicTextDisplay);
    procedure RemoveTextDisplay(ATextDisplay: TBasicTextDisplay);
    procedure RemoveAllTextDisplays;
  end;

implementation

{ TBMPFontList }

constructor TBMPFontList.Create;
begin
  FFonts := TObjectSet<TBMPFontItem>.Create(True, 16);
  FPage := TTexturePage.Create;
end;

destructor TBMPFontList.Destroy;
begin
  FPage.Free;
  FFonts.Free;
  inherited Destroy;
end;

procedure TBMPFontList.Add(AFont: TBMPFontItem);
var
  F: TBMPFontItem;
begin
  FFonts.Add(AFont);
  FPage.AddTexture(TTextureItem.Create(AFont.FData.Texture));
  FPage.BuildPage(1, False);
  for F in FFonts do
  begin
    F.FTexturePage := FPage;
    F.FTexture := FPage.TextureIDs[F.FData.Texture.Name];
  end;
end;

procedure TBMPFontList.Del(AFont: TBMPFontItem);
begin
  FFonts.Del(AFont);
  FPage.DelTexture(AFont.FData.Texture.Name);
  FPage.BuildPage(1, False);
end;

function TBMPFontList.FontExists(AFont: TBMPFontItem): Boolean;
begin
  Result := FFonts[AFont];
end;

procedure TBMPFontList.Uniform(AShader: TShader; AName: PAnsiChar);
begin
  FPage.Uniform(AShader, AName);
  FPage.Bind;
end;

{ TBMPFontItem }

function TBMPFontItem.ConvertTexCoord(ATexCoord: TGVector2): TGVector2;
begin
  Result := FTexturePage.GetTexCoord(FTexture, ATexCoord);
end;

function TBMPFontItem.ConvertTexBounds(ABounds: TGBounds2): TGBounds2;
begin
  Result.C1 := ConvertTexCoord(ABounds.C1);
  Result.C2 := ConvertTexCoord(ABounds.C2);
end;

function TBMPFontItem.HalfPixelInset(ABounds: TGBounds2): TGBounds2;
begin
  Result := FTexturePage.HalfPixelInset(ABounds);
end;

{ TTextDisplay3D }

constructor TTextDisplay3D.Create(AFont: TBMPFont);
begin
  inherited;
  FLocation := TLocation.Create;
end;

destructor TTextDisplay3D.Destroy;
begin
  FLocation.Free;
  inherited Destroy;
end;

function TTextDisplay3D.Changed: Boolean;
begin
  Result := inherited Changed or FLocation.Changed;
end;

procedure TTextDisplay3D.NotifyChanges;
begin
  inherited NotifyChanges;
  Location.NotifyChanges;
end;

function TTextDisplay3D.GetMode: TDisplayMode;
begin
  Result := dm3D;
end;

procedure TTextDisplay3D.AddToVAO(AVAO: TVAO);
{
var
  C: PAnsiChar;
  I: Integer;
  D: TData;
  Offset: TGVector2;
  Color: TColorRGBA;
}
begin
  raise Exception.Create('Broken');
  AVAO := AVAO;
  {
  if Length(Text) = 0 then
    Exit;

  I := 0;
  case XOrigin of
    haLeft:
      Offset.X := 0;
    haRight:
      Offset.X := -FHeight * Width;
    haCenter:
      Offset.X := -FHeight * Width / 2;
  end;

  case YOrigin of
    vaBottom:
      Offset.Y := 0;
    vaTop:
      Offset.Y := -FHeight;
    vaCenter:
      Offset.Y := -FHeight / 2;
  end;

  D.Pos := FLocation.Pos;
  Color := FColor;
  C := @FText[1];
  while True do
  begin
    if C^ = #0 then
      Break;

    D.Char := Integer(C^);

    D.Color := Color;
    for I := 0 to 5 do
    begin
      // Calculate UV
      D.Tex := TTexCoord2.Create(QuadTexCoords[I].S * FFont.Widths[C^], QuadTexCoords[I].T);

      if FMonoSpaced then
        D.Offset := FLocation.Right * (Offset.X + D.Tex.S * FHeight + FFont.GetMonoSpaceOffset(C^)) +
                    FLocation.Up *    (Offset.Y + D.Tex.T * FHeight)
      else
        D.Offset := FLocation.Right * (Offset.X + D.Tex.S * FHeight) +
                    FLocation.Up *    (Offset.Y + D.Tex.T * FHeight);

      if FItalic then
        D.Offset.X := D.Offset.X + D.Offset.Y * ItalicAmount;

      // ADD DATA
      AVAO.AddVertex(D);
    end;
    if FMonoSpaced then
      Offset.X := Offset.X + FHeight * (FFont.MaxWidth + FCharSpacing)
    else
      Offset.X := Offset.X + FHeight * (FFont.Widths[C^] + FCharSpacing);

    Inc(C);
  end;
  }
end;

{ TBilldboardTextDisplay }

procedure TBilldboardTextDisplay.SetPos(AValue: TGVector3);
begin
  if FPos = AValue then Exit;
  FPos := AValue;
end;

function TBilldboardTextDisplay.GetMode: TDisplayMode;
begin
  Result := dmBillboard;
end;

procedure TBilldboardTextDisplay.AddToVAO(AVAO: TVAO);
{
var
  C: PAnsiChar;
  I: Integer;
  D: TData;
  Offset: Single;
  Color: TColorRGBA;
}
begin
  raise Exception.Create('Broken');
  AVAO := AVAO;
  {
  if Length(Text) = 0 then
    Exit;

  I := 0;
  case XOrigin of
    haLeft:
      D.Pos.X := FPos.X;
    haRight:
      D.Pos.X := FPos.X - FHeight * Width;
    haCenter:
      D.Pos.X := FPos.X - FHeight * Width / 2;
  end;

  case YOrigin of
    vaBottom:
      D.Pos.Y := FPos.Y;
    vaTop:
      D.Pos.Y := FPos.Y - FHeight;
    vaCenter:
      D.Pos.Y := FPos.Y - FHeight / 2;
  end;

  D.Pos.Z := FPos.Z;

  Offset := 0;
  Color := FColor;
  C := @FText[1];
  while True do
  begin
    if C^ = #0 then
      Break;

    D.Char := Integer(C^);

    D.Color := Color;
    for I := 0 to 5 do
    begin
      D.Tex.S := QuadTexCoords[I].S * FFont.Widths[C^];
      D.Tex.T := QuadTexCoords[I].T;

      if FMonoSpaced then
        D.Offset.X := Offset + (D.Tex.S + FFont.GetMonoSpaceOffset(C^)) * FHeight
      else
        D.Offset.X := Offset + D.Tex.S * FHeight;
      D.Offset.Y := D.Tex.T * FHeight;

      if FItalic then
        D.Offset.X := D.Offset.X + D.Offset.Y * ItalicAmount;

      // ADD DATA
      AVAO.AddVertex(D);
    end;
    if FMonoSpaced then
      Offset := Offset + FHeight * (FFont.MaxWidth + FCharSpacing)
    else
      Offset := Offset + FHeight * (FFont.Widths[C^] + FCharSpacing);

    Inc(C);
  end;
  }
end;

{ TTextDisplay2D }

procedure TTextDisplay2D.SetPos(AValue: TGVector2);
begin
  if FPos = AValue then
    Exit;
  FPos := AValue;
  FChanged := True;
end;

procedure TTextDisplay2D.SetDepth(AValue: Single);
begin
  if FDepth = AValue then
    Exit;
  FDepth := AValue;
  FChanged := True;
end;

procedure TTextDisplay2D.SetX(AValue: Single);
begin
  if FPos.X = AValue then
    Exit;
  FPos.X := AValue;
  FChanged := True;
end;

procedure TTextDisplay2D.SetY(AValue: Single);
begin
  if FPos.Y = AValue then
    Exit;
  FPos.Y := AValue;
  FChanged := True;
end;

function TTextDisplay2D.GetMode: TDisplayMode;
begin
  Result := dm2D;
end;

procedure TTextDisplay2D.AddToVAO(AVAO: TVAO);
var
  C: PAnsiChar;
  I: TQuadSide;
  P: Integer;
  Data: TData;
  Pos: TGVector2;
  Offset: Single;
  CursorIndex: Cardinal;
  B, TexB: TGBounds2;
begin
  if (Length(Text) = 0) and not CursorVisible then
    Exit;

  case XOrigin of
    haLeft:
      Pos.X := FPos.X;
    haRight:
      Pos.X := FPos.X - FHeight * Width;
    else // haCenter
      Pos.X := FPos.X - FHeight * Width / 2;
  end;

  case YOrigin of
    vaBottom:
      Pos.Y := FPos.Y;
    vaTop:
      Pos.Y := FPos.Y - FHeight;
    else // vaCenter
      Pos.Y := FPos.Y - FHeight / 2;
  end;

  Data.Pos.Z := Depth;

  Offset := 0;
  Data.Color := FColor;

  if FCursorVisible and (FCursorPos <= Length(Text)) then
  begin
    CursorIndex := AVAO.GetSize;
    AVAO.AddSize(6);
  end
  else
    CursorIndex := 0;

  P := 0;
  if Length(Text) > 0 then
    C := @FText[1]
  else
    C := nil;

  while True do
  begin
    if FCursorVisible and (P = FCursorPos) then
    begin
      B.Horizontal := TGBounds1.Create(0, FFont.Widths[#0]);
      B.Vertical := TGBounds1.Create(0, 1);

      TexB.Horizontal := B.Horizontal / 16;
      TexB.Vertical := 1 - (1 - B.Vertical) / 16;

      if Font is TBMPFontItem then with Font as TBMPFontItem do
      begin
        TexB := ConvertTexBounds(TexB);
        Data.Border := HalfPixelInset(TexB);
      end
      else
      begin
        Data.Border.C1 := TexB.C1 + 1 / (Font.Size * 2);
        Data.Border.C2 := TexB.C2 - 1 / (Font.Size * 2);
      end;

      for I := 0 to 5 do
      begin
        if FMonoSpaced then
          Data.Pos.X := Pos.X + Offset + (B[QuadTexCoords[I]].S - 3 / 32 + FFont.GetMonoSpaceOffset(#0)) * FHeight
        else
          Data.Pos.X := Pos.X + Offset + (B[QuadTexCoords[I]].S - 3 / 32) * FHeight;
        Data.Pos.Y := Pos.Y + B[QuadTexCoords[I]].T * FHeight;

        if FItalic then
          Data.Pos.X := Data.Pos.X + B[QuadTexCoords[I]].T * FHeight * ItalicAmount;

        Data.Tex := TexB[QuadTexCoords[I]];

        AVAO.SetVertex(Data, CursorIndex + I);
      end;
    end;

    if (C = nil) or (C^ = #0) then
      Break;

    B.Horizontal := TGBounds1.Create(0, FFont.Widths[C^]);
    B.Vertical := TGBounds1.Create(0, 1);

    TexB.Horizontal := (B.Horizontal + Ord(C^) mod 16) / 16;
    TexB.Vertical := 1 - (1 - B.Vertical + Ord(C^) div 16) / 16;

    if Font is TBMPFontItem then with Font as TBMPFontItem do
    begin
      TexB := ConvertTexBounds(TexB);
      Data.Border := HalfPixelInset(TexB);
    end
    else
    begin
      Data.Border.C1 := TexB.C1 + 1 / (Font.Size * 2);
      Data.Border.C2 := TexB.C2 - 1 / (Font.Size * 2);
    end;

    for I := 0 to 5 do
    begin
      if FMonoSpaced then
        Data.Pos.X := Pos.X + Offset + (B[QuadTexCoords[I]].S + FFont.GetMonoSpaceOffset(C^)) * FHeight
      else
        Data.Pos.X := Pos.X + Offset + B[QuadTexCoords[I]].S * FHeight;
      Data.Pos.Y := Pos.Y + B[QuadTexCoords[I]].T * FHeight;

      if FItalic then
        Data.Pos.X := Data.Pos.X + B[QuadTexCoords[I]].T * FHeight * ItalicAmount;

      Data.Tex := TexB[QuadTexCoords[I]];

      AVAO.AddVertex(Data);
    end;

    if FMonoSpaced then
      Offset := Offset + FHeight * (FFont.MaxWidth + FCharSpacing)
    else
      Offset := Offset + FHeight * (FFont.Widths[C^] + FCharSpacing);

    Inc(C);
    Inc(P);
  end;
end;

function TTextDisplay2D.GetHBounds: TGBounds1;
begin
  case XOrigin of
    haLeft:
    begin
      Result.Low := Pos.X;
      Result.High := Pos.X + Width * Height;
    end;
    haRight:
    begin
      Result.Low := Pos.X - Width * Height;
      Result.High :=  Pos.X;
    end
    else //haCenter
    begin
      Result.Low := Pos.X - Width * Height / 2;
      Result.High :=  Pos.X + Width * Height / 2;
    end;
  end;
end;

function TTextDisplay2D.GetVBounds: TGBounds1;
begin
  case YOrigin of
    vaTop:
    begin
      Result.Low := Pos.Y - Height;
      Result.High := Pos.Y;
    end;
    vaBottom:
    begin
      Result.Low := Pos.Y;
      Result.High := Pos.Y + Height;
    end;
    else //vaCenter
    begin
      Result.Low := Pos.Y - Height;
      Result.High := Pos.Y + Height;
    end;
  end;
end;

function TTextDisplay2D.GetBounds: TGBounds2;
begin
  Result.Horizontal := GetHBounds;
  Result.Vertical := GetVBounds;;
end;

{ TBasicTextDisplay }

procedure TBasicTextDisplay.SetAlignment(AValue: THAlignment);
begin
  if FAlignment = AValue then
    Exit;
  FAlignment := AValue;
  FChanged := True;
end;

function TBasicTextDisplay.GetWidth: Single;
var
  I: Integer;
begin
  // NOT scaled! 1 char = 1 unit
  if FMonoSpaced then
    Exit((FFont.MaxWidth + CharSpacing) * Length(Text));

  Result := 0;
  for I := 1 to Length(Text) do
    Result := Result + FFont.Widths[Text[I]] + CharSpacing;

  if Length(Text) > 0 then
    Result := Result - CharSpacing;

  if Italic then
    Result := Result + ItalicAmount;
end;

procedure TBasicTextDisplay.SetCharSpacing(AValue: Single);
begin
  if FCharSpacing = AValue then
    Exit;
  FCharSpacing := AValue;
  FChanged := True;
end;

procedure TBasicTextDisplay.SetColor(AValue: TColorRGBA);
begin
  if FColor = AValue then
    Exit;
  FColor := AValue;
  FChanged := True;
end;

procedure TBasicTextDisplay.SetCursorPos(AValue: Integer);
begin
  AValue := EnsureRange(AValue, 0, Length(Text));
  if FCursorPos = AValue then
    Exit;
  FCursorPos := AValue;
  FChanged := True;
end;

procedure TBasicTextDisplay.SetCursorVisible(AValue: Boolean);
begin
  if FCursorVisible = AValue then
    Exit;
  FCursorVisible := AValue;
  FChanged := True;
end;

procedure TBasicTextDisplay.SetItalic(AValue: Boolean);
begin
  if FItalic = AValue then
    Exit;
  FItalic := AValue;
  FChanged := True;
end;

procedure TBasicTextDisplay.SetMonoSpaced(AValue: Boolean);
begin
  if FMonoSpaced = AValue then
    Exit;
  FMonoSpaced := AValue;
  FChanged := True;
end;

procedure TBasicTextDisplay.SetOrigin(AValue: TVAlignment);
begin
  if FOrigin = AValue then
    Exit;
  FOrigin := AValue;
  FChanged := True;
end;

procedure TBasicTextDisplay.SetHeight(AValue: Single);
begin
  if FHeight = AValue then
    Exit;
  FHeight := AValue;
  FChanged := True;
end;

procedure TBasicTextDisplay.SetText(AValue: AnsiString);
begin
  if FText = AValue then
    Exit;
  FText := AValue;
  CursorPos := EnsureRange(CursorPos, 0, Length(Text));
  FChanged := True;
end;

procedure TBasicTextDisplay.SetVisible(AValue: Boolean);
begin
  if FVisible = AValue then
    Exit;
  FVisible := AValue;
  FChanged := True;
end;

constructor TBasicTextDisplay.Create(AFont: TBMPFont);
begin
  FVisible := True;
  FHeight := 1;
  FColor := ColorWhite;
  FFont := AFont;
  FCharSpacing := 1 / 16;
end;

function TBasicTextDisplay.Changed: Boolean;
begin
  Result := FChanged;
end;

procedure TBasicTextDisplay.NotifyChanges;
begin
  FChanged := True;
end;

procedure TBasicTextDisplay.SetFont(AValue: TBMPFont);
begin
  if Pointer(FFont) = Pointer(AValue) then
    Exit;
  FFont := AValue;
  FChanged := True;
end;

function TBasicTextDisplay.GetVAOSize: Cardinal;
begin
  Result := Length(Text) * 6;
  if CursorVisible and (FCursorPos <= Length(Text)) then
    Result := Result + 6;
end;

function TBasicTextDisplay.IndexFromOffset(AOffset: Single; ARoundTo: THAlignment): Integer;
var
  A, W: Single;
  I: Integer;
begin
  A := 0;
  for I := 1 to Length(Text) do
  begin
    case ARoundTo of
      haLeft:
        W := Font.Widths[Text[I]] + CharSpacing;
      haCenter:
        W := Font.Widths[Text[I]] / 2;
      else // haRight
        W := 0;
    end;
    if AOffset < A + W then
      Exit(I - 1);
    A := A + Font.Widths[Text[I]] + CharSpacing;
  end;
  Exit(Length(Text));
end;

function TBasicTextDisplay.OffsetFromIndex(AIndex: Integer): Single;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to Length(Text) - 1 do
  begin
    if I = AIndex then
      Exit;
    Result := Result + Font.Widths[Text[I + 1]] + CharSpacing;
  end;
end;

function TBasicTextDisplay.GetCursorOffset: Single;
begin
  Result := OffsetFromIndex(CursorPos);
end;

{ TFontSystem }

procedure TFontSystem.InitVAO(AMode: TDisplayMode);
begin
  FVAOs[AMode] := TVAO.Create(FShaders[AMode]);
end;

function TFontSystem.GetTextDisplayCount: Integer;
begin
  Result := FTextDisplays.Count;
end;

constructor TFontSystem.Create(AUniformName: PAnsiChar);
begin
  FFont := TBMPFont.Create;
  FUniformName := AUniformName;
  FTextDisplays := TObjectArray<TBasicTextDisplay>.Create(True);
end;

constructor TFontSystem.Create;
begin
  Create('fontmap');
end;

destructor TFontSystem.Destroy;
var
  I: TDisplayMode;
begin
  FFont.Free;
  FTextDisplays.Free;
  for I := Low(TDisplayMode) to High(TDisplayMode) do
    FVAOs[I].Free;
  inherited;
end;

procedure TFontSystem.SetShader(AMode: TDisplayMode; AShader: TShader);
begin
  FShaders[AMode] := AShader;
  FFont.Uniform(AShader, FUniformName);
  InitVAO(AMode);
end;

procedure TFontSystem.LoadFontFromFile(AFileName: String);
begin
  FFont.LoadFromFile(AFilename);
end;

procedure TFontSystem.LoadFontFromPNG(AFileName: String; ASpaceWidth: Single);
begin
  FFont.LoadFromPNG(AFileName, ASpaceWidth);
end;

procedure TFontSystem.Render;
var
  AnyChange: Boolean;
  M: TDisplayMode;
  Size: array [TDisplayMode] of Cardinal;
  Current: TBasicTextDisplay;
begin
  AnyChange := FChanged;

  for M := Low(TDisplayMode) to High(TDisplayMode) do
    Size[M] := 0;

  for Current in FTextDisplays do
  begin
    M := Current.GetMode;
    if Current.Visible then
      Size[M] := Size[M] + Current.GetVAOSize;
    if Current.Changed then
      AnyChange := True;
  end;

  if AnyChange then
  begin
    for M := Low(TDisplayMode) to High(TDisplayMode) do
      if Size[M] > 0 then
      begin
        if FVAOs[M] = nil then
          raise Exception.Create('TODO! No Shader for Text DisplayMode set!');
        FVAOs[M].Generate(Size[M], buStaticDraw);
        FVAOs[M].Map(baWriteOnly);

        for Current in FTextDisplays do
          if (Current.GetMode = M) and Current.Visible then
            Current.AddToVAO(FVAOs[M]);

        FVAOs[M].Unmap;
      end;
  end;

  for M := Low(TDisplayMode) to High(TDisplayMode) do
    if Size[M] > 0 then
    begin
      FShaders[M].Enable;
      FFont.Uniform(FShaders[M], 'tex');
      FVAOs[M].Render;
    end;

  FChanged := False;
end;

procedure TFontSystem.AddTextDisplay(ATextDisplay: TBasicTextDisplay);
begin
  ATextDisplay.Font := FFont;
  FTextDisplays.Add(ATextDisplay);
  FChanged := True;
end;

procedure TFontSystem.RemoveTextDisplay(ATextDisplay: TBasicTextDisplay);
begin
  FTextDisplays.DelObject(ATextDisplay);
  FChanged := True;
end;

procedure TFontSystem.RemoveAllTextDisplays;
begin
  if FTextDisplays.Count > 0 then
  begin
    FChanged := True;
    FTextDisplays.DelAll;
  end;
end;

{ TBMPFont }

procedure TBMPFont.LoadFromFile(AFilename: String);
var
  T: TTextureData;
begin
  with TFileStream.Create(AFilename, fmOpenRead) do
  begin
    Read(FSize, 1);
    Read(FWidths, $100);
    T := TTextureData.Create(
      Size * 16,
      Size * 16,
      4,
      AFilename
    );
    Read(T.Data[ttMain]^, Size * $1000 * T.Bpp);
    Free;
  end;
  FData.Texture := T;
end;

procedure TBMPFont.LoadFromPNG(AFilename: String; ASpaceWidth: Single);
begin
  FData.Texture := TTextureData.Create(AFileName);
  FSize := FData.Texture.Width div 16;
  AutoWidth(ASpaceWidth);
end;

procedure TBMPFont.LoadFromPNGResource(AResourceName: String; ASpaceWidth: Single);
begin
  FData.Texture := TTextureData.Create(AResourceName, True);
  FSize := FData.Texture.Width div 16;
  AutoWidth(ASpaceWidth);
end;

procedure TBMPFont.AutoWidth(ASpace: Single);
var
  I: AnsiChar;
  X, Y: Integer;
  Next: Boolean;
begin
  for I := #0 to #255 do
  begin
    if I = #32 then
      Continue;
    Next := False;
    for X := 15 downto 0 do
    begin
      for Y := 0 to 15 do
        if Pixel[I, X, Y].A <> 0 then
        begin
          FWidths[I] := X * $80 div 16 + 8;
          Next := True;
          Break;
        end;
      if Next then
        Break;
    end;
  end;
  X := Floor(ASpace * $80);
  FWidths[#32] := X;  // Normal Space
  FWidths[#160] := X; // Non-Breaking Space
  CalculateMaxWidth;
end;

function TBMPFont.GetMonoSpaceOffset(C: AnsiChar): Single;
begin
  Result := (MaxWidth - Widths[C]) / 2;
end;

procedure TBMPFont.Uniform(AShader: TShader);
begin
  Uniform(AShader, 'tex');
end;

procedure TBMPFont.Uniform(AShader: TShader; AName: PAnsiChar);
begin
  FData.Uniform(AShader, AName);
end;

function TBMPFont.GetWidth(I: AnsiChar): Single;
begin
  Result := FWidths[I] / $80;
end;

procedure TBMPFont.CalculateMaxWidth;
var
  C: AnsiChar;
begin
  FMaxWidth := Widths[#0];
  for C := #1 to #255 do
    FMaxWidth := Max(FMaxWidth, Widths[C]);
end;

constructor TBMPFont.Create;
begin
  FData := TSingleTexture.Create;
end;

function TBMPFont.GetSize: Integer;
begin
  Result := Floor(Power(2, FSize));
end;

function TBMPFont.GetPixel(I: AnsiChar; X, Y: Integer): TColorRGBA;
var
  Offset: Integer;
begin
  Offset := ((Byte(I) mod 16) + (15 - Byte(I) div 16) * 256 + (15 - Y) * 16) * 64 + X * 4;
  Result.R := (FData.Texture.Data[ttMain] + Offset)[0] / $FF;
  Result.G := (FData.Texture.Data[ttMain] + Offset)[1] / $FF;
  Result.B := (FData.Texture.Data[ttMain] + Offset)[2] / $FF;
  Result.A := (FData.Texture.Data[ttMain] + Offset)[3] / $FF;
end;

destructor TBMPFont.Destroy;
begin
  if FData.Texture <> nil then
    FData.Texture.Free;
  FData.Free;
  inherited;
end;

procedure TBMPFont.SaveToFile(AFilename: String);
var
  FS: TFileStream;
begin
  FS := TFileStream.Create(AFilename, fmCreate);
  FS.Write(FSize, 1);
  FS.Write(FWidths, 256);
  FS.Write(FData.Texture.Data[ttMain]^, Size * $1000 * FData.Texture.Bpp);
  FS.Free;
end;

end.

