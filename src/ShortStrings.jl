module ShortStrings

using BitIntegers
using SortingAlgorithms

export fsort, fsort!, ShortString, ShortString3, ShortString7, ShortString15
export ShortString31, ShortString63, ShortString127, ShortString255
export @ss_str, @ss3_str, @ss7_str, @ss15_str, @ss31_str, @ss63_str, @ss127_str, @ss255_str

include("base.jl")

using MurmurHash3: mmhash128_a, mmhash32

function Base.hash(x::ShortString, h::UInt)
    h += Base.memhash_seed
@static if UInt === UInt64
    last(mmhash128_a(sizeof(x), bswap(x.size_content), h%UInt32)) + h
else
    mmhash32(sizeof(x), bswap(x.size_content), h%UInt32) + h
end
end

end # module
