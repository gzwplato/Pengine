unit Physics2D;

interface

uses
  VectorGeometry, Lists;

type

  TPhys2Object = class;

  TPhys2World = class
  private
    FHomoGravity: TGVector2;
    FCircularGravity: TArray<TGVector2>;

    FObjects: TArray<TPhys2Object>;

  public

  end;

  TPhys2Object = class abstract
  private
    FWorld: TPhys2World;

    function GetCenter: TGVector2; virtual; abstract;
    function GetRotation: Single; virtual; abstract;
    procedure SetCenter(const Value: TGVector2); virtual; abstract;
    procedure SetRotation(const Value: Single); virtual; abstract;

  public
    property World: TPhys2World read FWorld;

    property Center: TGVector2 read GetCenter write SetCenter;
    property Rotation: Single read GetRotation write SetRotation;

    procedure ApplyForceRel();
    procedure ApplyForceAbs();

  end;

  TPhys2Ball = class(TPhys2Object)
  private

  public

  end;

  TPhys2Triangle = class(TPhys2Object)
  private

  public

  end;

implementation

end.
