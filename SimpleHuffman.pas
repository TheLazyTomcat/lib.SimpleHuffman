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
    Length: TMemSize;
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
    Function TreeIsReady: Boolean; virtual;
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
    //Function CompressFrequencies(Force: Boolean = False): Boolean; virtual;
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
    fHuffmanTree:           THuffmanTree;
    fStreamBufferSize:      TMemSize;
    fUncompressedSize:      Int64;
    fCompressedSize:        Int64;
    fCompressionRatio:      Double;
    fBreakProcessing:       Boolean;
    fScanInitialized:       Boolean;
    fScanFinalized:         Boolean;
    fScanProgressCallback:  TProgressCallback;
    fScanProgressEvent:     TProgressEvent;
    procedure DoScanProgress(Progress: Double); virtual;
    procedure Initialize; virtual;
    procedure Finalize; virtual;
  public
    constructor Create;
    destructor Destroy; override;
    Function BreakProcessing: Boolean; virtual;
    // scanning
    procedure ScanInit; virtual;
    procedure ScanUpdate(const Buffer; Size: TMemSize); virtual;
    Function ScanFinal: Int64; virtual;
    // scanning macros
    Function ScanMemory(Memory: Pointer; Size: TMemSize): Int64; virtual;
    Function ScanBuffer(const Buffer; Size: TMemSize): Int64; virtual;
    Function ScanAnsiString(const Str: AnsiString): Int64; virtual;
    Function ScanWideString(const Str: WideString): Int64; virtual;
    Function ScanString(const Str: String): Int64; virtual;
    Function ScanStream(Stream: TStream; Count: Int64 = -1): Int64; virtual;
    Function ScanFile(const FileName: String): Int64; virtual;
    // properties
    property HuffmanTree: THuffmanTree read fHuffmanTree;
    property StreamBufferSize: TMemSize read fStreamBufferSize write fStreamBufferSize;
    property UncompressedSize: Int64 read fUncompressedSize;
    property CompressedSize: Int64 read fCompressedSize;
    property CompressionRatio: Double read fCompressionRatio;
    // events
    property OnScanProgressCallback: TProgressCallback read fScanProgressCallback write fScanProgressCallback;
    property OnScanProgressEvent: TProgressEvent read fScanProgressEvent write fScanProgressEvent;
    property OnScanProgress: TProgressEvent read fScanProgressEvent write fScanProgressEvent;
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
    fEncodedSizeInitialized:      Boolean;
    fEncodedSizeFinalized:        Boolean;
    fEncodedSizeCounters:         array[UInt8] of Int64;
    fEncodeInitialized:           Boolean;
    fEncodeFinalized:             Boolean;
    fEncodingBuffer:              Pointer;
    fEncodingTransferBits:        TMemSize;
    fEncodedSizeProgressCallback: TProgressCallback;
    fEncodedSizeProgressEvent:    TProgressEvent;
    fEncodeProgressCallback:      TProgressCallback;
    fEncodeProgressEvent:         TProgressEvent;
    procedure DoEncodedSizeProgress(Progress: Double); virtual;
    procedure DoEncodeProgress(Progress: Double); virtual;
    procedure Initialize; override;
    procedure Finalize; override;
  public
    // encoded size
    procedure EncodedSizeInit; virtual;
    procedure EncodedSizeUpdate(const Buffer; Size: TMemSize); virtual;
    Function EncodedSizeFinal: Int64; virtual;
    // encoded size macros
    Function EncodedSizeMemory(Memory: Pointer; Size: TMemSize): Int64; virtual;
    Function EncodedSizeBuffer(const Buffer; Size: TMemSize): Int64; virtual;
    Function EncodedSizeAnsiString(const Str: AnsiString): Int64; virtual;
    Function EncodedSizeWideString(const Str: WideString): Int64; virtual;
    Function EncodedSizeString(const Str: String): Int64; virtual;
    Function EncodedSizeStream(Stream: TStream; Count: Int64 = -1): Int64; virtual;
    Function EncodedSizeFile(const FileName: String): Int64; virtual;
    // encoding
  {
    The tree must be prepared before calling EncodeInit.
  }
    procedure EncodeInit; virtual;
  {
    Set SizeIn to size of the BufferIn and SizeOut to size of BufferOut (this
    buffer must be allocated by the caller).

    Upon return, the SizeIn will contain number of bytes that were consumed
    from BufferIn within the call, which might be less than was passed. SizeOut
    will contain number of bytes that were written into BufferOut.
  }
    procedure EncodeUpdate(const BufferIn; var SizeIn: TMemSize; out BufferOut; var SizeOut: TMemSize); virtual;
  {
    Set SizeOut to a size of BufferOut.
    When the funtion succeeds (returns true), then the SizeOut will contain
    number of bytes written into the BufferOut.
    When the function fails (returns false) due to output buffer being too
    small, the SizeOut will be set to a minimum size the output buffer needs
    to be (reallocate it as such and call this function again).
  }
    Function EncodeFinal(out BufferOut; var SizeOut: TMemSize): Boolean; virtual;
    // encoding macros
  {
    WARNING - MemoryOut/BufferOut output buffers must be allocated by the
              caller and SizeOut must contain their allocated size. StrOut
              string variable parameters must also be allocated (string length
              set).
              You can get the required size, in bytes, when scanning the data,
              or, if using pre-computed huffman tree, use EncodedSize* methods
              (tree must be prepared/loaded before calling any EncodedSize*
              method) - note that using EncodedSize* is "fast", in the sense
              there is almost no processing done, so the performance depends
              only on how fast can the data be served.
  }
    procedure EncodeMemory(MemoryIn: Pointer; SizeIn: TMemSize; MemoryOut: Pointer; SizeOut: TMemSize); virtual;
    procedure EncodeBuffer(const BufferIn; SizeIn: TMemSize; out BufferOut; SizeOut: TMemSize); virtual;
    procedure EncodeAnsiString(const StrIn: AnsiString; var StrOut: AnsiString); virtual;
    procedure EncodeWideString(const StrIn: WideString; var StrOut: WideString); virtual;
    procedure EncodeString(const StrIn: String; var StrOut: String); virtual;
    procedure EncodeStream(StreamIn: TStream; Count: Int64; StreamOut: TStream); overload; virtual;
    procedure EncodeStream(StreamIn: TStream; StreamOut: TStream); overload; virtual;
    procedure EncodeFile(const FileNameIn,FileNameOut: String); virtual;
    // properties
    property OnEncodedSizeProgressCallback: TProgressCallback read fEncodedSizeProgressCallback write fEncodedSizeProgressCallback;
    property OnEncodedSizeProgressEvent: TProgressEvent read fEncodedSizeProgressEvent write fEncodedSizeProgressEvent;
    property OnEncodedSizeProgress: TProgressEvent read fEncodedSizeProgressEvent write fEncodedSizeProgressEvent;
    property OnEncodeProgressCallback: TProgressCallback read fEncodeProgressCallback write fEncodeProgressCallback;
    property OnEncodeProgressEvent: TProgressEvent read fEncodeProgressEvent write fEncodeProgressEvent;
    property OnEncodeProgress: TProgressEvent read fEncodeProgressEvent write fEncodeProgressEvent;
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
    // also include DecodedSize* (slow, but to be complete)
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

Function THuffmanTree.TreeIsReady: Boolean;
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
    WriteLn('node count        ',Ctr);
    WriteLn('root frequency    ',fRootTreeNode^.Frequency);
  end;
Bits := 0;
For i := LowByteNodeIndex to HighByteNodeIndex do
  Bits := Bits + (fByteNodes[UInt8(i)].Frequency * fByteNodes[UInt8(i)].BitSequence.Length);
WriteLn('bits              ',Bits);
WriteLn('bytes             ',(Bits + 7) shr 3);
If fRootTreeNode^.Frequency <> 0 then
  WriteLn('compression ratio ',Format('%.2f%%',[(((Bits + 7) shr 3) / fRootTreeNode^.Frequency) * 100]));
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

procedure THuffmanBase.DoScanProgress(Progress: Double);
begin
If Assigned(fScanProgressEvent) then
  fScanProgressEvent(Self,Progress)
else If Assigned(fScanProgressCallback) then
  fScanProgressCallback(Self,Progress);
end;

//------------------------------------------------------------------------------

procedure THuffmanBase.Initialize;
begin
fHuffmanTree := THuffmanTree.Create;
fStreamBufferSize := 64 * 1024; // 64KiB
fUncompressedSize := 0;
fCompressedSize := 0;
fCompressionRatio := 0.0;
fBreakProcessing := False;
fScanInitialized := False;
fScanFinalized := False;
fScanProgressCallback := nil;
fScanProgressEvent := nil;
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

//------------------------------------------------------------------------------

procedure THuffmanBase.ScanInit;
begin
fHuffmanTree.ClearTree;
fScanInitialized := True;
fScanFinalized := False;
end;

//------------------------------------------------------------------------------

procedure THuffmanBase.ScanUpdate(const Buffer; Size: TMemSize);
var
  Buff: PUInt8;
  i:    TMemSize;
begin
If not fScanFinalized then
  begin
    If fScanInitialized then
      begin
        Buff := @Buffer;
        For i := 1 to Size do
          begin
            fHuffmanTree.IncreaseFrequency(Buff^);
            Inc(Buff);
          end;
      end
    else raise ESHInvalidState.Create('THuffmanBase.ScanUpdate: Scanning not initialized.');
  end
else raise ESHInvalidState.Create('THuffmanBase.ScanUpdate: Scanning already finalized.');
end;

//------------------------------------------------------------------------------

Function THuffmanBase.ScanFinal: Int64;
var
  i:  Integer;
begin
If not fScanFinalized then
  begin
    If fScanInitialized then
      begin
        fHuffmanTree.ConstructTree;
        // get compressed size in bits...
        Result := 7;
        For i := fHuffmanTree.LowByteNodeIndex to fHuffmanTree.HighByteNodeIndex do
          Inc(Result,(fHuffmanTree[i].Frequency * fHuffmanTree[i].BitSequence.Length));
      {
        ...and convert to bytes - let's hope there is no overflow, 1 EiB (one
        exbibyte, 2^60) should be enough for everyone ;)
      }
        Result := Result shr 3;
        fScanFinalized := True;
      end
    else raise ESHInvalidState.Create('THuffmanBase.ScanFinal: Scanning not initialized.');
  end
else raise ESHInvalidState.Create('THuffmanBase.ScanFinal: Scanning already finalized.');
end;

//------------------------------------------------------------------------------

Function THuffmanBase.ScanMemory(Memory: Pointer; Size: TMemSize): Int64;
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
        ScanUpdate(Memory^,Size);
        Result := ScanFinal;
        DoScanProgress(1.0);
      end
    else Result := 0;
  end;
end;

//------------------------------------------------------------------------------

Function THuffmanBase.ScanBuffer(const Buffer; Size: TMemSize): Int64;
begin
Result := ScanMemory(@Buffer,Size);
end;

//------------------------------------------------------------------------------

Function THuffmanBase.ScanAnsiString(const Str: AnsiString): Int64;
begin
Result := ScanMemory(PAnsiChar(Str),Length(Str) * SizeOf(AnsiChar));
end;

//------------------------------------------------------------------------------

Function THuffmanBase.ScanWideString(const Str: WideString): Int64;
begin
Result := ScanMemory(PWideChar(Str),Length(Str) * SizeOf(WideChar));
end;

//------------------------------------------------------------------------------

Function THuffmanBase.ScanString(const Str: String): Int64;
begin
Result := ScanMemory(PChar(Str),Length(Str) * SizeOf(Char));
end;

//------------------------------------------------------------------------------

Function THuffmanBase.ScanStream(Stream: TStream; Count: Int64 = -1): Int64;
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
else raise ESHInvalidValue.Create('THuffmanBase.ScanStream: Stream not assigned.');
end;

//------------------------------------------------------------------------------

Function THuffmanBase.ScanFile(const FileName: String): Int64;
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


{===============================================================================
--------------------------------------------------------------------------------
                                 THuffmanEncoder
--------------------------------------------------------------------------------
===============================================================================}
const
  SH_ENCODING_BUFFER_SIZE = 4 * 1024; // 4KiB
  SH_ENCODING_BUFFER_BITS = SH_ENCODING_BUFFER_SIZE * 8;

{===============================================================================
    THuffmanEncoder - class declaration
===============================================================================}
{-------------------------------------------------------------------------------
    THuffmanEncoder - protected methods
-------------------------------------------------------------------------------}

procedure THuffmanEncoder.DoEncodedSizeProgress(Progress: Double);
begin
If Assigned(fEncodedSizeProgressEvent) then
  fEncodedSizeProgressEvent(Self,Progress)
else If Assigned(fEncodedSizeProgressCallback) then
  fEncodedSizeProgressCallback(Self,Progress);
end;

//------------------------------------------------------------------------------

procedure THuffmanEncoder.DoEncodeProgress(Progress: Double);
begin
If Assigned(fEncodeProgressEvent) then
  fEncodeProgressEvent(Self,Progress)
else If Assigned(fEncodeProgressCallback) then
  fEncodeProgressCallback(Self,Progress);
end;

//------------------------------------------------------------------------------

procedure THuffmanEncoder.Initialize;
begin
inherited;
fEncodedSizeInitialized := False;
fEncodedSizeFinalized := False;
FillChar(fEncodedSizeCounters,SizeOf(fEncodedSizeCounters),0);
fEncodeInitialized := False;
fEncodeFinalized := False;
GetMem(fEncodingBuffer,SH_ENCODING_BUFFER_SIZE);
fEncodingTransferBits := 0;
fEncodedSizeProgressCallback := nil;
fEncodedSizeProgressEvent := nil;
fEncodeProgressCallback := nil;
fEncodeProgressEvent := nil;
end;

//------------------------------------------------------------------------------

procedure THuffmanEncoder.Finalize;
begin
FreeMem(fEncodingBuffer,SH_ENCODING_BUFFER_SIZE);
inherited;
end;

{-------------------------------------------------------------------------------
    THuffmanEncoder - public methods
-------------------------------------------------------------------------------}

procedure THuffmanEncoder.EncodedSizeInit;
begin
If fHuffmanTree.TreeIsReady then
  begin
    fEncodedSizeInitialized := True;
    fEncodedSizeFinalized := False;
    FillChar(fEncodedSizeCounters,SizeOf(fEncodedSizeCounters),0);
  end
else raise ESHInvalidState.Create('THuffmanEncoder.EncodedSizeInit: Tree not ready.');
end;

//------------------------------------------------------------------------------

procedure THuffmanEncoder.EncodedSizeUpdate(const Buffer; Size: TMemSize);
var
  Buff: PUInt8;
  i:    TMemSize;
begin
If not fEncodedSizeFinalized then
  begin
    If fEncodedSizeInitialized then
      begin
        Buff := @Buffer;
        For i := 1 to Size do
          begin
            Inc(fEncodedSizeCounters[Buff^]);
            Inc(Buff);
          end;
      end
    else raise ESHInvalidState.Create('THuffmanEncoder.EncodedSizeUpdate: Encoded size obtaining not initialized.');
  end
else raise ESHInvalidState.Create('THuffmanEncoder.EncodedSizeUpdate: Encoded size obtaining already finalized.');
end;

//------------------------------------------------------------------------------

Function THuffmanEncoder.EncodedSizeFinal: Int64;
var
  i:  Integer;
begin
If not fEncodedSizeFinalized then
  begin
    If fEncodedSizeInitialized then
      begin
        Result := 7;
        For i := Low(fEncodedSizeCounters) to High(fEncodedSizeCounters) do
          Inc(Result,fEncodedSizeCounters[i] * fHuffmanTree[i].BitSequence.Length);
        // convert bits to bytes
        Result := Result shr 3;          
      end
    else raise ESHInvalidState.Create('THuffmanEncoder.EncodedSizeFinal: Encoded size obtaining not initialized.');
  end
else raise ESHInvalidState.Create('THuffmanEncoder.EncodedSizeFinal: Encoded size obtaining already finalized.');
end;

//------------------------------------------------------------------------------

Function THuffmanEncoder.EncodedSizeMemory(Memory: Pointer; Size: TMemSize): Int64;
var
  MemoryStream: TStaticMemoryStream;
begin
If Size > fStreamBufferSize then
  begin
    MemoryStream := TStaticMemoryStream.Create(Memory,Size);
    try
      Result := EncodedSizeStream(MemoryStream);
    finally
      MemoryStream.Free;
    end;
  end
else
  begin
    fBreakProcessing := False;
    DoEncodedSizeProgress(0.0);
    If not fBreakProcessing then
      begin
        EncodedSizeInit;
        EncodedSizeUpdate(Memory^,Size);
        Result := EncodedSizeFinal;
        DoEncodedSizeProgress(1.0);
      end
    else Result := 0;
  end;
end;

//------------------------------------------------------------------------------

Function THuffmanEncoder.EncodedSizeBuffer(const Buffer; Size: TMemSize): Int64;
begin
Result := EncodedSizeMemory(@Buffer,Size);
end;

//------------------------------------------------------------------------------

Function THuffmanEncoder.EncodedSizeAnsiString(const Str: AnsiString): Int64;
begin
Result := EncodedSizeMemory(PAnsiChar(Str),Length(Str) * SizeOf(AnsiChar));
end;

//------------------------------------------------------------------------------

Function THuffmanEncoder.EncodedSizeWideString(const Str: WideString): Int64;
begin
Result := EncodedSizeMemory(PWideChar(Str),Length(Str) * SizeOf(WideChar));
end;

//------------------------------------------------------------------------------

Function THuffmanEncoder.EncodedSizeString(const Str: String): Int64;
begin
Result := EncodedSizeMemory(PChar(Str),Length(Str) * SizeOf(Char));
end;

//------------------------------------------------------------------------------

Function THuffmanEncoder.EncodedSizeStream(Stream: TStream; Count: Int64 = -1): Int64;
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
    DoEncodedSizeProgress(0.0);
    If not fBreakProcessing  then
      begin
        EncodedSizeInit;
        If InitCount > 0 then
          begin
            GetMem(Buffer,fStreamBufferSize);
            try
              repeat
                BytesRead := Stream.Read(Buffer^,Min(fStreamBufferSize,Count));
                EncodedSizeUpdate(Buffer^,TMemSize(BytesRead));
                Dec(Count,BytesRead);
                DoEncodedSizeProgress((InitCount - Count) / InitCount);
              until (TMemSize(BytesRead) < fStreamBufferSize) or fBreakProcessing;
            finally
              FreeMem(Buffer,fStreamBufferSize);
            end;
          end;
        Result := EncodedSizeFinal;
        DoEncodedSizeProgress(1.0);
      end
    else Result := 0;      
  end
else raise ESHInvalidValue.Create('THuffmanEncoder.EncodedSizeStream: Stream not assigned.');
end;

//------------------------------------------------------------------------------

Function THuffmanEncoder.EncodedSizeFile(const FileName: String): Int64;
var
  FileStream: TFileStream;
begin
FileStream := TFileStream.Create(StrToRTL(FileName),fmOpenRead or fmShareDenyWrite);
try
  FileStream.Seek(0,soBeginning);
  Result := EncodedSizeStream(FileStream);
finally
  FileStream.Free;
end;
end;

//------------------------------------------------------------------------------

procedure THuffmanEncoder.EncodeInit;
begin
If fHuffmanTree.TreeIsReady then
  begin
    fUncompressedSize := 0;
    fCompressedSize := 0;
    fCompressionRatio := 0.0;
    fEncodeInitialized := True;
    fEncodeFinalized := False;
    FillChar(fEncodingBuffer^,SH_ENCODING_BUFFER_SIZE,0);
    fEncodingTransferBits := 0;
  end
else raise ESHInvalidState.Create('THuffmanEncoder.EncodeInit: Tree not ready.');
end;

//------------------------------------------------------------------------------

procedure THuffmanEncoder.EncodeUpdate(const BufferIn; var SizeIn: TMemSize; out BufferOut; var SizeOut: TMemSize);
var
  BuffIn:   PUInt8;
  BuffOut:  PUInt8;
  BytesIn:  TMemSize;
  BytesOut: TMemSize;

//--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --

  Function ConsumeBytes: Boolean;
  var
    TempPtr:      Pointer;
    BitSequence:  TSHBitSequence;
  begin
    Result := False;
    TempPtr := PtrAdvance(fEncodingBuffer,fEncodingTransferBits shr 3);
    while BytesIn > 0 do
      begin
        BitSequence := fHuffmanTree.BitSequences[BuffIn^];
        If (fEncodingTransferBits + TMemSize(BitSequence.Length)) <= SH_ENCODING_BUFFER_BITS then
          begin
            PutBitsAndMoveDest(PUInt8(TempPtr),fEncodingTransferBits and 7,PUInt8(@BitSequence.Data),BitSequence.Length);
            Inc(BuffIn);
            Dec(BytesIn);
            Inc(fEncodingTransferBits,BitSequence.Length);
            Inc(fUncompressedSize);
            Result := True;
          end
        else Break{while...};
      end;
  end;

//--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --

  Function ProduceBytes: Boolean;
  var
    BytesToMove:  TMemSize;
  begin
    If (BytesOut > 0) and (fEncodingTransferBits >= 8) then
      begin
        BytesToMove := TMemSize(Min(BytesOut,fEncodingTransferBits shr 3));
        Move(fEncodingBuffer^,BuffOut^,BytesToMove);
        Inc(BuffOut,BytesToMove);
        Dec(BytesOut,BytesToMove);
        BufferShiftDown(fEncodingBuffer^,(fEncodingTransferBits + 7) shr 3,BytesToMove);
        Dec(fEncodingTransferBits,BytesToMove * 8);
        Inc(fCompressedSize,BytesToMove);
        Result := True;
      end
    else Result := False;
  end;

//--  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --  --

var
  BytesConsumed:  Boolean;
  BytesProduced:  Boolean;
begin
If not fEncodeFinalized then
  begin
    If fEncodeInitialized then
      begin
        BuffIn := @BufferIn;
        BuffOut := @BufferOut;
        BytesIn := SizeIn;
        BytesOut := SizeOut;
        BytesConsumed := True;
        BytesProduced := True;
        while BytesConsumed or BytesProduced do
          begin
            BytesConsumed := ConsumeBytes;
            BytesProduced := ProduceBytes;
          end;
        SizeIn := SizeIn - BytesIn;
        SizeOut := SizeOut - BytesOut;
      end
    else raise ESHInvalidState.Create('THuffmanEncoder.EncodeUpdate: Encoding not initialized.');
  end
else raise ESHInvalidState.Create('THuffmanEncoder.EncodeUpdate: Encoding already finalized.');
end;

//------------------------------------------------------------------------------

Function THuffmanEncoder.EncodeFinal(out BufferOut; var SizeOut: TMemSize): Boolean;
var
  BuffOut:  PUInt8;
begin
If not fEncodeFinalized then
  begin
    If fEncodeInitialized then
      begin
        If SizeOut >= ((fEncodingTransferBits + 7) shr 3) then
          begin
            // buffered data can fit into output
            BuffOut := @BufferOut;
            // move whole bytes
            SizeOut := fEncodingTransferBits shr 3;
            If SizeOut > 0 then
              begin
                Move(fEncodingBuffer^,BuffOut^,SizeOut);
                Inc(BuffOut,SizeOut);
              end;
            // now the partial byte (mask only valid bits)
            If fEncodingTransferBits and 7 <> 0 then
              begin
                BuffOut^ := PUInt8(PtrAdvance(fEncodingBuffer,PtrInt(SizeOut)))^ and
                            (UInt8($FF) shr (8 - (fEncodingTransferBits and 7)));
                Inc(SizeOut);
              end;
            // final touches
            Inc(fCompressedSize,SizeOut);
            If fUncompressedSize <> 0 then
              fCompressionRatio := fCompressedSize / fUncompressedSize
            else
              fCompressionRatio := 0.0;
            fEncodeFinalized := True;
            Result := True;
          end
        else
          begin
            // buffered data cannot fit into output
            SizeOut := (fEncodingTransferBits + 7) shr 3;
            Result := False;
          end;
      end
    else raise ESHInvalidState.Create('THuffmanEncoder.EncodeFinal: Encoding not initialized.');
  end
else raise ESHInvalidState.Create('THuffmanEncoder.EncodeFinal: Encoding already finalized.');
end;

//------------------------------------------------------------------------------

procedure THuffmanEncoder.EncodeMemory(MemoryIn: Pointer; SizeIn: TMemSize; MemoryOut: Pointer; SizeOut: TMemSize);
var
  MemoryStreamIn:   TStaticMemoryStream;
  MemoryStreamOut:  TWritableStaticMemoryStream;
  SizeInTemp:       TMemSize;
  SizeOutTemp:      TMemSize;
begin
If SizeIn > fStreamBufferSize then
  begin
    MemoryStreamIn := TStaticMemoryStream.Create(MemoryIn,SizeIn);
    try
      MemoryStreamOut := TWritableStaticMemoryStream.Create(MemoryOut,SizeOut);
      try
        EncodeStream(MemoryStreamIn,MemoryStreamOut);
      finally
        MemoryStreamOut.Free;
      end;
    finally
      MemoryStreamIn.Free;
    end;
  end
else
  begin
    fBreakProcessing := False;
    DoEncodeProgress(0.0);
    If not fBreakProcessing then
      begin
        EncodeInit;
        SizeInTemp := SizeIn;
        SizeOutTemp := SizeOut;
        EncodeUpdate(MemoryIn^,SizeInTemp,MemoryOut^,SizeOutTemp);
      {
        EncodeUpdate encodes everything it can, so if not all data were
        consumed it can only mean the output buffer is too small for them.
      }
        If SizeInTemp >= SizeIn then
          begin
            SizeOutTemp := SizeOut - SizeOutTemp;
            If not EncodeFinal(PtrAdvance(MemoryOut,SizeOutTemp)^,SizeOutTemp) then
              raise ESHBufferTooSmall.CreateFmt('THuffmanEncoder.EncodeMemory: Output buffer too small (%u).',[SizeOut]);
            DoEncodeProgress(1.0);
          end
        else raise ESHBufferTooSmall.CreateFmt('THuffmanEncoder.EncodeMemory: Output buffer too small (%u).',[SizeOut]);
      end;
  end;
end;

//------------------------------------------------------------------------------

procedure THuffmanEncoder.EncodeBuffer(const BufferIn; SizeIn: TMemSize; out BufferOut; SizeOut: TMemSize);
begin
EncodeMemory(@BufferIn,SizeIn,@BufferOut,Sizeout);
end;

//------------------------------------------------------------------------------

procedure THuffmanEncoder.EncodeAnsiString(const StrIn: AnsiString; var StrOut: AnsiString);
begin
EncodeMemory(PAnsiChar(StrIn),Length(StrIn) * SizeOf(AnsiChar),PAnsiChar(StrOut),Length(StrOut) * SizeOf(AnsiChar));
end;

//------------------------------------------------------------------------------

procedure THuffmanEncoder.EncodeWideString(const StrIn: WideString; var StrOut: WideString);
begin
EncodeMemory(PWideChar(StrIn),Length(StrIn) * SizeOf(WideChar),PWideChar(StrOut),Length(StrOut) * SizeOf(WideChar));
end;

//------------------------------------------------------------------------------

procedure THuffmanEncoder.EncodeString(const StrIn: String; var StrOut: String);
begin
EncodeMemory(PChar(StrIn),Length(StrIn) * SizeOf(Char),PChar(StrOut),Length(StrOut) * SizeOf(Char));
end;

//------------------------------------------------------------------------------

procedure THuffmanEncoder.EncodeStream(StreamIn: TStream; Count: Int64; StreamOut: TStream);
var
  InitCount:    Int64;
  BufferIn:     Pointer;
  BufferInTemp: Pointer;  
  BufferOut:    Pointer;
  BytesRead:    TMemSize;
  BytesIn:      TMemSize;
  BytesInTemp:  TMemSize;
  BytesOut:     TMemSize;
begin
If Assigned(StreamIn) then
  begin
    If Assigned(StreamOut) then
      begin
        If Count = 0 then
          Count := StreamIn.Size - StreamIn.Position;
        If Count < 0 then
          begin
            StreamIn.Seek(0,soBeginning);
            Count := StreamIn.Size;
          end;
        InitCount := Count;
        fBreakProcessing := False;
        DoEncodeProgress(0.0);
        If not fBreakProcessing then
          begin
            GetMem(BufferOut,fStreamBufferSize);
            try
              EncodeInit;
              If InitCount > 0 then
                begin
                  GetMem(BufferIn,fStreamBufferSize);
                  try
                    repeat
                      BytesRead := TMemSize(StreamIn.Read(BufferIn^,Min(fStreamBufferSize,Count)));
                      BufferInTemp := BufferIn;
                      BytesInTemp := BytesRead;
                      // process everything that was read
                      repeat
                        BytesIn := BytesInTemp;
                        BytesOut := fStreamBufferSize;
                        EncodeUpdate(BufferInTemp^,BytesIn,BufferOut^,BytesOut);
                        If TMemSize(StreamOut.Write(BufferOut^,BytesOut)) >= BytesOut then
                          begin
                            PtrAdvanceVar(BufferInTemp,BytesIn);
                            BytesInTemp := BytesInTemp - BytesIn;
                          end
                        else raise ESHBufferTooSmall.Create('THuffmanEncoder.EncodeStream: Output buffer too small.');
                      until (BytesInTemp <= 0) and (BytesOut <= 0);
                      Dec(Count,BytesRead); 
                      DoEncodeProgress((InitCount - Count) / InitCount);
                    until (BytesRead < fStreamBufferSize) or fBreakProcessing;
                finally
                  FreeMem(BufferIn,fStreamBufferSize);
                end;
              end;
              // there should be at max. only few bytes buffered at this point
              BytesOut := fStreamBufferSize;
              If EncodeFinal(BufferOut^,BytesOut) then
                begin
                  If TMemSize(StreamOut.Write(BufferOut^,BytesOut)) < BytesOut then
                    raise ESHBufferTooSmall.Create('THuffmanEncoder.EncodeStream: Output buffer too small.');
                end
              else ESHBufferTooSmall.Create('THuffmanEncoder.EncodeStream: Output buffer too small.');
            finally
              FreeMem(BufferOut,fStreamBufferSize);
            end;
            DoEncodeProgress(1.0);
          end;
      end
    else raise ESHInvalidValue.Create('THuffmanEncoder.EncodeStream: Output stream not assigned.');
  end
else raise ESHInvalidValue.Create('THuffmanEncoder.EncodeStream: Input stream not assigned.');
end;

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

procedure THuffmanEncoder.EncodeStream(StreamIn: TStream; StreamOut: TStream);
begin
EncodeStream(StreamIn,-1,StreamOut);
end;

//------------------------------------------------------------------------------

procedure THuffmanEncoder.EncodeFile(const FileNameIn,FileNameOut: String);
var
  FileStreamIn:   TFileStream;
  FileStreamOut:  TFileStream;
begin
FileStreamIn := TFileStream.Create(StrToRTL(FileNameIn),fmOpenRead or fmShareDenyWrite);
try
  FileStreamIn.Seek(0,soBeginning);
  FileStreamOut := TFileStream.Create(StrToRTL(FileNameOut),fmCreate or fmShareDenyWrite);
  try
    FileStreamOut.Seek(0,soBeginning);
    EncodeStream(FileStreamIn,FileStreamOut);
  finally
    FileStreamOut.Free;
  end;
finally
  FileStreamIn.Free;
end;
end;


end.
