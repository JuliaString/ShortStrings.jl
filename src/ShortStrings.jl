module ShortStrings

using BitIntegers
using SortingAlgorithms
export fsort, fsort!, ShortString,
    ShortString3, ShortString7, ShortString15, ShortString30, ShortString62, ShortString126,
    @ss3_str, @ss7_str, @ss15_str, @ss30_str, @ss62_str, @ss126_str

export hash # from hash.jl

include("base.jl")
include("hash.jl")

end # module
