unit SimpleHuffman;

interface

uses
  SysUtils, Classes,
  AuxTypes, AuxClasses;

{===============================================================================
    Library-specific exceptions
===============================================================================}
type
  ESHException = class(Exception);

  ESHInvalidValue     = class(ESHException);
  ESHInvalidState     = class(ESHException);
  ESHInvalidOperation = class(ESHException);
  ESHIndexOutOfBounds = class(ESHException);
  ESHBufferTooSmall   = class(ESHException);

{===============================================================================
--------------------------------------------------------------------------------
                                  THuffmanTree
--------------------------------------------------------------------------------
===============================================================================}
const
  SH_HUFFTREE_LIST_BYTENODES = 0;
  SH_HUFFTREE_LIST_TREENODES = 1;

type
  // 256 bits, anyway what is the worst-case scenario?
  TSHBitSequenceData = packed array[0..31] of UInt8;

  TSHBitSequence = record
    Length: Integer;
    Data:   TSHBitSequenceData;
  end;

  PSHHuffmanTreeNode = ^TSHHuffmanTreeNode;
  TSHHuffmanTreeNode = record
    ByteNode:       Boolean;
    ByteIndex:      UInt8;
    TreeIndex:      Integer;
    Frequency:      Int64;
    BitSequence:    TSHBitSequence;
    ParentNode:     PSHHuffmanTreeNode;
    ParentPath:     Boolean;
    SubNodes:       array[Boolean] of PSHHuffmanTreeNode;
    NodeSaved:      Boolean;
  end;

{===============================================================================
    THuffmanTree - class declaration
===============================================================================}
type
  THuffmanTree = class(TCustomMultiListObject)
  protected
    fByteNodes:     array[UInt8] of TSHHuffmanTreeNode;
    fTreeNodes:     array of PSHHuffmanTreeNode;
    fTreeNodeCount: Integer;
    fRootTreeNode:  PSHHuffmanTreeNode;
    // getters, setters
    Function GetByteNode(Index: Integer): TSHHuffmanTreeNode; virtual;
    Function GetFrequency(Index: Integer): Int64; virtual;
    procedure SetFrequency(Index: Integer; Value: Int64); virtual;
    Function GetBitSequence(Index: Integer): TSHBitSequence; virtual;
    Function GetNodeSaved(Index: Integer): Boolean; virtual;
    procedure SetNodeSaved(Index: Integer; Value: Boolean); virtual;
    Function GetTreeNode(Index: Integer): TSHHuffmanTreeNode; virtual;
    // inherited protected list methods
    Function GetCapacity(List: Integer): Integer; override;
    procedure SetCapacity(List,Value: Integer); override;
    Function GetCount(List: Integer): Integer; override;
    procedure SetCount(List,Value: Integer); override;
    // tree building
    Function AddTreeNode(Node: PSHHuffmanTreeNode): Integer; virtual;
    // streaming
    Function StreamingSize(out FreqBits: Integer): TMemSize; overload; virtual;
    // initialization and finalization
    procedure ClearByteNodes; virtual;
    procedure ClearTreeNodes; virtual;
    procedure Initialize; virtual;
    procedure Finalize; virtual;
  public
    constructor Create;
    destructor Destroy; override;
    // inherited public list methods
    Function LowIndex(List: Integer): Integer; override;
    Function HighIndex(List: Integer): Integer; override;
    // new list methods
    Function LowByteNodeIndex: Integer; virtual;
    Function HighByteNodeIndex: Integer; virtual;
    Function CheckByteNodeIndex(Index: UInt8): Boolean; virtual;
    Function LowTreeNodeIndex: Integer; virtual;
    Function HighTreeNodeIndex: Integer; virtual;
    Function CheckTreeNodeIndex(Index: Integer): Boolean; virtual;
    // tree methods
    Function IncreaseFrequency(ByteIndex: UInt8): Int64; virtual;
    procedure BuildTree(Frequencies: array of Int64); virtual;
    procedure ConstructTree; virtual;
    procedure ClearTree; virtual;
    Function IsReadyTree: Boolean; virtual;
    // set TreeNodeIndex to an invalid (eg. negative) value before first call
    Function TraverseTree(BitPath: Boolean; var TreeNodeIndex: Integer): Boolean; virtual;
    // streaming (saving, loading)
    Function StreamingSize: TMemSize; overload; virtual;
    procedure SaveToBuffer(out Buffer; Size: TMemSize); virtual;
    procedure SaveToStream(Stream: TStream); virtual;
    procedure SaveToFile(const FileName: String); virtual;
    procedure LoadFromBuffer(const Buffer; Size: TMemSize); virtual;
    procedure LoadFromStream(Stream: TStream); virtual;
    procedure LoadFromFile(const FileName: String); virtual;
    // other
    Function IsSame(Tree: THuffmanTree): Boolean; virtual;
    procedure Foo;
    // properties
  {
    Use tree node indices (eg. LowTreeNodeIndex) for TreeNodes, for all other
    array properties use byte indices (LowByteNodeIndex, ...).
  }
    property ByteNodes[Index: Integer]: TSHHuffmanTreeNode read GetByteNode; default;
    property Frequencies[Index: Integer]: Int64 read GetFrequency write SetFrequency;
    property BitSequences[Index: Integer]: TSHBitSequence read GetBitSequence;
    property NodeSaved[Index: Integer]: Boolean read GetNodeSaved write SetNodeSaved;
    property TreeNodes[Index: Integer]: TSHHuffmanTreeNode read GetTreeNode;
    property ByteNodeCount: Integer index SH_HUFFTREE_LIST_BYTENODES read GetCount;
    property TreeNodeCount: Integer index SH_HUFFTREE_LIST_TREENODES read GetCount;
  end;

{===============================================================================
--------------------------------------------------------------------------------
                                  THuffmanBase
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    THuffmanBase - class declaration
===============================================================================}
type
  THuffmanBase = class(TCustomObject)
  protected
    fHuffmanTree:       THuffmanTree;
    fStreamBufferSize:  TMemSize;
    fUncompressedSize:  Int64;
    fCompressedSize:    Int64;
    fCompressionRatio:  Double;
    fBreakProcessing:   Boolean;
    procedure Initialize; virtual;
    procedure Finalize; virtual;
  public
    constructor Create;
    destructor Destroy; override;
    Function BreakProcessing: Boolean; virtual;
    property HuffmanTree: THuffmanTree read fHuffmanTree;
    property StreamBufferSize: TMemSize read fStreamBufferSize write fStreamBufferSize;
    property UncompressedSize: Int64 read fUncompressedSize;
    property CompressedSize: Int64 read fCompressedSize;
    property CompressionRatio: Double read fCompressionRatio;
  end;


{===============================================================================
--------------------------------------------------------------------------------
                                 THuffmanEncoder
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    THuffmanEncoder - class declaration
===============================================================================}
type
  THuffmanEncoder = class(THuffmanBase)
  protected
    fScanInitialized:         Boolean;
    fScanFinalized:           Boolean;
    fEncodeInitialized:       Boolean;
    fEncodeFinalized:         Boolean;
    fScanProgressCallback:    TFloatCallback;
    fScanProgressEvent:       TFloatEvent;
    fEncodeProgressCallback:  TFloatCallback;
    fEncodeProgressEvent:     TFloatEvent;
    fProgressCallback:        TFloatCallback;
    fProgressEvent:           TFloatEvent;
    procedure DoScanProgress(Progress: Double); virtual;
    procedure DoEncodeProgress(Progress: Double); virtual;
    procedure Initialize; override;
  public
    // scanning
    procedure ScanInit; virtual;
    procedure ScanUpdate(const Buffer; Size: TMemSize); virtual;
    Function ScanFinal(const Buffer; Size: TMemSize): Int64; overload; virtual;
    Function ScanFinal: Int64; overload; virtual;
    // scanning macros
    Function ScanMemory(Memory: Pointer; Size: TMemSize): Int64; virtual;
    Function ScanBuffer(const Buffer; Size: TMemSize): Int64; virtual;
    Function ScanAnsiString(const Str: AnsiString): Int64; virtual;
    Function ScanWideString(const Str: WideString): Int64; virtual;
    Function ScanString(const Str: String): Int64; virtual;
    Function ScanStream(Stream: TStream; Count: Int64 = -1): Int64; virtual;
    Function ScanFile(const FileName: String): Int64; virtual;
    // encoding
    procedure EncodeInit; virtual;
    procedure EncodeUpdate(const BufferIn; var SizeIn: TMemSize; out BufferOut; var SizeOut: TMemSize); virtual;
    procedure EncodeFinal(const BufferIn; var SizeIn: TMemSize; out BufferOut; var SizeOut: TMemSize); overload; virtual;
    procedure EncodeFinal(out BufferOut; var SizeOut: TMemSize); overload; virtual;
    // encoding macros
    //procedure EncodeMemory(MemoryIn: Pointer; SizeIn: TMemSize; MemoryOut: Pointer; SizeOut: TMemSize); virtual;
    //procedure EncodeBuffer(const BufferIn; SizeIn: TMemSize; out MemoryOut; SizeOut: TMemSize); virtual;
    //procedure EncodeAnsiString(const StrIn: AnsiString; out StrOut: AnsiString); virtual;
    //procedure EncodeWideString(const StrIn: WideString; out StrOut: WideString); virtual;
    //procedure EncodeString(const StrIn: String; out StrOut: String); virtual;
    //procedure EncodeStream(StreamIn: TStream; Count: Int64 = -1; StreamOut: Stream); virtual;
    //procedure EncodeFile(const FileNameIn,FileNameOut: String); virtual;
    // properties
    property OnScanProgressCallback: TFloatCallback read fScanProgressCallback write fScanProgressCallback;
    property OnScanProgressEvent: TFloatEvent read fScanProgressEvent write fScanProgressEvent;
    property OnScanProgress: TFloatEvent read fScanProgressEvent write fScanProgressEvent;
    property OnEncodeProgressCallback: TFloatCallback read fEncodeProgressCallback write fEncodeProgressCallback;
    property OnEncodeProgressEvent: TFloatEvent read fEncodeProgressEvent write fEncodeProgressEvent;
    property OnEncodeProgress: TFloatEvent read fEncodeProgressEvent write fEncodeProgressEvent;
  {
    Following are reporting progress of scanning in interval <0.0,1.0> and progress
    of encoding in interval <1.0,2.0>.
  }
    property OnProgressCallback: TFloatCallback read fProgressCallback write fProgressCallback;
    property OnProgressEvent: TFloatEvent read fProgressEvent write fProgressEvent;
    property OnProgress: TFloatEvent read fProgressEvent write fProgressEvent;
  end;

{===============================================================================
--------------------------------------------------------------------------------
                                 THuffmanDecoder
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    THuffmanDecoder - class declaration
===============================================================================}
type
  THuffmanDecoder = class(THuffmanBase)
  protected
  public
  end;

implementation

uses
  Math,
  BitOps, StrRect, StaticMemoryStream;

{===============================================================================
    Auxiliary functions
===============================================================================}

procedure PutBitsAndMoveDest(var Destination: PUInt8; DstBitOffset: TMemSize; Source: PUInt8; BitCount: TMemSize);
var
  Mask:   UInt8;
  Buffer: UInt8;
begin
{
  This function assumes that destination and source are at completely different
  memory locations and DstBitOffset is in interval <0,7>.
}
If (DstBitOffset <> 0) or ((BitCount and 7) <> 0) then
  begin
    // arbitrary bitstring or bit position
    // copy full octets
    If DstBitOffset <> 0 then
      begin
        Mask := UInt8(UInt8($FF) shl DstBitOffset);
        while BitCount >= 8 do
          begin
            Buffer := Source^;
            Destination^ := (Destination^ and not Mask) or UInt8(Buffer shl DstBitOffset);
            Inc(Destination);
            Destination^ := (Destination^ and Mask) or (Buffer shr (8 - DstBitOffset));
            // do NOT increase destination again
            Inc(Source);
            Dec(BitCount,8);
          end;
      end
    else
      begin
        while BitCount >= 8 do
          begin
            Destination^ := Source^;
            Inc(Destination);
            Inc(Source);
            Dec(BitCount,8);
          end;
      end;
    // copy remaining bits, if any
    If BitCount > 0 then
      begin
        Buffer := Source^;
        If BitCount > (8 - DstBitOffset) then
          begin
            // writing into two bytes (note that if here, DstBitOffset cannot be 0)
            Destination^ := (Destination^ and {Mask}(UInt8($FF) shr (8 - DstBitOffset))) or UInt8(Buffer shl DstBitOffset);
            Inc(Destination);
            Mask := UInt8(UInt8($FF) shl (BitCount + DstBitOffset - 8));
            Destination^ := (Destination^ and Mask) or ((Buffer shr (8 - DstBitOffset)) and not Mask);
          end
        else
          begin
            // writing into only one byte
            Mask := UInt8(UInt8($FF) shl DstBitOffset) and (UInt8($FF) shr (8 - DstBitOffset - BitCount));
            Destination^ := (Destination^ and not Mask) or (UInt8(Buffer shl DstBitOffset) and Mask);
            If (8 - DstBitOffset - BitCount) <= 0 then
              Inc(Destination);
          end;
      end;
  end
else
  begin
    // integral bytes on byte boundary
    Move(Source^,Destination^,BitCount shr 3);
    Inc(Destination,BitCount shr 3);
  end;
end;

//------------------------------------------------------------------------------

Function LoadFrequencyBits(var Source: PUInt8; SrcBitOffset,BitCount: TMemSize): Int64;
var
  DstBitOffset: TMemSize;
begin
// This function assumes that SrcBitOffset is in interval <0,7>.
If BitCount < 64 then
  begin
    If BitCount > 0 then
      begin
        If SrcBitOffset <> 0 then
          begin
            If BitCount >= (8 - SrcBitOffset) then
              begin
                Result := Source^ shr SrcBitOffset;
                Inc(Source);
                Dec(BitCount,8 - SrcBitOffset);
                DstBitOffset := 8 - SrcBitOffset;
                while BitCount >= 8 do
                  begin
                    Result := Result or (Int64(Source^) shl DstBitOffset);
                    Dec(BitCount,8);
                    Inc(Source);
                    Inc(DstBitOffset,8);
                  end;
                If BitCount > 0 then
                  Result := Result or (Int64(Source^ and (UInt8($FF) shr (8 - BitCount))) shl DstBitOffset);
              end
            else Result := (Source^ shr SrcBitOffset) and (UInt8($FF) shr (8 - BitCount));
          end
        else
          begin
            Move(Source^,Result,(BitCount + 7) shr 3);
            // mask bits that are not supposed to be in the result
          {$IFDEF ENDIAN_BIG}
            Result := Int64(SwapEndian(UInt64(Result))) and (Int64($FFFFFFFFFFFFFFFF) shr (64 - BitCount));
          {$ELSE}
            Result := Result and (Int64($FFFFFFFFFFFFFFFF) shr (64 - BitCount));
          {$ENDIF}
            Inc(Source,BitCount shr 3);          
          end;
      end
    else Result := 0;
  end
else raise ESHInvalidValue.CreateFmt('LoadFrequencyBits: Invalid value of frequency bits (%d).',[BitCount]);
end;

{===============================================================================
--------------------------------------------------------------------------------
                                  THuffmanTree                                  
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    THuffmanTree - class implementation
===============================================================================}
{-------------------------------------------------------------------------------
    THuffmanTree - protected methods
-------------------------------------------------------------------------------}

Function THuffmanTree.GetByteNode(Index: Integer): TSHHuffmanTreeNode;
begin 
If CheckByteNodeIndex(Index) then
  Result := fByteNodes[UInt8(Index)]
else
  raise ESHIndexOutOfBounds.CreateFmt('THuffmanTree.GetByteNode: Index (%d) ouf of bounds.',[Index]);
end;

//------------------------------------------------------------------------------

Function THuffmanTree.GetFrequency(Index: Integer): Int64;
begin
If CheckByteNodeIndex(Index) then
  Result := fByteNodes[UInt8(Index)].Frequency
else
  raise ESHIndexOutOfBounds.CreateFmt('THuffmanTree.GetFrequency: Index (%d) ouf of bounds.',[Index]);
end;

//------------------------------------------------------------------------------

procedure THuffmanTree.SetFrequency(Index: Integer; Value: Int64);
begin
If CheckByteNodeIndex(Index) then
  fByteNodes[UInt8(Index)].Frequency := Value
else
  raise ESHIndexOutOfBounds.CreateFmt('THuffmanTree.SetFrequency: Index (%d) ouf of bounds.',[Index]);
end;

//------------------------------------------------------------------------------

Function THuffmanTree.GetBitSequence(Index: Integer): TSHBitSequence;
begin
If CheckByteNodeIndex(Index) then
  Result := fByteNodes[UInt8(Index)].BitSequence
else
  raise ESHIndexOutOfBounds.CreateFmt('THuffmanTree.GetBitSequence: Index (%d) ouf of bounds.',[Index]);
end;

//------------------------------------------------------------------------------

Function THuffmanTree.GetNodeSaved(Index: Integer): Boolean;
begin
If CheckByteNodeIndex(Index) then
  Result := fByteNodes[UInt8(Index)].NodeSaved
else
  raise ESHIndexOutOfBounds.CreateFmt('THuffmanTree.GetNodeSaved: Index (%d) ouf of bounds.',[Index]);
end;

//------------------------------------------------------------------------------

procedure THuffmanTree.SetNodeSaved(Index: Integer; Value: Boolean);
begin
If CheckByteNodeIndex(Index) then
  // do not clear frequency
  fByteNodes[UInt8(Index)].NodeSaved := Value
else
  raise ESHIndexOutOfBounds.CreateFmt('THuffmanTree.SetNodeSaved: Index (%d) ouf of bounds.',[Index]);
end;

//------------------------------------------------------------------------------

Function THuffmanTree.GetTreeNode(Index: Integer): TSHHuffmanTreeNode;
begin
If CheckTreeNodeIndex(Index) then
  Result := fTreeNodes[Index]^
else
  raise ESHIndexOutOfBounds.CreateFmt('THuffmanTree.GetTreeNode: Index (%d) ouf of bounds.',[Index]);
end;

//------------------------------------------------------------------------------

Function THuffmanTree.GetCapacity(List: Integer): Integer;
begin
case List of
  SH_HUFFTREE_LIST_BYTENODES: Result := Length(fByteNodes);
  SH_HUFFTREE_LIST_TREENODES: Result := Length(fTreeNodes);
else
  raise ESHInvalidValue.CreateFmt('THuffmanTree.GetCapacity: Invalid list index (%d).',[List]);
end;
end;

//------------------------------------------------------------------------------

procedure THuffmanTree.SetCapacity(List,Value: Integer);
begin
case List of
  SH_HUFFTREE_LIST_BYTENODES: raise ESHInvalidOperation.Create('THuffmanTree.SetCapacity: Cannot change capacity of byte nodes.');
{
  Since capacity of tree nodes is only changed internally, and then only
  increased, there is no need for complex checks and data protection.
}
  SH_HUFFTREE_LIST_TREENODES: SetLength(fTreeNodes,Value);
else
  raise ESHInvalidValue.CreateFmt('THuffmanTree.SetCapacity: Invalid list index (%d).',[List]);
end;
end;

//------------------------------------------------------------------------------

Function THuffmanTree.GetCount(List: Integer): Integer;
begin
case List of
  SH_HUFFTREE_LIST_BYTENODES: Result := Length(fByteNodes);
  SH_HUFFTREE_LIST_TREENODES: Result := fTreeNodeCount;
else
  raise ESHInvalidValue.CreateFmt('THuffmanTree.GetCount: Invalid list index (%d).',[List]);
end;
end;

//------------------------------------------------------------------------------

procedure THuffmanTree.SetCount(List,Value: Integer);
begin
case List of
  SH_HUFFTREE_LIST_BYTENODES,
  SH_HUFFTREE_LIST_TREENODES:;  // do nothing
else
  raise ESHInvalidValue.CreateFmt('THuffmanTree.SetCount: Invalid list index (%d).',[List]);
end;
end;

//------------------------------------------------------------------------------

Function THuffmanTree.AddTreeNode(Node: PSHHuffmanTreeNode): Integer;
var
  i:  Integer;
begin
Grow(SH_HUFFTREE_LIST_TREENODES);
// find index where to put the new node
Result := fTreeNodeCount;
For i := LowTreeNodeIndex to HighTreeNodeIndex do
  If Node^.Frequency < fTreeNodes[i]^.Frequency then
    begin
      Result := i;
      Break{For i};
    end;
// inser the node at selected position
For i := HighTreeNodeIndex downto Result do
  fTreeNodes[i + 1] := fTreeNodes[i];
fTreeNodes[Result] := Node;
Inc(fTreeNodeCount);
end;

//------------------------------------------------------------------------------

Function THuffmanTree.StreamingSize(out FreqBits: Integer): TMemSize;
var
  SavedCnt: Integer;
  FreqHigh: Int64;
  i:        Integer;
begin
FreqHigh := 0;
SavedCnt := 0;
// get highest frequency
For i := LowByteNodeIndex to HighByteNodeIndex do
  If fByteNodes[UInt8(i)].NodeSaved then
    begin
      Inc(SavedCnt);
      If fByteNodes[UInt8(i)].Frequency > FreqHigh then
        FreqHigh := fByteNodes[UInt8(i)].Frequency;
    end
  else If fByteNodes[UInt8(i)].Frequency <> 0 then
    raise ESHInvalidValue.CreateFmt('THuffmanTree.TreeSize: Unsaved node (%d) with frequency.',[i]);
// how many bits is needed to store this number (reversed bit scan)
If FreqHigh <> 0 then
  FreqBits := BSR(UInt64(FreqHigh)) + 1
 else
  FreqBits := 0;
{
  Calculate resulting size in bytes...

  First byte contains how many bits is used to store each frequency.

  If bits is above zero, then the next bytes contains bit-packed frequencies
  (256 values, for each only the lovest bits is stored), when bits is zero then
  nothing is stored after the first byte.
}
Result := 1 + TMemSize(Ceil((FreqBits * SavedCnt) / 8));
end;

//------------------------------------------------------------------------------

procedure THuffmanTree.ClearByteNodes;
var
  i:  Integer;
begin
FillChar(fByteNodes,SizeOf(fByteNodes),0);
For i := LowByteNodeIndex to HighByteNodeIndex do
  begin
    fByteNodes[UInt8(i)].ByteNode := True;
    fByteNodes[UInt8(i)].ByteIndex := UInt8(i);
    fByteNodes[UInt8(i)].TreeIndex := -1;
    fByteNodes[UInt8(i)].NodeSaved := True;
  end;
end;

//------------------------------------------------------------------------------

procedure THuffmanTree.ClearTreeNodes;
var
  i:  Integer;
begin
For i := LowTreeNodeIndex to HighTreeNodeIndex do
  If not fTreeNodes[i]^.ByteNode then
    Dispose(fTreeNodes[i]);
SetLength(fTreeNodes,0);
fTreeNodeCount := 0;
fRootTreeNode := nil;
end;

//------------------------------------------------------------------------------

procedure THuffmanTree.Initialize;
begin
ClearTree;
end;

//------------------------------------------------------------------------------

procedure THuffmanTree.Finalize;
begin
ClearTreeNodes;
end;

{-------------------------------------------------------------------------------
    THuffmanTree - public methods
-------------------------------------------------------------------------------}

constructor THuffmanTree.Create;
begin
inherited Create(2);
Initialize;
end;

//------------------------------------------------------------------------------

destructor THuffmanTree.Destroy;
begin
Finalize;
inherited;
end;

//------------------------------------------------------------------------------

Function THuffmanTree.LowIndex(List: Integer): Integer;
begin
case List of
  SH_HUFFTREE_LIST_BYTENODES: Result := Low(fByteNodes);
  SH_HUFFTREE_LIST_TREENODES: Result := Low(fTreeNodes);
else
  raise ESHInvalidValue.CreateFmt('THuffmanTree.LowIndex: Invalid list index (%d).',[List]);
end;
end;

//------------------------------------------------------------------------------

Function THuffmanTree.HighIndex(List: Integer): Integer;
begin
case List of
  SH_HUFFTREE_LIST_BYTENODES: Result := High(fByteNodes);
  SH_HUFFTREE_LIST_TREENODES: Result := Pred(fTreeNodeCount);
else
  raise ESHInvalidValue.CreateFmt('THuffmanTree.HighIndex: Invalid list index (%d).',[List]);
end;
end;

//------------------------------------------------------------------------------

Function THuffmanTree.LowByteNodeIndex: Integer;
begin
Result := LowIndex(SH_HUFFTREE_LIST_BYTENODES);
end;

//------------------------------------------------------------------------------

Function THuffmanTree.HighByteNodeIndex: Integer;
begin
Result := HighIndex(SH_HUFFTREE_LIST_BYTENODES);
end;

//------------------------------------------------------------------------------

Function THuffmanTree.CheckByteNodeIndex(Index: UInt8): Boolean;
begin
Result := CheckIndex(SH_HUFFTREE_LIST_BYTENODES,Index);
end;

//------------------------------------------------------------------------------

Function THuffmanTree.LowTreeNodeIndex: Integer;
begin
Result := LowIndex(SH_HUFFTREE_LIST_TREENODES);
end;

//------------------------------------------------------------------------------

Function THuffmanTree.HighTreeNodeIndex: Integer;
begin
Result := HighIndex(SH_HUFFTREE_LIST_TREENODES);
end;

//------------------------------------------------------------------------------

Function THuffmanTree.CheckTreeNodeIndex(Index: Integer): Boolean;
begin
Result := CheckIndex(SH_HUFFTREE_LIST_TREENODES,Index);
end;

//------------------------------------------------------------------------------

Function THuffmanTree.IncreaseFrequency(ByteIndex: UInt8): Int64;
begin
Inc(fByteNodes[ByteIndex].Frequency);
Result := fByteNodes[ByteIndex].Frequency;
end;

//------------------------------------------------------------------------------

procedure THuffmanTree.BuildTree(Frequencies: array of Int64);
var
  i:  Integer;
begin
ClearTree;
For i := Low(Frequencies) to Min(High(Frequencies),High(fByteNodes)) do
  fByteNodes[UInt8(i)].Frequency := Frequencies[i];
ConstructTree;
end;

//------------------------------------------------------------------------------

procedure THuffmanTree.ConstructTree;

  procedure AddToBitSequence(var BitSequence: TSHBitSequence; Node: PSHHuffmanTreeNode);

    procedure AddToBitSequenceData(var BitSequenceData: TSHBitSequenceData; NewBit: Boolean);
    var
      i,Carry:  Integer;
    begin
      // shift existing sequence
      Carry := 0;
      For i := Low(BitSequenceData) to (BitSequence.Length shr 3) do
        begin
          Carry := Carry or (BitSequenceData[i] and $80);
          BitSequenceData[i] := UInt8(BitSequenceData[i] shl 1) or UInt8(Carry and 1);
          Carry := Carry shr 7;
        end;
      // add new bit  
      If NewBit then
        BitSequenceData[Low(BitSequenceData)] := BitSequenceData[Low(BitSequenceData)] or 1;
    end;

  begin
    If Assigned(Node^.ParentNode) then
      begin
        AddToBitSequenceData(BitSequence.Data,Node^.ParentPath);
        Inc(BitSequence.Length);  // must be second
        AddToBitSequence(BitSequence,Node^.ParentNode);
      end;
  end;

var
  i:        Integer;
  TempNode: PSHHuffmanTreeNode;
begin
If Assigned(fRootTreeNode) then
  ClearTreeNodes;
{
  Preallocate tree nodes (512 should be enough for all cases, meaning the will
  be no need for reallocation).
}
SetCapacity(SH_HUFFTREE_LIST_TREENODES,512);
// first add all the byte nodes (they are being ordered as added)
For i := LowByteNodeIndex to HighByteNodeIndex do
  begin
    If fByteNodes[UInt8(i)].NodeSaved or (fByteNodes[UInt8(i)].Frequency = 0) then
      AddTreeNode(@fByteNodes[UInt8(i)])
    else
      raise ESHInvalidValue.CreateFmt('THuffmanTree.ConstructTree: Unsaved node (%d) with frequency.',[i]);
  end;
// now create branch nodes
i := LowTreeNodeIndex;
while i < HighTreeNodeIndex do
  begin
    New(TempNode);
    FillChar(TempNode^,SizeOf(TSHHuffmanTreeNode),0);
    TempNode^.TreeIndex := -1;  // assigned later
    TempNode^.Frequency := fTreeNodes[i]^.Frequency + fTreeNodes[Succ(i)]^.Frequency;
    // connect nodes
    TempNode^.SubNodes[False] := fTreeNodes[i];
    fTreeNodes[i]^.ParentNode := TempNode;
    fTreeNodes[i]^.ParentPath := False;
    TempNode^.SubNodes[True] := fTreeNodes[Succ(i)];
    fTreeNodes[Succ(i)]^.ParentNode := TempNode;
    fTreeNodes[Succ(i)]^.ParentPath := True;
    AddTreeNode(TempNode);
    Inc(i,2);
  end;
fRootTreeNode := fTreeNodes[HighTreeNodeIndex];
// assign correct tree indices
For i := LowTreeNodeIndex to HighTreeNodeIndex do
  fTreeNodes[i]^.TreeIndex := i;
// prepare bit sequences
For i := LowByteNodeIndex to HighByteNodeIndex do
  AddToBitSequence(fByteNodes[UInt8(i)].BitSequence,@fByteNodes[UInt8(i)]);
end;

//------------------------------------------------------------------------------

procedure THuffmanTree.ClearTree;
begin
ClearByteNodes;
ClearTreeNodes;
end;

//------------------------------------------------------------------------------

Function THuffmanTree.IsReadyTree: Boolean;
begin
Result := Assigned(fRootTreeNode);
end;

//------------------------------------------------------------------------------

Function THuffmanTree.TraverseTree(BitPath: Boolean; var TreeNodeIndex: Integer): Boolean;
var
  SubNode:  PSHHuffmanTreeNode;
begin
If not CheckTreeNodeIndex(TreeNodeIndex) then
  begin
    If Assigned(fRootTreeNode) then
      SubNode := fRootTreeNode^.SubNodes[BitPath]
    else
      raise ESHInvalidOperation.Create('THuffmanTree.TraverseTree: Root node not assigned.');
  end
else SubNode := fTreeNodes[TreeNodeIndex]^.SubNodes[BitPath];  
If Assigned(SubNode) then
  TreeNodeIndex := SubNode^.TreeIndex
else
  raise ESHInvalidOperation.Create('THuffmanTree.TraverseTree: No subnode assigned.');
Result := not SubNode^.ByteNode;
end;

//------------------------------------------------------------------------------

Function THuffmanTree.StreamingSize: TMemSize;
var
  FreqBits: Integer;
begin
Result := StreamingSize(FreqBits);
end;

//------------------------------------------------------------------------------

procedure THuffmanTree.SaveToBuffer(out Buffer; Size: TMemSize);
var
  Buff:       PUInt8;
  FreqBits:   Integer;
  i:          Integer;
  BitOffset:  Integer;
  FreqTemp:   Int64;
begin
If Size >= StreamingSize(FreqBits) then
  begin
    Buff := @Buffer;
    Buff^ := UInt8(FreqBits);
    If FreqBits > 0 then
      begin
        Inc(Buff);
        BitOffset := 0;
        For i := LowByteNodeIndex to HighByteNodeIndex do
          If fByteNodes[UInt8(i)].NodeSaved then
            begin
              // make sure the number has little endianness
            {$IFDEF ENDIAN_BIG}
              FreqTemp := Int64(SwapEndian(UInt64(fByteNodes[UInt8(i)].Frequency)));
            {$ELSE}
              FreqTemp := fByteNodes[UInt8(i)].Frequency;
            {$ENDIF}
              PutBitsAndMoveDest(Buff,BitOffset,PUInt8(@FreqTemp),TMemSize(FreqBits));
              BitOffset := (BitOffset + FreqBits) and 7;
            end;
      end;
  end
else raise ESHBufferTooSmall.CreateFmt('THuffmanTree.SaveToBuffer: Insufficient buffer size (%u).',[Size]);
end;

//------------------------------------------------------------------------------

procedure THuffmanTree.SaveToStream(Stream: TStream);
var
  Buffer:   Pointer;
  BuffSize: TMemSize;
begin
BuffSize := StreamingSize;
GetMem(Buffer,BuffSize);
try
  SaveToBuffer(Buffer^,BuffSize);
  Stream.WriteBuffer(Buffer^,BuffSize);
finally
  FreeMem(Buffer,BuffSize);
end;
end;

//------------------------------------------------------------------------------

procedure THuffmanTree.SaveToFile(const FileName: String);
var
  FileStream: TFileStream;
begin
FileStream := TFileStream.Create(StrToRTL(FileName),fmCreate or fmShareDenyWrite);
try
  FileStream.Seek(0,soBeginning);
  SaveToStream(FileStream);
finally
  FileStream.Free;
end;
end;

//------------------------------------------------------------------------------

procedure THuffmanTree.LoadFromBuffer(const Buffer; Size: TMemSize);
var
  Buff:       PUInt8;
  FreqBits:   Integer;
  i:          Integer;
  BitOffset:  Integer;
begin
If Size >= 1 then
  begin
    Buff := @Buffer;
    FreqBits := Buff^;
    If Size >= TMemSize(1 + (FreqBits * 32)) then
      begin
        ClearTree;
        If FreqBits > 0 then
          begin
            Inc(Buff);
            BitOffSet := 0;
            For i := LowByteNodeIndex to HighByteNodeIndex do
              If fByteNodes[UInt8(i)].NodeSaved then
                begin
                  fByteNodes[UInt8(i)].Frequency := LoadFrequencyBits(Buff,BitOffset,FreqBits);
                  BitOffset := (BitOffset + FreqBits) and 7;
                end;
            end;
        ConstructTree;
      end
    else raise ESHBufferTooSmall.CreateFmt('THuffmanTree.LoadFromBuffer: Buffer too small to store frequency table (%u).',[Size]);
  end
else raise ESHBufferTooSmall.CreateFmt('THuffmanTree.LoadFromBuffer: Buffer too small to store frequency bits (%u).',[Size]);
end;

//------------------------------------------------------------------------------

procedure THuffmanTree.LoadFromStream(Stream: TStream);
var
  FreqBits: UInt8;
  Buffer:   Pointer;
  BuffSize: TMemSize;
begin
FreqBits := 0;
Stream.ReadBuffer(FreqBits,1);
If FreqBits > 0 then
  begin
    BuffSize := 1 + TMemSize(FreqBits * 32);
    GetMem(Buffer,BuffSize);
    try
      Stream.Seek(-1,soCurrent);
      Stream.ReadBuffer(Buffer^,BuffSize);
      LoadFromBuffer(Buffer^,BuffSize);
    finally
      FreeMem(Buffer,BuffSize);
    end;
  end
else LoadFromBuffer(FreqBits,1);
end;

//------------------------------------------------------------------------------

procedure THuffmanTree.LoadFromFile(const FileName: String);
var
  FileStream: TFileStream;
begin
FileStream := TFileStream.Create(StrToRTL(FileName),fmOpenRead or fmShareDenyWrite);
try
  FileStream.Seek(0,soBeginning);
  LoadFromStream(FileStream);
finally
  FileStream.Free;
end;
end;

//------------------------------------------------------------------------------

Function THuffmanTree.IsSame(Tree: THuffmanTree): Boolean;

  Function SameBitSequence(A,B: TSHBitSequence): Boolean;
  var
    i:    Integer;
    Mask: UInt8;
  begin
    If A.Length = B.Length then
      begin
        Result := True;
        For i := 1 to (A.Length shr 3) do
          If A.Data[Pred(i)] <> B.Data[Pred(i)] then
            begin
              Result := False;
              Exit;
            end;
        If (A.Length and 7) <> 0 then
          begin
            i := (A.Length + 7) shr 3;
            Mask := UInt8($FF) shr (8 - (A.Length and 7));
            Result := (A.Data[i] and Mask) = (B.Data[i] and Mask);
          end;
      end
    else Result := False;
  end;

var
  i:  Integer;
begin
Result := True;
For i := LowByteNodeIndex to HighByteNodeIndex do
  If not SameBitSequence(fByteNodes[UInt8(i)].BitSequence,Tree.BitSequences[i]) then
    begin
      Result := False;
      Break{For i};
    end;
end;



procedure THuffmanTree.Foo;
var
  Ctr:  Integer;

  procedure Traverse(Node: PSHHuffmanTreeNode; const Str: String);
  begin
    If not Node^.ByteNode then
      begin
        Traverse(Node^.SubNodes[False],Str + '0');
        Traverse(Node^.SubNodes[True],Str + '1');
      end
    else
      begin
        WriteLn(Format('%-2d  %.2x %.2x  %-16s #%-3d  (%d)',[
          Node^.BitSequence.Length,Node^.BitSequence.Data[0],Node^.BitSequence.Data[1],
          Str,Node^.ByteIndex,Node^.Frequency]));
        Inc(Ctr);
      end;
  end;

var
  i:    Integer;
  Bits: Int64;
begin
Ctr := 0;
If Assigned(fRootTreeNode) then
  begin
    Traverse(fRootTreeNode,'');
    WriteLn('node count       ',Ctr);
    WriteLn('root frequency   ',fRootTreeNode^.Frequency);
  end;
Bits := 0;
For i := LowByteNodeIndex to HighByteNodeIndex do
  Bits := Bits + (fByteNodes[UInt8(i)].Frequency * fByteNodes[UInt8(i)].BitSequence.Length);
WriteLn('bits             ',Bits);
WriteLn('bytes            ',(Bits + 7) shr 3);
If fRootTreeNode^.Frequency <> 0 then
  WriteLn('compression rate ',Format('%.2f%%',[(((Bits + 7) shr 3) / fRootTreeNode^.Frequency) * 100]));
end;



{===============================================================================
--------------------------------------------------------------------------------
                                 THuffmanBase
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    THuffmanBase - class implementation
===============================================================================}
{-------------------------------------------------------------------------------
    THuffmanBase - protected methods
-------------------------------------------------------------------------------}

procedure THuffmanBase.Initialize;
begin
fHuffmanTree := THuffmanTree.Create;
fStreamBufferSize := 64 * 1024; // 64KiB
fUncompressedSize := 0;
fCompressedSize := 0;
fCompressionRatio := 0.0;
fBreakProcessing := False;
end;

//------------------------------------------------------------------------------

procedure THuffmanBase.Finalize;
begin
fHuffmanTree.Free;
end;

{-------------------------------------------------------------------------------
    THuffmanBase - public methods
-------------------------------------------------------------------------------}

constructor THuffmanBase.Create;
begin
inherited Create;
Initialize;
end;

//------------------------------------------------------------------------------

destructor THuffmanBase.Destroy;
begin
Finalize;
inherited;
end;

//------------------------------------------------------------------------------

Function THuffmanBase.BreakProcessing: Boolean;
begin
Result := fBreakProcessing;
fBreakProcessing := True;
end;


{===============================================================================
--------------------------------------------------------------------------------
                                 THuffmanEncoder
--------------------------------------------------------------------------------
===============================================================================}
{===============================================================================
    THuffmanEncoder - class declaration
===============================================================================}
{-------------------------------------------------------------------------------
    THuffmanEncoder - protected methods
-------------------------------------------------------------------------------}

procedure THuffmanEncoder.DoScanProgress(Progress: Double);
begin
If Assigned(fScanProgressEvent) then
  fScanProgressEvent(Self,Progress)
else If Assigned(fScanProgressCallback) then
  fScanProgressCallback(Self,Progress);
If Assigned(fProgressEvent) then
  fProgressEvent(Self,Progress)
else If Assigned(fProgressCallback) then
  fProgressCallback(Self,Progress);
end;

//------------------------------------------------------------------------------

procedure THuffmanEncoder.DoEncodeProgress(Progress: Double);
begin
If Assigned(fEncodeProgressEvent) then
  fEncodeProgressEvent(Self,Progress)
else If Assigned(fEncodeProgressCallback) then
  fEncodeProgressCallback(Self,Progress);
If Assigned(fProgressEvent) then
  fProgressEvent(Self,1.0 + Progress)
else If Assigned(fProgressCallback) then
  fProgressCallback(Self,1.0 + Progress);
end;

{-------------------------------------------------------------------------------
    THuffmanEncoder - public methods
-------------------------------------------------------------------------------}

procedure THuffmanEncoder.Initialize;
begin
inherited;
fScanInitialized := False;
fScanFinalized := False;
fEncodeInitialized := False;
fEncodeFinalized := False;
fScanProgressCallback := nil;
fScanProgressEvent := nil;
fEncodeProgressCallback := nil;
fEncodeProgressEvent := nil;
fProgressCallback := nil;
fProgressEvent := nil;
end;

//------------------------------------------------------------------------------

procedure THuffmanEncoder.ScanInit;
begin
fHuffmanTree.ClearTree;
fScanInitialized := True;
fScanFinalized := False;
end;

//------------------------------------------------------------------------------

procedure THuffmanEncoder.ScanUpdate(const Buffer; Size: TMemSize);
var
  Buff: PUInt8;
  i:    TMemSize;
begin
If fScanFinalized then
  begin
    If not fScanInitialized then
      begin
        Buff := @Buffer;
        For i := 1 to Size do
          begin
            fHuffmanTree.IncreaseFrequency(Buff^);
            Inc(Buff);
          end;
      end
    else raise ESHInvalidState.Create('THuffmanEncoder.ScanUpdate: Scanning not initialized.');
  end
else raise ESHInvalidState.Create('THuffmanEncoder.ScanUpdate: Scanning already finalized.');
end;

//------------------------------------------------------------------------------

Function THuffmanEncoder.ScanFinal(const Buffer; Size: TMemSize): Int64;
begin
ScanUpdate(Buffer,Size);
Result := ScanFinal;
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

Function THuffmanEncoder.ScanFinal: Int64;
var
  i:  Integer;
begin
If fScanFinalized then
  begin
    If not fScanInitialized then
      begin
        fHuffmanTree.ConstructTree;
        // get compressed size in bits...
        Result := 0;
        For i := fHuffmanTree.LowByteNodeIndex to fHuffmanTree.HighByteNodeIndex do
          Inc(Result,(fHuffmanTree[i].Frequency * fHuffmanTree[i].BitSequence.Length));
      {
        ...and convert to bytes - let's hope there is no overflow, 1 EiB (one
        exbibyte, 2^60) should be enough for everyone ;)
      }
        Result := (Result + 7) shr 3;
        fScanFinalized := True;
      end
    else raise ESHInvalidState.Create('THuffmanEncoder.ScanFinal: Scanning not initialized.');
  end
else raise ESHInvalidState.Create('THuffmanEncoder.ScanFinal: Scanning already finalized.');
end;

//------------------------------------------------------------------------------

Function THuffmanEncoder.ScanMemory(Memory: Pointer; Size: TMemSize): Int64;
var
  MemoryStream: TStaticMemoryStream;
begin
If Size > fStreamBufferSize then
  begin
    MemoryStream := TStaticMemoryStream.Create(Memory,Size);
    try
      Result := ScanStream(MemoryStream);
    finally
      MemoryStream.Free;
    end;
  end
else
  begin
    fBreakProcessing := False;
    DoScanProgress(0.0);
    If not fBreakProcessing then
      begin
        ScanInit;
        Result := ScanFinal(Memory^,Size);
        DoScanProgress(1.0);
      end
    else Result := 0;
  end;
end;

//------------------------------------------------------------------------------

Function THuffmanEncoder.ScanBuffer(const Buffer; Size: TMemSize): Int64;
begin
Result := ScanMemory(@Buffer,Size);
end;

//------------------------------------------------------------------------------

Function THuffmanEncoder.ScanAnsiString(const Str: AnsiString): Int64;
begin
Result := ScanMemory(PAnsiChar(Str),Length(Str) * SizeOf(AnsiChar));
end;

//------------------------------------------------------------------------------

Function THuffmanEncoder.ScanWideString(const Str: WideString): Int64;
begin
Result := ScanMemory(PWideChar(Str),Length(Str) * SizeOf(WideChar));
end;

//------------------------------------------------------------------------------

Function THuffmanEncoder.ScanString(const Str: String): Int64;
begin
Result := ScanMemory(PChar(Str),Length(Str) * SizeOf(Char));
end;

//------------------------------------------------------------------------------

Function THuffmanEncoder.ScanStream(Stream: TStream; Count: Int64 = -1): Int64;
var
  InitCount:  Int64;
  Buffer:     Pointer;
  BytesRead:  Integer;
begin
If Assigned(Stream) then
  begin
    If Count = 0 then
      Count := Stream.Size - Stream.Position;
    If Count < 0 then
      begin
        Stream.Seek(0,soBeginning);
        Count := Stream.Size;
      end;
    InitCount := Count;
    fBreakProcessing := False;
    DoScanProgress(0.0);
    If not fBreakProcessing  then
      begin
        ScanInit;
        If InitCount > 0 then
          begin
            GetMem(Buffer,fStreamBufferSize);
            try
              repeat
                BytesRead := Stream.Read(Buffer^,Min(fStreamBufferSize,Count));
                ScanUpdate(Buffer^,TMemSize(BytesRead));
                Dec(Count,BytesRead);
                DoScanProgress((InitCount - Count) / InitCount);
              until (TMemSize(BytesRead) < fStreamBufferSize) or fBreakProcessing;
            finally
              FreeMem(Buffer,fStreamBufferSize);
            end;
          end;
        Result := ScanFinal;
        DoScanProgress(1.0);
      end
    else Result := 0;      
  end
else raise ESHInvalidValue.Create('THuffmanEncoder.ScanStream: Stream not assigned.');
end;

//------------------------------------------------------------------------------

Function THuffmanEncoder.ScanFile(const FileName: String): Int64;
var
  FileStream: TFileStream;
begin
FileStream := TFileStream.Create(StrToRTL(FileName),fmOpenRead or fmShareDenyWrite);
try
  FileStream.Seek(0,soBeginning);
  Result := ScanStream(FileStream);
finally
  FileStream.Free;
end;
end;

//------------------------------------------------------------------------------

procedure THuffmanEncoder.EncodeInit;
begin
If fHuffmanTree.IsReadyTree then
  begin
    fUncompressedSize := 0;
    fCompressedSize := 0;
    fCompressionRatio := 0.0;
    fEncodeInitialized := True;
    fEncodeFinalized := False;
  end
else raise ESHInvalidState.Create('THuffmanEncoder.EncodeInit: Tree not ready.');
end;

//------------------------------------------------------------------------------

procedure THuffmanEncoder.EncodeUpdate(const BufferIn; var SizeIn: TMemSize; out BufferOut; var SizeOut: TMemSize);
begin
If fEncodeFinalized then
  begin
    If not fEncodeInitialized then
      begin

      end
    else raise ESHInvalidState.Create('THuffmanEncoder.EncodeUpdate: Encoding not initialized.');
  end
else raise ESHInvalidState.Create('THuffmanEncoder.EncodeUpdate: Encoding already finalized.');
end;

//------------------------------------------------------------------------------

procedure THuffmanEncoder.EncodeFinal(const BufferIn; var SizeIn: TMemSize; out BufferOut; var SizeOut: TMemSize);
begin
//EncodeUpdate(BufferIn,SizeIn,BufferOut,SizeOut);
// check out before proceeding
end;

//------------------------------------------------------------------------------

procedure THuffmanEncoder.EncodeFinal(out BufferOut; var SizeOut: TMemSize);
begin
If fEncodeFinalized then
  begin
    If not fEncodeInitialized then
      begin
        
        fEncodeFinalized := True;
      end
    else raise ESHInvalidState.Create('THuffmanEncoder.EncodeUpdate: Encoding not initialized.');
  end
else raise ESHInvalidState.Create('THuffmanEncoder.EncodeUpdate: Encoding already finalized.');
end;





end.
