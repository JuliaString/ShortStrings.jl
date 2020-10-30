module ShortStrings

using BitIntegers
using MurmurHash3: mmhash128_c
using SortingAlgorithms
export fsort, fsort!, ShortString,
    ShortString3, ShortString7, ShortString15, ShortString30, ShortString62, ShortString126,
    @ss3_str, @ss7_str, @ss15_str, @ss30_str, @ss62_str, @ss126_str

include("base.jl")

end # module
