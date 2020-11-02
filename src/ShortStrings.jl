module ShortStrings

using BitIntegers
using SortingAlgorithms

export fsort, fsort!, ShortString, ShortString3, ShortString7, ShortString15
export ShortString31, ShortString63, ShortString127, ShortString255
export @ss3_str, @ss7_str, @ss15_str, @ss31_str, @ss63_str, @ss127_str, @ss255_str

export ShortString30, ShortString62, ShortString126, @ss30_str, @ss62_str, @ss126_str

include("base.jl")

end # module
