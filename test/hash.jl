using ShortStrings: ShortString, hash
using Test


@test hash(ShortString(10)) == hash(UInt(10))
