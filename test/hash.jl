using ShortStrings: ShortString, hash
using Test


@test ShortString(10) == hash(UInt(10))
