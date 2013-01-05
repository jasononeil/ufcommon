package ufcommon.db;

class Types
{

}

// A complete copy of sys.db.Types, but available for client targets too...

// basic types

/** int with auto increment **/
typedef SId = Int

/** int unsigned with auto increment **/
typedef SUId = Int

/** big int with auto increment **/
typedef SBigId = Float

typedef SInt = Int

typedef SUInt = Int

typedef SBigInt = Float

/** single precision float **/
typedef SSingle = Float

/** double precision float **/
typedef SFloat = Float

/** use tinyint(1) to distinguish with int **/
typedef SBool = Bool

/** same as varchar(n) **/
typedef SString<Const> = String

/** date only, use SDateTime for date+time **/
typedef SDate = Date

/** mysql DateTime **/
typedef SDateTime = Date

/** mysql Timestamp **/
typedef STimeStamp = Date

/** TinyText (up to 255 bytes) **/
typedef STinyText = String

/** Text (up to 64KB) **/
typedef SSmallText = String

/** MediumText (up to 24MB) **/
typedef SText = String

/** Blob type (up to 64KB) **/
typedef SSmallBinary = haxe.io.Bytes

/** LongBlob type (up to 4GB) **/
typedef SLongBinary = haxe.io.Bytes

/** MediumBlob type (up to 24MB) **/
typedef SBinary = haxe.io.Bytes

/** same as binary(n) **/
typedef SBytes<Const> = haxe.io.Bytes

/** one byte signed [-128...127] **/
typedef STinyInt = Int

/** two bytes signed [-32768...32767] **/
typedef SSmallInt = Int;

/** three bytes signed [-8388608...8388607] **/
typedef SMediumInt = Int;

/** one byte [0...255] **/
typedef STinyUInt = Int

/** two bytes [0...65535] **/
typedef SSmallUInt = Int;

/** three bytes [0...16777215] **/
typedef SMediumUInt = Int;

// extra

/** specify that this field is nullable **/
typedef SNull<T> = T

/** specify that the integer use custom encoding **/
typedef SEncoded = Int

/** haxe Serialized string **/
typedef SSerialized = String

/** native neko serialized bytes **/
typedef SNekoSerialized = haxe.io.Bytes

/** a set of bitflags of different enum values **/
typedef SFlags<T:EnumValue> = haxe.EnumFlags<T>

/** same as [SFlags] but will adapt the storage size to the number of flags **/
typedef SSmallFlags<T:EnumValue> = SFlags<T>;

/** allow to store any value in serialized form **/
typedef SData<T> = T

/** allow to store an enum value that does not have parameters as a simple int **/
typedef SEnum<E:EnumValue> = E

