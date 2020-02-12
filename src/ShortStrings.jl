__precompile__(true)
module ShortStrings

using SortingAlgorithms
export ShortString, ShortString15, ShortString7, ShortString3, fsort, fsort!,
       @ss15_str, @ss7_str, @ss3_str

import Base:unsafe_getindex, ==

struct ShortString{T} <: AbstractString where T
    size_content::T
end

function ShortString{T}(s::String) where T
    sz = sizeof(s)
    if sz > sizeof(T) - 1 # the last byte is used to store the length
        throw(ErrorException("sizeof(::ShortString) must be shorter than or equal to $(sizeof(T) - 1) in length; you have supplied a string of size $sz"))
    end
    bits_to_wipe = 8(sizeof(T) - sz)
    content = (T(s |> pointer |> Ptr{T} |> Base.unsafe_load |> ntoh) >> bits_to_wipe) << bits_to_wipe
    ShortString{T}(content | T(sz))
end

String(s::ShortString) = String(reinterpret(UInt8, [s.size_content|>ntoh])[1:sizeof(s)])

Base.lastindex(s::ShortString) = Int(s.size_content & 0xf)
Base.iterate(s::ShortString, i::Integer) = iterate(String(s), i)
Base.iterate(s::ShortString) = iterate(String(s))
Base.sizeof(s::ShortString) = Int(s.size_content & 0xf)
Base.print(s::ShortString) = print(String(s))
Base.display(s::ShortString) = display(String(s))
Base.convert(::ShortString{T}, s::String) where T = ShortString{T}(s)
Base.convert(::String, ss::ShortString) = String(a) #reduce(*, ss)
Base.firstindex(::ShortString) = 1
Base.ncodeunits(s::ShortString) = ncodeunits(String(s))
Base.codeunit(s::ShortString, i) = codeunits(String(s), i)
Base.isvalid(s::ShortString, i::Integer) = isvalid(String(s), i)

Base.getindex(s::ShortString{T}, i::Integer) where T = begin
    print(i)
    Char((s.size_content << 8(i-1)) >> 8(sizeof(T)-1))
end
Base.collect(s::ShortString) = getindex.(s, 1:lastindex(s))

==(s::ShortString, b::String) = begin
    String(s)  == b
end

size_content(s::ShortString) = s.size_content

const ShortString15 = ShortString{UInt128}
const ShortString7 = ShortString{UInt64}
const ShortString3 = ShortString{UInt32}

# ss15"ShortString15"
macro ss15_str(s)
    :(ShortString15($s))
end

# ss7"Short7"
macro ss7_str(s)
    :(ShortString7($s))
end

# ss3"ss3"
macro ss3_str(s)
    :(ShortString3($s))
end

fsort(v::Vector{ShortString{T}}; rev = false) where T = sort(v, rev = rev, by = size_content, alg = RadixSort)
fsort!(v::Vector{ShortString{T}}; rev = false) where T = sort!(v, rev = rev, by = size_content, alg = RadixSort)

fsortperm(v::Vector{ShortString{T}}; rev = false) where T = sortperm(v, rev = rev)

end # module
