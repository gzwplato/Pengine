unit Sorting;

interface

uses
  Classes, SysUtils;

type

  { TBinaryTreeSorter }

  TBinaryTreeSorter = class abstract
  protected
    type
      TNode = record
        Left, Right: ^TNode;
        Data: TObject;
      end;
      PNode = ^TNode;

  private
    FRoot: PNode;

    procedure AddToNode(var Node: PNode; Entry: TObject);
    procedure SortedExecuteNode(Node: PNode);

    procedure FreeNode(var Node: PNode);

  protected
    class function Compare(A, B: TObject): Boolean; virtual; abstract;
    class procedure ExecuteEntry(Entry: TObject); virtual; abstract;

  public
    constructor Create;
    destructor Destroy; override;

    procedure AddToTree(Entry: TObject);

    procedure SortedExecute;
  end;

  { TQuickSorter }

  TQuickSorter = class abstract
  protected
    function Compare(A, B: TObject): Boolean; virtual; abstract;
  public
    procedure Sort(var Data: array of TObject);
  end;

implementation

{ TQuickSorter }

procedure TQuickSorter.Sort(var Data: array of TObject);

  procedure DoQuickSort(var A: array of TObject; iLo, iHi: Integer);
  var
    Lo, Hi: Integer;
    Mid, T: TObject;
  begin
    Lo := iLo;
    Hi := iHi;
    Mid := A[(Lo + Hi) div 2];
    repeat
      while Compare(Mid, A[Lo]) do
        Inc(Lo);
      while Compare(A[Hi], Mid) do
        Dec(Hi);
      if Lo <= Hi then
      begin
        T := A[Lo];
        A[Lo] := A[Hi];
        A[Hi] := T;
        Inc(Lo);
        Dec(Hi);
      end;
    until Lo > Hi;

    if Hi > iLo then
      DoQuickSort(A, iLo, Hi);
    if Lo < iHi then
      DoQuickSort(A, Lo, iHi);
  end;

begin
  if Length(Data) > 1 then
    DoQuickSort(Data, 0, Length(Data) - 1);
end;

{ TBinaryTreeSorter }

procedure TBinaryTreeSorter.AddToNode(var Node: PNode; Entry: TObject);
begin
  if Node = nil then
  begin
    Node := AllocMem(SizeOf(TNode));
    Node^.Data := Entry;
  end
  else
  begin
    if Compare(Entry, Node^.Data) then
      AddToNode(Node^.Right, Entry)
    else
      AddToNode(Node^.Left, Entry);
  end;
end;

procedure TBinaryTreeSorter.SortedExecuteNode(Node: PNode);
begin
  if Node^.Left <> nil then
    SortedExecuteNode(Node^.Left);
  ExecuteEntry(Node^.Data);
  if Node^.Right <> nil then
    SortedExecuteNode(Node^.Right);
end;

procedure TBinaryTreeSorter.FreeNode(var Node: PNode);
begin
  if Node^.Left <> nil then
    FreeNode(Node^.Left);
  if Node^.Right <> nil then
    FreeNode(Node^.Right);
  FreeMem(Node);
end;

constructor TBinaryTreeSorter.Create;
begin
  FRoot := AllocMem(SizeOf(TNode));
end;

destructor TBinaryTreeSorter.Destroy;
begin
  FreeNode(FRoot);
  inherited Destroy;
end;

procedure TBinaryTreeSorter.AddToTree(Entry: TObject);
begin
  if FRoot^.Data = nil then
    FRoot^.Data := Entry
  else
    AddToNode(FRoot, Entry);
end;

procedure TBinaryTreeSorter.SortedExecute;
begin
  SortedExecuteNode(FRoot);
end;

end.

