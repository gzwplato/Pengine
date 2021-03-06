unit Lists;

interface

uses
  Classes, SysUtils;

type

  { TFindFunctionClass }

  TFindFunctionClass<T> = class abstract
  protected
    function Find(AElement: T): Boolean; virtual; abstract;
  end;

  TCompareFunction<T> = function(A, B: T): Boolean;
  TCompareFunctionOfObject<T> = function(A, B: T): Boolean of object;

  TFindFunctionStatic<T> = function(A: T): Boolean;
  TFindFunctionOfObject<T> = function(A: T): Boolean of object;


 { TPair }

  TPair<TKey, TData> = record
  private
    FKey: TKey;
    FData: TData;
  public
    constructor Create(AKey: TKey; AData: TData);

    property Key: TKey read FKey;
    property Data: TData read FData;
  end;

  { TArrayList<T> }

  TIntArray = class;
  TArrayList<T> = class
  private
    FItems: array of T;
    FIterReversed: Boolean;
    FSizeSteps: Integer;
    FCount: Integer;

    procedure SortLR(ACompareFunc: TCompareFunction<T>; ALeft, ARight: Integer); overload;
    procedure SortLR(ACompareFunc: TCompareFunctionOfObject<T>; ALeft, ARight: Integer); overload;

  public
    type

      { TIterator }

      TIterator = class
      private
        FList: TArrayList<T>;

        FCurrent: Integer;
        FReversed: Boolean;
        FAutoFree: Boolean;

        FRemoveFlag: Boolean;

        function GetCurrent: T;
      public
        constructor Create(AList: TArrayList<T>; AReversed, AAutoFree: Boolean);

        function MoveNext: Boolean;
        property Current: T read GetCurrent;

        procedure RemoveCurrent;
      end;

  protected
    function GetItem(AIndex: Integer): T; virtual;
    procedure SetItem(AIndex: Integer; AValue: T); virtual;

    procedure FreeData(const {%H-}AData: T); virtual;

    function EntryNotFound: T; virtual;

  public
    constructor Create(ASizeSteps: Integer = 16);

    function Add(AElement: T): T;
    function Insert(AElement: T; AIndex: Integer): T;

    procedure Del(AIndex: Integer);
    procedure DelLast;
    procedure DelAll;

    procedure Swap(A, B: Integer);

    function FindFirstIndex(AFunc: TFindFunctionStatic<T>): Integer; overload;
    function FindFirstIndex(AFunc: TFindFunctionOfObject<T>): Integer; overload;
    function FindFirstIndex(AFunc: TFindFunctionClass<T>; ADoFree: Boolean = True): Integer; overload;

    function FindFirst(AFunc: TFindFunctionStatic<T>): T; overload;
    function FindFirst(AFunc: TFindFunctionOfObject<T>): T; overload;
    function FindFirst(AFunc: TFindFunctionClass<T>; ADoFree: Boolean = True): T; overload;

    function FindLastIndex(AFunc: TFindFunctionStatic<T>): Integer; overload;
    function FindLastIndex(AFunc: TFindFunctionOfObject<T>): Integer; overload;
    function FindLastIndex(AFunc: TFindFunctionClass<T>; ADoFree: Boolean = True): Integer; overload;

    function FindLast(AFunc: TFindFunctionStatic<T>): T; overload;
    function FindLast(AFunc: TFindFunctionOfObject<T>): T; overload;
    function FindLast(AFunc: TFindFunctionClass<T>; ADoFree: Boolean = True): T; overload;

    function FindIndexAsArray(AFunc: TFindFunctionStatic<T>): TIntArray; overload;
    function FindIndexAsArray(AFunc: TFindFunctionOfObject<T>): TIntArray; overload;
    function FindIndexAsArray(AFunc: TFindFunctionClass<T>; ADoFree: Boolean = True): TIntArray; overload;

    function FindAsArray(AFunc: TFindFunctionStatic<T>): TArrayList<T>; overload; virtual;
    function FindAsArray(AFunc: TFindFunctionOfObject<T>): TArrayList<T>; overload; virtual;
    function FindAsArray(AFunc: TFindFunctionClass<T>; ADoFree: Boolean = True): TArrayList<T>; overload; virtual;

    procedure Sort(AFunc: TCompareFunction<T>); overload;
    procedure Sort(AFunc: TCompareFunctionOfObject<T>); overload;

    function Copy: TArrayList<T>; virtual;

    property Count: Integer read FCount;
    function Empty: Boolean;

    property Items[I: Integer]: T read GetItem write SetItem; default;

    function First: T; virtual;
    function Last: T; virtual;

    function Ptr: Pointer;

    function GetEnumerator(AAutoFree: Boolean = False): TIterator;
    function IterReversed: TArrayList<T>;

    procedure RangeCheckException(AIndex: Integer);
    function RangeCheck(AIndex: Integer): Boolean;
  end;

  { TNotifyArray }

  TNotifyArray<T> = class (TArrayList<T>)
  private
    FChanged: Boolean;
  protected
    procedure SetItem(AIndex: Integer; AValue: T); override;
  public
    property Changed: Boolean read FChanged;
    procedure NotifyChanges;
  end;

  { TIntArray }

  TIntArray = class (TArrayList<Integer>)
  public
    function Sum: Integer;

    function ToString: String; override;
  end;

  { TObjectArray<T> }

  TObjectArray<T: class> = class (TArrayList<T>)
  private
    FReferenceList: Boolean;

  protected
    procedure FreeData(const AData: T); override;

    function EntryNotFound: T; override;

  public
    constructor Create(AReferenceList: Boolean = False; ASizeSteps: Integer = 16);
    destructor Destroy; override;

    function FindAsObjectArray(AFunc: TFindFunctionStatic<T>): TObjectArray<T>; overload;
    function FindAsObjectArray(AFunc: TFindFunctionOfObject<T>): TObjectArray<T>; overload;
    function FindAsObjectArray(AFunc: TFindFunctionClass<T>; ADoFree: Boolean = True): TObjectArray<T>; overload;

    function FindObject(AData: T): Integer;
    procedure DelObject(AData: T);

    function Copy: TArrayList<T>; override;

    function First: T; override;
    function Last: T; override;

    function ToString: String; override;
  end;

  { TObjectStack<T> }

  TObjectStack<T: class> = class
  private
    type

      { TItem }

      TItem = class
        Prev: TItem;
        Data: T;

        constructor Create(AData: T; APrev: TItem);
      end;

  private
    FTop: TItem;
    FReferenceList: Boolean;

  public
    constructor Create(AReferenceList: Boolean = False);
    destructor Destroy; override;

    function Push(AElement: T): T;
    function Pop: Boolean;
    function Top: T;

    function Copy: TObjectStack<T>;
  end;

  { THashBase }

  THashBase<TKey> = class abstract
  protected
    FCount: Cardinal;
    FInternalSize: Cardinal;

    function GetKeyHash(AKey: TKey): Cardinal; virtual; abstract;
    class function CantIndex({%H-}AKey: TKey): Boolean; virtual;
    class function KeysEqual(AKey1, AKey2: TKey): Boolean; virtual; abstract;

  public
    constructor Create(AInternalSize: Cardinal);
  end;

  { TMap }

  TMap<TKey, TData> = class abstract (THashBase<TKey>)
  private
    type

      { THashEntry }

      THashEntry = class
      public
        Key: TKey;
        Data: TData;
        Next: THashEntry;
      end;

  public
    type

      { TIterator }

      TIterator = class
      private
        FList: TMap<TKey, TData>;
        FIndex: Integer;
        FEntry: THashEntry;

        function GetCurrent: TPair<TKey, TData>;

      public
        constructor Create(AList: TMap<TKey, TData>);

        function MoveNext: Boolean;
        property Current: TPair<TKey, TData> read GetCurrent;

      end;

  private
    FData: array of THashEntry;

  protected
    property InternalSize: Cardinal read FInternalSize; // for getHash

    function GetEntry(AKey: TKey): TData; virtual;
    procedure SetEntry(AKey: TKey; AValue: TData); virtual;

    procedure FreeData(const {%H-}AData: TData); virtual;

  public
    constructor Create(AInternalSize: Cardinal = 256);
    destructor Destroy; override;

    function Get(AKey: TKey; out AData: TData): Boolean;
    function HasKey(AKey: TKey): Boolean;
    procedure Del(AKey: TKey);

    property Data[AKey: TKey]: TData read GetEntry write SetEntry; default;

    function NextKeyCheck(AKey: TKey; out AOut: TKey): Boolean; overload;
    function NextKeyCheck(var AKey: TKey): Boolean; overload;

    function PrevKeyCheck(AKey: TKey; out AOut: TKey): Boolean; overload;
    function PrevKeyCheck(var AKey: TKey): Boolean; overload;

    function HasNextKey(AKey: TKey): Boolean;
    function HasPrevKey(AKey: TKey): Boolean;

    function NextKey(AKey: TKey): TKey;
    function PrevKey(AKey: TKey): TKey;

    function FirstKeyCheck(out AOut: TKey): Boolean;
    function LastKeyCheck(out AOut: TKey): Boolean;

    function FirstKey: TKey;
    function LastKey: TKey;

    function NextData(AKey: TKey): TData;
    function PrevData(AKey: TKey): TData;

    procedure DelAll;

    function GetEnumerator: TIterator;
    property Count: Cardinal read FCount;

  end;

  { TClassMap }

  TClassMap<T: class> = class (TMap<TClass, T>)
  protected
    function GetKeyHash(AKey: TClass): Cardinal; override;
    class function CantIndex(AKey: TClass): Boolean; override;
    class function KeysEqual(AKey1, AKey2: TClass): Boolean; override;
  end;

  { TObjectMap }

  TObjectMap<TKey, TData: class> = class (TMap<TKey, TData>)
  private
    FReferenceList: Boolean;

  protected
    function GetKeyHash(AKey: TKey): Cardinal; override;
    class function CantIndex(AKey: TKey): Boolean; override;
    class function KeysEqual(AKey1, AKey2: TKey): Boolean; override;

    procedure FreeData(const AData: TData); override;

  public
    constructor Create(AReferenceList: Boolean = False; AInternalSize: Cardinal = 256);
  end;

  { TStringMap<TData> }

  TStringMap<TData> = class (TMap<String, TData>)
  protected
    function GetKeyHash(AKey: String): Cardinal; override;
    class function CantIndex(AKey: String): Boolean; override;
    class function KeysEqual(AKey1, AKey2: String): Boolean; override;
  end;

  { TAnsiStringMap<TData> }

  TAnsiStringMap<TData> = class (TMap<AnsiString, TData>)
  protected
    function GetKeyHash(AKey: AnsiString): Cardinal; override;
    class function CantIndex(AKey: AnsiString): Boolean; override;
    class function KeysEqual(AKey1, AKey2: AnsiString): Boolean; override;
  end;

  { TStringObjectMap }

  TStringObjectMap<TData: class> = class (TStringMap<TData>)
  protected
    function GetEntry(AKey: String): TData; override;
    procedure FreeData(const AData: TData); override;
  end;

  { TAnsiStringObjectMap<TData> }

  TAnsiStringObjectMap<TData: class> = class (TAnsiStringMap<TData>)
  protected
    function GetEntry(AKey: AnsiString): TData; override;
    procedure FreeData(const AData: TData); override;
  end;

  { TSet<T> }

  TSet<T> = class abstract (THashBase<T>)
  private
    type

      { TEntry }

      TEntry = class
      public
        Data: T;
        Next: TEntry;
      end;

      { TIterator }

      TIterator = class
      private
        FList: TSet<T>;
        FIndex: Integer;
        FEntry: TEntry;
        function GetCurrent: T;
      public
        constructor Create(AList: TSet<T>);

        function MoveNext: Boolean;
        property Current: T read GetCurrent;
      end;

  private
    FTags: array of TEntry;

  protected
    function GetElement(S: T): Boolean; virtual;
    procedure SetElement(S: T; AValue: Boolean); virtual;

    procedure FreeData(const {%H-}AData: T); virtual;

  public
    constructor Create(AInternalSize: Cardinal = 256);
    destructor Destroy; override;

    property Elements[S: T]: Boolean read GetElement write SetElement; default;
    procedure Add(S: T);
    procedure Del(S: T);

    property Count: Cardinal read FCount;

    procedure Clear;

    procedure Assign(ATagList: TSet<T>);

    function GetEnumerator: TIterator;
  end;

  { TObjectSet }

  TObjectSet<T: class> = class (TSet<T>)
  private
    FReferenceList: Boolean;

  protected
    function GetKeyHash(AKey: T): Cardinal; override;
    class function CantIndex(AKey: T): Boolean; override;
    class function KeysEqual(AKey1, AKey2: T): Boolean; override;

    procedure FreeData(const AData: T); override;

  public
    constructor Create(AReferenceList: Boolean = False; AInternalSize: Cardinal = 256);

  end;

  { TTags }

  TTags = class (TSet<String>)
  protected
    function GetKeyHash(AKey: String): Cardinal; override;
    class function CantIndex(AKey: String): Boolean; override;
    class function KeysEqual(AKey1, AKey2: String): Boolean; override;
  end;

  { TCardinalSet }

  TCardinalSet = class (TSet<Cardinal>)
  protected
    function GetKeyHash(AKey: Cardinal): Cardinal; override;
    class function CantIndex({%H-}AKey: Cardinal): Boolean; override;
    class function KeysEqual(AKey1, AKey2: Cardinal): Boolean; override;
  end;

function GetHash(AObject: TObject; ARange: Cardinal): Cardinal; overload; inline;
function GetHash(AString: WideString; ARange: Cardinal): Cardinal; overload; inline;
function GetHash(AString: AnsiString; ARange: Cardinal): Cardinal; overload; inline;

implementation

function GetHash(AObject: TObject; ARange: Cardinal): Cardinal;
var
  I: NativeUInt;
begin
  I := NativeUInt(Pointer(AObject));
  Result := (I xor Cardinal(I shl 3) xor (I shr 7)) mod ARange;
end;

function GetHash(AString: WideString; ARange: Cardinal): Cardinal;
var
  C: Char;
begin
  Result := 0;
  for C in AString do
    Result := Cardinal((Result + Ord(C)) xor Ord(C) * Ord(C));
  Result := Result mod ARange;
end;

function GetHash(AString: AnsiString; ARange: Cardinal): Cardinal;
var
  C: AnsiChar;
begin
  Result := 0;
  for C in AString do
    Result := Cardinal((Result + Ord(C)) xor Ord(C) * Ord(C));
  Result := Result mod ARange;
end;

{ TObjectStack<T>.TItem }

constructor TObjectStack<T>.TItem.Create(AData: T; APrev: TItem);
begin
  Data := AData;
  Prev := APrev;
end;

{ TPair<TKey, TData> }

constructor TPair<TKey, TData>.Create(AKey: TKey; AData: TData);
begin
  FKey := AKey;
  FData := AData;
end;

{ THashTable<TKey, TData> }

function TMap<TKey, TData>.GetEntry(AKey: TKey): TData;
begin
  if not Get(AKey, Result) then
    raise Exception.Create('HashTable Key missing');
end;

procedure TMap<TKey, TData>.SetEntry(AKey: TKey; AValue: TData);
var
  Entry: THashEntry;
  Hash: Cardinal;
begin
  if CantIndex(AKey) then
    raise Exception.Create('Invalid HashTable-Index');

  Hash := GetKeyHash(AKey);
  if FData[Hash] = nil then
  begin
    // create new base entry
    FData[Hash] := THashEntry.Create;
    FData[Hash].Key := AKey;
    FData[Hash].Data := AValue;
    Inc(FCount);
    Exit;
  end;

  Entry := FData[Hash];
  // find key in list
  while not KeysEqual(Entry.Key, AKey) do
  begin
    if Entry.Next = nil then // not fount > add entry
    begin
      Entry.Next := THashEntry.Create;
      Entry.Next.Key := AKey;
      Entry.Next.Data := AValue;
      Inc(FCount);
      Exit;
    end;
    Entry := Entry.Next;
  end;

  // update Data
  FreeData(Entry.Data);
  Entry.Data := AValue;
end;

procedure TMap<TKey, TData>.FreeData(const AData: TData);
begin
  // might not do anything depending on generic Data Type
end;

constructor TMap<TKey, TData>.Create(AInternalSize: Cardinal);
begin
  inherited Create(AInternalSize);
  SetLength(FData, FInternalSize);
end;

destructor TMap<TKey, TData>.Destroy;
begin
  DelAll;
  inherited Destroy;
end;

function TMap<TKey, TData>.Get(AKey: TKey; out AData: TData): Boolean;
var
  Entry: THashEntry;
  Hash: Cardinal;
begin
  if CantIndex(AKey) then
    raise Exception.Create('Invalid HashTable-Index');

  Hash := GetKeyHash(AKey);
  if FData[Hash] = nil then // base entry doesn't exist > not found
    Exit(False);

  Entry := FData[Hash];
  while not KeysEqual(Entry.Key, AKey) do
  begin
    if Entry.Next = nil then // end reached > not found
      Exit(False);
    Entry := Entry.Next;
  end;
  // found
  AData := Entry.Data;
  Result := True;
end;

function TMap<TKey, TData>.HasKey(AKey: TKey): Boolean;
var
  _: TData;
begin
  Result := Get(AKey, _);
end;

procedure TMap<TKey, TData>.Del(AKey: TKey);
var
  Hash: Cardinal;
  Entry, PrevEntry: THashEntry;
begin
  Hash := GetKeyHash(AKey);
  Entry := FData[Hash];
  if Entry = nil then
    Exit; // already nil

  PrevEntry := nil;
  // find key in list
  while not KeysEqual(Entry.Key, AKey) do
  begin
    if Entry.Next = nil then // not found
      Exit;
    PrevEntry := Entry;
    Entry := Entry.Next;
  end;

  FreeData(Entry.Data);

  if PrevEntry <> nil then
    PrevEntry.Next := Entry.Next
  else
    FData[Hash] := Entry.Next;

  Entry.Free;
  Dec(FCount);
end;

function TMap<TKey, TData>.NextKeyCheck(AKey: TKey; out AOut: TKey): Boolean;
var
  Hash: Cardinal;
  Current: THashEntry;
begin
  Hash := GetKeyHash(AKey);
  // Find Entry
  Current := FData[Hash];
  while not KeysEqual(Current.Key, AKey) do
  begin
    Current := Current.Next;
    if Current = nil then
      Exit(False);
  end;

  // Find Next
  if Current.Next <> nil then
  begin
    AOut := Current.Next.Key;
    Exit(True);
  end;
  repeat
    Inc(Hash);
  until (Hash = FInternalSize) or (FData[Hash] <> nil);
  if Hash = FInternalSize then
    Exit(False);
  AOut := FData[Hash].Key;
  Result := True;
end;

function TMap<TKey, TData>.PrevKeyCheck(AKey: TKey; out AOut: TKey): Boolean;
var
  Hash: Cardinal;
  Current: THashEntry;
begin
  Hash := GetKeyHash(AKey);
  // Find Entry
  if FData[Hash] = nil then
    Exit(False);
  Current := FData[Hash];
  while not KeysEqual(Current.Key, AKey) do
  begin
    if (Current.Next <> nil) and KeysEqual(Current.Next.Key, AKey) then
    begin
      AOut := Current.Key;
      Exit(True)
    end
    else if Current.Next = nil then
      Exit(False);
    Current := Current.Next;
  end;

  // Find Prev
  while Hash > 0 do
  begin
    Dec(Hash);
    if FData[Hash] <> nil then
    begin
      Current := FData[Hash];
      while Current.Next <> nil do
        Current := Current.Next;
      AOut := Current.Key;
      Exit(True);
    end;
  end;
  Result := False;
end;

function TMap<TKey, TData>.NextKeyCheck(var AKey: TKey): Boolean;
var
  Tmp: TKey;
begin
  Tmp := AKey;
  Result := NextKeyCheck(Tmp, AKey);
  if not Result then
    AKey := Tmp;
end;

function TMap<TKey, TData>.PrevKeyCheck(var AKey: TKey): Boolean;
var
  Tmp: TKey;
begin
  Tmp := AKey;
  Result := PrevKeyCheck(Tmp, AKey);
  if not Result then
    AKey := Tmp;
end;

function TMap<TKey, TData>.HasNextKey(AKey: TKey): Boolean;
var
  _: TKey;
begin
  Result := NextKeyCheck(AKey, _);
end;

function TMap<TKey, TData>.HasPrevKey(AKey: TKey): Boolean;
var
  _: TKey;
begin
  Result := PrevKeyCheck(AKey, _);
end;

function TMap<TKey, TData>.NextKey(AKey: TKey): TKey;
begin
  if not NextKeyCheck(AKey, Result) then
    raise Exception.Create('No next Key!');
end;

function TMap<TKey, TData>.PrevKey(AKey: TKey): TKey;
begin
  if not NextKeyCheck(AKey, Result) then
    raise Exception.Create('No previous Key!');
end;

function TMap<TKey, TData>.FirstKeyCheck(out AOut: TKey): Boolean;
var
  I: Integer;
begin
  if Count = 0 then
    Exit(False);
  Result := True;
  for I := 0 to FInternalSize - 1 do
    if FData[I] <> nil then
    begin
      AOut := FData[I].Key;
      Exit;
    end;
end;

function TMap<TKey, TData>.FirstKey: TKey;
begin
  if not FirstKeyCheck(Result) then
    raise Exception.Create('No first Key!');
end;

function TMap<TKey, TData>.LastKey: TKey;
begin
  if not LastKeyCheck(Result) then
    raise Exception.Create('No last Key!');
end;

function TMap<TKey, TData>.LastKeyCheck(out AOut: TKey): Boolean;
var
  I: Cardinal;
  Current: THashEntry;
begin
  if Count = 0 then
    Exit(False);
  Result := True;
  for I := FInternalSize - 1 downto 0 do
  begin
    Current := FData[I];
    if Current <> nil then
    begin
      while Current.Next <> nil do
        Current := Current.Next;
      AOut := Current.Key;
      Exit;
    end;
  end;
end;

function TMap<TKey, TData>.NextData(AKey: TKey): TData;
begin
  Result := Data[NextKey(AKey)];
end;

function TMap<TKey, TData>.PrevData(AKey: TKey): TData;
begin
  Result := Data[PrevKey(AKey)];
end;

procedure TMap<TKey, TData>.DelAll;
var
  Next: THashEntry;
  I: Integer;
begin
  for I := 0 to FInternalSize - 1 do
  begin
    while FData[I] <> nil do
    begin
      Next := FData[I].Next;
      FreeData(FData[I].Data);
      FData[I].Free;
      FData[I] := Next;
    end;
  end;
end;

function TMap<TKey, TData>.GetEnumerator: TIterator;
begin
  Result := TIterator.Create(Self);
end;

{ THashTable<TKey, TData>.TIterator }

function TMap<TKey, TData>.TIterator.GetCurrent: TPair<TKey, TData>;
begin
  Result := TPair<TKey, TData>.Create(FEntry.Key, FEntry.Data);
end;

constructor TMap<TKey, TData>.TIterator.Create(AList: TMap<TKey, TData>);
begin
  FList := AList;
  FIndex := -1;
  FEntry := nil;
end;

function TMap<TKey, TData>.TIterator.MoveNext: Boolean;
begin
  if (FIndex = -1) or (FEntry.Next = nil) then
  begin
    // Move to next list
    repeat
      FIndex := FIndex + 1;
      if Cardinal(FIndex) = FList.FInternalSize then
        Exit(False);
      FEntry := FList.FData[FIndex];
    until (FEntry <> nil);
  end
  else
  begin
    FEntry := FEntry.Next;
  end;
  Result := True;
end;

{ TStringHashTable<TData> }

function TStringMap<TData>.GetKeyHash(AKey: String): Cardinal;
begin
  Result := GetHash(AKey, InternalSize);
end;

class function TStringMap<TData>.CantIndex(AKey: String): Boolean;
begin
  Result := AKey = '';
end;

class function TStringMap<TData>.KeysEqual(AKey1, AKey2: String): Boolean;
begin
  Result := AKey1 = AKey2;
end;

{ TStringObjectHashTable<TData> }

function TStringObjectMap<TData>.GetEntry(AKey: String): TData;
begin
  if not Get(AKey, Result) then
    Result := nil;
end;

procedure TStringObjectMap<TData>.FreeData(const AData: TData);
begin
  AData.Free;
end;

{ THashBase<TKey> }

constructor THashBase<TKey>.Create(AInternalSize: Cardinal);
begin
  if AInternalSize = 0 then
    raise Exception.Create('Internal Size for HashTable must be at least 1');
  FInternalSize := AInternalSize;
end;

class function THashBase<TKey>.CantIndex(AKey: TKey): Boolean;
begin
  Result := False;
end;

{ TObjectHashTable<TKey, TData> }

constructor TObjectMap<TKey, TData>.Create(AReferenceList: Boolean; AInternalSize: Cardinal);
begin
  inherited Create(AInternalSize);
  FReferenceList := AReferencelist;
end;

function TObjectMap<TKey, TData>.GetKeyHash(AKey: TKey): Cardinal;
begin
  Result := GetHash(TObject(AKey), FInternalSize);
end;

class function TObjectMap<TKey, TData>.CantIndex(AKey: TKey): Boolean;
begin
  Result := AKey = nil;
end;

class function TObjectMap<TKey, TData>.KeysEqual(AKey1, AKey2: TKey): Boolean;
begin
  Result := Pointer(AKey1) = Pointer(AKey2);
end;

procedure TObjectMap<TKey, TData>.FreeData(const AData: TData);
begin
  AData.Free;
end;

{ TObjectSet<T> }

function TObjectSet<T>.GetKeyHash(AKey: T): Cardinal;
begin
  Result := GetHash(TObject(AKey), FInternalSize);
end;

class function TObjectSet<T>.CantIndex(AKey: T): Boolean;
begin
  Result := AKey = nil;
end;

class function TObjectSet<T>.KeysEqual(AKey1, AKey2: T): Boolean;
begin
  Result := Pointer(AKey1) = Pointer(AKey2);
end;

procedure TObjectSet<T>.FreeData(const AData: T);
begin
  if not FReferenceList then
    AData.Free;
end;

constructor TObjectSet<T>.Create(AReferenceList: Boolean; AInternalSize: Cardinal);
begin
  inherited Create(AInternalSize);
  FReferenceList := AReferenceList;
end;

{ TArrayList<T> }

function TArrayList<T>.GetItem(AIndex: Integer): T;
begin
  RangeCheckException(AIndex);
  Result := FItems[AIndex];
end;

procedure TArrayList<T>.SetItem(AIndex: Integer; AValue: T);
begin
  RangeCheckException(AIndex);
  FreeData(FItems[AIndex]);
  FItems[AIndex] := AValue;
end;

procedure TArrayList<T>.Sort(AFunc: TCompareFunction<T>);
begin
  if Count > 1 then
    SortLR(AFunc, 0, Count - 1);
end;

procedure TArrayList<T>.Sort(AFunc: TCompareFunctionOfObject<T>);
begin
  if Count > 1 then
    SortLR(AFunc, 0, Count - 1);
end;

procedure TArrayList<T>.SortLR(ACompareFunc: TCompareFunctionOfObject<T>; ALeft, ARight: Integer);
var
  Pivot: T;
  L, R: Integer;
begin
  Pivot := FItems[(ALeft + ARight) div 2];
  L := ALeft;
  R := ARight;
  repeat
    while ACompareFunc(Pivot, FItems[L]) do
      Inc(L);
    while ACompareFunc(FItems[R], Pivot) do
      Dec(R);
    if L <= R then
    begin
      Swap(L, R);
      Inc(L);
      Dec(R);
    end;
  until L > R;
  if R > ALeft then
    SortLR(ACompareFunc, ALeft, R);
  if L < ARight then
    SortLR(ACompareFunc, L, ARight);
end;

procedure TArrayList<T>.SortLR(ACompareFunc: TCompareFunction<T>; ALeft, ARight: Integer);
var
  Pivot: T;
  L, R: Integer;
begin
  Pivot := FItems[(ALeft + ARight) div 2];
  L := ALeft;
  R := ARight;
  repeat
    while ACompareFunc(Pivot, FItems[L]) do
      Inc(L);
    while ACompareFunc(FItems[R], Pivot) do
      Dec(R);
    if L <= R then
    begin
      Swap(L, R);
      Inc(L);
      Dec(R);
    end;
  until L > R;
  if R > ALeft then
    SortLR(ACompareFunc, ALeft, R);
  if L < ARight then
    SortLR(ACompareFunc, L, ARight);
end;

constructor TArrayList<T>.Create(ASizeSteps: Integer);
begin
  FSizeSteps := ASizeSteps;
end;

function TArrayList<T>.Add(AElement: T): T;
begin
  if Count + 1 > Length(FItems) then
    SetLength(FItems, Length(FItems) + FSizeSteps);
  FItems[FCount] := AElement;
  Inc(FCount);
  Result := AElement;
end;

function TArrayList<T>.Insert(AElement: T; AIndex: Integer): T;
begin
  if Count + 1 > Length(FItems) then
    SetLength(FItems, Length(FItems) + FSizeSteps);
  Move(FItems[AIndex], FItems[AIndex + 1], SizeOf(T) * (Count - AIndex));
  FItems[AIndex] := AElement;
  Inc(FCount);
  Result := AElement;
end;

procedure TArrayList<T>.DelLast;
begin
  Del(Count - 1);
end;

procedure TArrayList<T>.DelAll;
var
  I: Integer;
begin
  for I := Count - 1 downto 0 do
    Del(I);
end;

procedure TArrayList<T>.Del(AIndex: Integer);
begin
  RangeCheckException(AIndex);
  FreeData(FItems[AIndex]);
  if Count - AIndex > 1 then
    Move(FItems[AIndex + 1], FItems[AIndex], SizeOf(T) * (Count - AIndex - 1));
  Dec(FCount);
  if Length(FItems) - FSizeSteps >= FCount then
    SetLength(FItems, Length(FItems) - FSizeSteps);
end;

procedure TArrayList<T>.Swap(A, B: Integer);
var
  Tmp: T;
begin
  RangeCheckException(A);
  RangeCheckException(B);
  Tmp := FItems[A];
  FItems[A] := FItems[B];
  FItems[B] := Tmp;
end;

function TArrayList<T>.EntryNotFound: T;
begin
  raise Exception.Create('Array Entry could not be found!');
  Result := EntryNotFound; // preventing a warning...
end;

function TArrayList<T>.FindFirstIndex(AFunc: TFindFunctionStatic<T>): Integer;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    if AFunc(FItems[I]) then
      Exit(I);
  Result := -1;
end;

function TArrayList<T>.FindFirstIndex(AFunc: TFindFunctionOfObject<T>): Integer;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    if AFunc(FItems[I]) then
      Exit(I);
  Result := -1;
end;

function TArrayList<T>.FindFirstIndex(AFunc: TFindFunctionClass<T>; ADoFree: Boolean): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to Count - 1 do
    if AFunc.Find(FItems[I]) then
      Result := I;
  if ADoFree then
    AFunc.Free;
end;

function TArrayList<T>.FindFirst(AFunc: TFindFunctionStatic<T>): T;
var
  I: Integer;
begin
  I := FindFirstIndex(AFunc);
  if I = -1 then
    Exit(EntryNotFound);
  Result := FItems[I];
end;

function TArrayList<T>.FindFirst(AFunc: TFindFunctionOfObject<T>): T;
var
  I: Integer;
begin
  I := FindFirstIndex(AFunc);
  if I = -1 then
    Exit(EntryNotFound);
  Result := FItems[I];
end;

function TArrayList<T>.FindFirst(AFunc: TFindFunctionClass<T>; ADoFree: Boolean): T;
var
  I: Integer;
begin
  I := FindFirstIndex(AFunc, ADoFree);
  if I = -1 then
    Exit(EntryNotFound);
  Result := FItems[I];
end;


function TArrayList<T>.FindLastIndex(AFunc: TFindFunctionStatic<T>): Integer;
var
  I: Integer;
begin
  for I := Count - 1 downto 0 do
    if AFunc(FItems[I]) then
      Exit(I);
  Result := -1;
end;

function TArrayList<T>.FindLastIndex(AFunc: TFindFunctionOfObject<T>): Integer;
var
  I: Integer;
begin
  for I := Count - 1 downto 0 do
    if AFunc(FItems[I]) then
      Exit(I);
  Result := -1;
end;

function TArrayList<T>.FindLastIndex(AFunc: TFindFunctionClass<T>; ADoFree: Boolean): Integer;
var
  I: Integer;
begin
  for I := Count - 1 downto 0 do
    if AFunc.Find(FItems[I]) then
      Exit(I);
  Result := -1;
  if ADoFree then
    AFunc.Free;
end;

function TArrayList<T>.FindLast(AFunc: TFindFunctionStatic<T>): T;
var
  I: Integer;
begin
  I := FindLastIndex(AFunc);
  if I = -1 then
    Exit(EntryNotFound);
  Result := FItems[I];
end;

function TArrayList<T>.FindLast(AFunc: TFindFunctionOfObject<T>): T;
var
  I: Integer;
begin
  I := FindLastIndex(AFunc);
  if I = -1 then
    Exit(EntryNotFound);
  Result := FItems[I];
end;


function TArrayList<T>.FindLast(AFunc: TFindFunctionClass<T>; ADoFree: Boolean): T;
var
  I: Integer;
begin
  I := FindLastIndex(AFunc, ADoFree);
  if I = -1 then
    Exit(EntryNotFound);
  Result := FItems[I];
end;

function TArrayList<T>.FindIndexAsArray(AFunc: TFindFunctionStatic<T>): TIntArray;
var
  I: Integer;
begin
  Result := TIntArray.Create;
  for I := 0 to Count - 1 do
    if AFunc(FItems[I]) then
      Result.Add(I);
end;

function TArrayList<T>.FindIndexAsArray(AFunc: TFindFunctionOfObject<T>): TIntArray;
var
  I: Integer;
begin
  Result := TIntArray.Create;
  for I := 0 to Count - 1 do
    if AFunc(FItems[I]) then
      Result.Add(I);
end;

function TArrayList<T>.FindIndexAsArray(AFunc: TFindFunctionClass<T>; ADoFree: Boolean): TIntArray;
var
  I: Integer;
begin
  Result := TIntArray.Create;
  for I := 0 to Count - 1 do
    if AFunc.Find(FItems[I]) then
      Result.Add(I);
  if ADoFree then
    AFunc.Free;
end;

function TArrayList<T>.FindAsArray(AFunc: TFindFunctionStatic<T>): TArrayList<T>;
var
  I: Integer;
begin
  Result := TArrayList<T>.Create;
  for I := 0 to Count - 1 do
    if AFunc(FItems[I]) then
      Result.Add(FItems[I]);
end;

function TArrayList<T>.FindAsArray(AFunc: TFindFunctionOfObject<T>): TArrayList<T>;
var
  I: Integer;
begin
  Result := TArrayList<T>.Create;
  for I := 0 to Count - 1 do
    if AFunc(FItems[I]) then
      Result.Add(FItems[I]);
end;

function TArrayList<T>.FindAsArray(AFunc: TFindFunctionClass<T>; ADoFree: Boolean): TArrayList<T>;
var
  I: Integer;
begin
  Result := TArrayList<T>.Create;
  for I := 0 to Count - 1 do
    if AFunc.Find(FItems[I]) then
      Result.Add(FItems[I]);
  if ADoFree then
    AFunc.Free;
end;

function TArrayList<T>.Copy: TArrayList<T>;
var
  I: Integer;
begin
  Result := TArrayList<T>.Create;
  for I := 0 to Count - 1 do
    Result.Add(FItems[I]);
end;

function TArrayList<T>.Empty: Boolean;
begin
  Result := Count = 0;
end;

function TArrayList<T>.First: T;
begin
  Result := FItems[0];
end;

procedure TArrayList<T>.FreeData(const AData: T);
begin
  // Nothing to free
end;

function TArrayList<T>.Last: T;
begin
  Result := FItems[Count - 1];
end;

function TArrayList<T>.Ptr: Pointer;
begin
  Result := FItems;
end;

function TArrayList<T>.GetEnumerator(AAutoFree: Boolean): TIterator;
begin
  Result := TIterator.Create(Self, FIterReversed, AAutoFree);
  FIterReversed := False;
end;

function TArrayList<T>.IterReversed: TArrayList<T>;
begin
  FIterReversed := True;
  Result := Self;
end;

procedure TArrayList<T>.RangeCheckException(AIndex: Integer);
begin
  if not RangeCheck(AIndex) then
    Exception.Create('TArrayList index out of bounds!');
end;

function TArrayList<T>.RangeCheck(AIndex: Integer): Boolean;
begin
  Result := (AIndex >= 0) and (AIndex < Count);
end;

{ TNotifyArray<T> }

procedure TNotifyArray<T>.SetItem(AIndex: Integer; AValue: T);
begin
  inherited SetItem(AIndex, AValue);
  FChanged := True;
end;

procedure TNotifyArray<T>.NotifyChanges;
begin
  FChanged := False;
end;

{ TClassMap }

function TClassMap<T>.GetKeyHash(AKey: TClass): Cardinal;
begin
  Result := GetHash(TObject(AKey), FInternalSize);
end;

class function TClassMap<T>.CantIndex(AKey: TClass): Boolean;
begin
  Result := AKey = nil;
end;

class function TClassMap<T>.KeysEqual(AKey1, AKey2: TClass): Boolean;
begin
  Result := Pointer(AKey1) = Pointer(AKey2);
end;

{ TCardinalSet }

function TCardinalSet.GetKeyHash(AKey: Cardinal): Cardinal;
begin
  Result := AKey mod FInternalSize;
end;

class function TCardinalSet.CantIndex(AKey: Cardinal): Boolean;
begin
  Result := False;
end;

class function TCardinalSet.KeysEqual(AKey1, AKey2: Cardinal): Boolean;
begin
  Result := AKey1 = AKey2;
end;

{ TIntArray }

function TIntArray.Sum: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I in Self do
    Result := Result + I;
end;

function TIntArray.ToString: String;
var
  I: Integer;
begin
  if Count = 0 then
    Exit('Empty');
  Result := IntToStr(FItems[0]); // casts only necessary for delphi quick-syntaxcheck
  for I := 1 to Count - 1 do
    Result := Result + ', ' + IntToStr(FItems[I]);
end;

{ TTags }

function TTags.GetKeyHash(AKey: String): Cardinal;
begin
  Result := GetHash(AKey, FInternalSize);
end;

class function TTags.CantIndex(AKey: String): Boolean;
begin
  Result := AKey = '';
end;

class function TTags.KeysEqual(AKey1, AKey2: String): Boolean;
begin
  Result := AKey1 = AKey2;
end;

{ TSet<T>.TIterator }

function TSet<T>.TIterator.GetCurrent: T;
begin
  Result := FEntry.Data;
end;

constructor TSet<T>.TIterator.Create(AList: TSet<T>);
begin
  FList := AList;
  FIndex := -1;
  FEntry := nil;
end;

function TSet<T>.TIterator.MoveNext: Boolean;
begin
  if (FIndex = -1) or (FEntry.Next = nil) then
  begin
    // Move to next list
    repeat
      FIndex := FIndex + 1;
      if Cardinal(FIndex) = FList.FInternalSize then
        Exit(False);
      FEntry := FList.FTags[FIndex];
    until (FEntry <> nil);
  end
  else
  begin
    FEntry := FEntry.Next;
  end;
  Result := True;
end;

{ TSet<T> }

function TSet<T>.GetElement(S: T): Boolean;
var
  Entry: TEntry;
begin
  if CantIndex(S) then
    raise Exception.Create('Invalid Set-Index');

  Entry := FTags[GetKeyHash(S)];
  while Entry <> nil do
  begin
    if KeysEqual(Entry.Data, S) then
      Exit(True);
    Entry := Entry.Next;
  end;
  Result := False;
end;

procedure TSet<T>.SetElement(S: T; AValue: Boolean);
var
  Hash: Cardinal;
  Entry, EntryToDelete: TEntry;
begin
  if CantIndex(S) then
    raise Exception.Create('Invalid Set-Index');

  Hash := GetKeyHash(S);
  if FTags[Hash] = nil then
  begin
    if AValue then
    begin
      // create new base entry
      FTags[Hash] := TEntry.Create;
      FTags[Hash].Data := S;
      Inc(FCount);
    end;
    // else doesn't exist in the first place
  end
  else
  begin
    // first
    if KeysEqual(FTags[Hash].Data, S) then
    begin
      if not AValue then
      begin
        // delete first
        Entry := FTags[Hash].Next;
        FreeData(FTags[Hash].Data);
        FTags[Hash].Free;
        FTags[Hash] := Entry;
        Dec(FCount);
      end;
      Exit;
    end;
    // rest
    Entry := FTags[Hash];
    while Entry.Next <> nil do
    begin
      if KeysEqual(Entry.Next.Data, S) then
      begin
        if not AValue then
        begin
          // delete in rest
          EntryToDelete := Entry.Next;
          Entry.Next := Entry.Next.Next;
          FreeData(EntryToDelete.Data);
          EntryToDelete.Free;
          Dec(FCount);
        end;
        // else exists already
        Exit;
      end;
      Entry := Entry.Next;
    end;
    // not found
    if AValue then
    begin
      // add
      Entry.Next := TEntry.Create;
      Entry.Next.Data := S;
      Inc(FCount);
    end;
    // else doesn't exist in the first place
  end;
end;

procedure TSet<T>.FreeData(const AData: T);
begin
  // might not do anything depending on generic Data Type
end;

constructor TSet<T>.Create(AInternalSize: Cardinal);
begin
  inherited Create(AInternalSize);
  SetLength(FTags, FInternalSize);
end;

destructor TSet<T>.Destroy;
begin
  Clear;
  inherited;
end;

procedure TSet<T>.Add(S: T);
begin
  SetElement(S, True);
end;

procedure TSet<T>.Del(S: T);
begin
  SetElement(S, False);
end;

procedure TSet<T>.Clear;
var
  I: Integer;
  Next: TEntry;
begin
  for I := 0 to FInternalSize - 1 do
  begin
    if FCount = 0 then
      Exit;
    while FTags[I] <> nil do
    begin
      Next := FTags[I].Next;
      FTags[I].Free;
      FTags[I] := Next;
      Dec(FCount);
    end;
  end;
end;

procedure TSet<T>.Assign(ATagList: TSet<T>);
var
  S: T;
begin
  Clear;
  for S in ATagList do
    Self[S] := True;
end;

function TSet<T>.GetEnumerator: TIterator;
begin
  Result := TIterator.Create(Self);
end;

{ TObjectStack }

constructor TObjectStack<T>.Create(AReferenceList: Boolean);
begin
  FReferenceList := AReferenceList;
end;

destructor TObjectStack<T>.Destroy;
begin
  while Pop do;
  inherited Destroy;
end;

function TObjectStack<T>.Push(AElement: T): T;
begin
  FTop := TItem.Create(AElement, FTop);
  Result := FTop.Data;
end;

function TObjectStack<T>.Pop: Boolean;
var
  Old: TItem;
begin
  if FTop = nil then
    Exit(False);
  Old := FTop;
  if not FReferenceList then
    FTop.Data.Free;
  FTop := FTop.Prev;
  Result := FTop <> nil;
  Old.Free;
end;

function TObjectStack<T>.Top: T;
begin
  Result := FTop.Data;
end;

function TObjectStack<T>.Copy: TObjectStack<T>;
var
  A, B: TItem;
begin
  Result := TObjectStack<T>.Create(True);
  if FTop = nil then
    Exit;
  A := TItem.Create(FTop.Data, nil);
  Result.FTop := A;
  B := FTop;
  while B.Prev <> nil do
  begin
    B := B.Prev;
    A.Prev := TItem.Create(B.Data, nil);
    A := A.Prev;
  end;
end;

{ TObjectArray }

constructor TObjectArray<T>.Create(AReferenceList: Boolean; ASizeSteps: Integer);
begin
  FReferenceList := AReferenceList;
  FSizeSteps := ASizeSteps;
end;

destructor TObjectArray<T>.Destroy;
begin
  DelAll;
  inherited;
end;

function TObjectArray<T>.FindAsObjectArray(AFunc: TFindFunctionStatic<T>): TObjectArray<T>;
var
  I: Integer;
begin
  Result := TObjectArray<T>.Create(True);
  for I := 0 to Count - 1 do
    if AFunc(FItems[I]) then
      Result.Add(FItems[I]);
end;

function TObjectArray<T>.FindAsObjectArray(AFunc: TFindFunctionOfObject<T>): TObjectArray<T>;
var
  I: Integer;
begin
  Result := TObjectArray<T>.Create(True);
  for I := 0 to Count - 1 do
    if AFunc(FItems[I]) then
      Result.Add(FItems[I]);
end;

function TObjectArray<T>.FindAsObjectArray(AFunc: TFindFunctionClass<T>; ADoFree: Boolean = True): TObjectArray<T>;
var
  I: Integer;
begin
  Result := TObjectArray<T>.Create(True);
  for I := 0 to Count - 1 do
    if AFunc.Find(FItems[I]) then
      Result.Add(FItems[I]);
  if ADoFree then
    AFunc.Free;
end;

function TObjectArray<T>.FindObject(AData: T): Integer;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    if Pointer(AData) = Pointer(FItems[I]) then
      Exit(I);
  Result := -1;
end;

procedure TObjectArray<T>.DelObject(AData: T);
begin
  Del(FindObject(AData));
end;

function TObjectArray<T>.Copy: TArrayList<T>;
var
  I: Integer;
begin
  Result := TObjectArray<T>.Create(True);
  for I := 0 to Count - 1 do
    Result.Add(FItems[I]);
end;

function TObjectArray<T>.First: T;
begin
  if Count > 0 then
    Exit(inherited First);
  Result := nil;
end;

function TObjectArray<T>.Last: T;
begin
  if Count > 0 then
    Exit(inherited Last);
  Result := nil;
end;

procedure TObjectArray<T>.FreeData(const AData: T);
begin
  if not FReferenceList then
    AData.Free;
end;

function TObjectArray<T>.EntryNotFound: T;
begin
  Result := nil;
end;

function TObjectArray<T>.ToString: String;
var
  I: Integer;
begin
  if Count = 0 then
    Exit('Empty');
  Result := T(FItems[0]).ToString; // casts only necessary for delphi quick-syntaxcheck
  for I := 1 to Count - 1 do
    Result := Result + ', ' + T(FItems[I]).ToString;
end;

{ TAnsiStringObjectMap<TData> }

function TAnsiStringObjectMap<TData>.GetEntry(AKey: AnsiString): TData;
begin
  if not Get(AKey, Result) then
    Result := nil;
end;

procedure TAnsiStringObjectMap<TData>.FreeData(const AData: TData);
begin
  AData.Free;
end;

{ TAnsiStringMap<TData> }

class function TAnsiStringMap<TData>.CantIndex(AKey: AnsiString): Boolean;
begin
  Result := AKey = '';
end;

function TAnsiStringMap<TData>.GetKeyHash(AKey: AnsiString): Cardinal;
begin
  Result := GetHash(AKey, FInternalSize);
end;

class function TAnsiStringMap<TData>.KeysEqual(AKey1, AKey2: AnsiString): Boolean;
begin
  Result := AKey1 = AKey2;
end;

{ TArrayList<T>.TIterator }

constructor TArrayList<T>.TIterator.Create(AList: TArrayList<T>; AReversed, AAutoFree: Boolean);
begin
  FList := AList;
  FReversed := AReversed;
  FAutoFree := AAutoFree;
  if FReversed then
    FCurrent := FList.Count
  else
    FCurrent := -1;
end;

function TArrayList<T>.TIterator.GetCurrent: T;
begin
  Result := FList[FCurrent];
end;

function TArrayList<T>.TIterator.MoveNext: Boolean;
begin
  if FRemoveFlag then
  begin
    FList.Del(FCurrent);
    FRemoveFlag := False;
  end
  else if not FReversed then
    Inc(FCurrent);

  if FReversed then
  begin
    Dec(FCurrent);
    Result := FCurrent <> -1;
  end
  else
    Result := FCurrent <> FList.Count;

  if not Result and FAutoFree then
    Free;
end;

procedure TArrayList<T>.TIterator.RemoveCurrent;
begin
  FRemoveFlag := True;
end;

end.

