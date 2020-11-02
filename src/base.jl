# this is for keeping the basic functionalities

import Base: unsafe_getindex, ==, show, promote_rule

struct ShortString{T} <: AbstractString where {T}
    size_content::T
end

# check if a string of size `sz` can be stored in ShortString{T}`
function check_size(T, sz)
    max_len = sizeof(T) - size_nibbles(T)  # the last few nibbles are is used to store the length
    if sz > max_len
        throw(ErrorException("sizeof(::ShortString) must be shorter than or equal to $(max_len) in length; you have supplied a string of size $sz"))
    end
end

function ShortString{T}(s::Union{String, SubString{String}}) where {T}
    sz = sizeof(s)
    check_size(T, sz)
    bits_to_wipe = 8(sizeof(T) - sz)

    # Warning: if a SubString is at the very end of a string, which is at the end of allocated
    # memory, this can cause an access violation, by trying to access past the end
    # (for example, reading a 1 byte substring at the end of a length 119 string, could go past
    # the end)

    # TODO some times this can throw errors for longish strings
    # Exception: EXCEPTION_ACCESS_VIOLATION at 0x1e0b7afd -- bswap at C:\Users\RTX2080\.julia\packages\BitIntegers\xU40U\src\BitIntegers.jl:332 [inlined]
    # ntoh at .\io.jl:541 [inlined]
    content = (T(s |> pointer |> Ptr{T} |> Base.unsafe_load |> ntoh) >> bits_to_wipe) << bits_to_wipe
    ShortString{T}(content | T(sz))
end

ShortString{T}(s::ShortString{T}) where {T} = s
function ShortString{T}(s::ShortString{S}) where {T, S}
    sz = sizeof(s)
    check_size(T, sz)
    # Flip it so empty bytes are at start, grow/shrink it, flip it back
    # S(size_mask(S)) will return a mask for getting the size for Shorting Strings in (content size)
    # format, so something like 00001111 in binary.
    #  ~S(size_mask(S))) will yield 11110000 which can be used as maks to extract the content
    content = ntoh(T(ntoh(s.size_content & ~S(size_mask(S)))))
    ShortString{T}(content | T(sz))
end


String(s::ShortString) = String(reinterpret(UInt8, [s.size_content|>ntoh])[1:sizeof(s)])

Base.codeunit(s::ShortString) = UInt8
Base.codeunit(s::ShortString, i) = codeunits(String(s), i)
Base.codeunit(s::ShortString, i::Integer) = codeunit(String(s), i)
Base.codeunits(s::ShortString) = codeunits(String(s))

Base.convert(::ShortString{T}, s::String) where {T} = ShortString{T}(s)
Base.convert(::String, ss::ShortString) = String(ss)

Base.sizeof(s::ShortString{T}) where {T} = Int(s.size_content & (size_mask(s) % UInt))
Base.firstindex(::ShortString) = 1
Base.isvalid(s::ShortString, i::Integer) = isvalid(String(s), i)
Base.lastindex(s::ShortString) = sizeof(s)
Base.ncodeunits(s::ShortString) = sizeof(s)

Base.display(s::ShortString) = display(String(s))
Base.print(s::ShortString) = print(String(s))
Base.show(io::IO, str::ShortString) = show(io, String(str))

@inline _get_word(s::ShortString{T}, i::Int) where {T} =
           (s.size_content >> (8*(sizeof(T) - i - 3)))%UInt32

@inline function Base.iterate(s::ShortString, i::Int=1)
       0 < i <= ncodeunits(s) || return nothing
       chr = _get_word(s, i)
       chr < 0x8000_0000 ? (reinterpret(Char, chr & 0xFF00_0000), i + 1) :
           chr < 0xe000_0000 ? (reinterpret(Char, chr & 0xFFFF_0000), i + 2) :
           chr < 0xf000_0000 ? (reinterpret(Char, chr & 0xFFFF_FF00), i + 3) :
           (reinterpret(Char, chr), i + 4)
end

Base.sizeof(s::ShortString{T}) where T = Int(s.size_content & (size_mask(s) % UInt))
size_nibbles(::Type{<:Union{UInt16, UInt32, UInt64, UInt128}}) = 1
size_nibbles(::Type{<:Union{Int16, Int32, Int64, Int128}}) = 1
size_nibbles(::Type{<:Union{UInt256, UInt512, UInt1024}}) = 2
size_nibbles(::Type{<:Union{Int256, Int512, Int1024}}) = 2
size_nibbles(::Type{T}) where {T} = ceil(log2(sizeof(T))/4)

size_mask(T) = T(exp2(4*size_nibbles(T)) - 1)
size_mask(s::ShortString{T}) where {T} = size_mask(T)


# function Base.getindex(s::ShortString, i::Integer)
#     getindex(String(s), i)
# end

# function Base.getindex(s::ShortString, args...; kwargs...)
#     getindex(String(s), args...; kwargs...)
# end

Base.collect(s::ShortString) = collect(String(s))

function ==(s::ShortString{S}, b::Union{String, SubString{String}}) where {S}
    ncodeunits(b) == ncodeunits(s) || return false
    return s == ShortString{S}(b)
end
function ==(s::ShortString, b::AbstractString)
    # Could be a string type that might not use UTF8 encoding and that we don't have a
    # constructor for. Defer to equality that type probably has defined on `String`
    return String(s) == b
end

==(a::AbstractString, b::ShortString) = b == a
function ==(a::ShortString{S}, b::ShortString{S}) where {S}
    return a.size_content == b.size_content
end
function ==(a::ShortString{A}, b::ShortString{B}) where {A,B}
    ncodeunits(a) == ncodeunits(b) || return false
    # compare if equal after dropping size bits and
    # flipping so that the empty bytes are at the start
    ntoh(a.size_content & ~size_mask(A)) == ntoh(b.size_content & ~size_mask(B))
end

function Base.cmp(a::ShortString{S}, b::ShortString{S}) where {S}
    return cmp(a.size_content, b.size_content)
end

promote_rule(::Type{String}, ::Type{ShortString{S}}) where {S} = String

function promote_rule(::Type{ShortString{T}}, ::Type{ShortString{S}}) where {T,S}
    if sizeof(T) >= sizeof(S)
        return ShortString{promote_rule(T,S)}
    else
        return ShortString{promote_rule(S,T)}
    end
end

size_content(s::ShortString) = s.size_content

for T in (UInt1024, UInt512, UInt256, UInt128, UInt64, UInt32)
    max_len = sizeof(T) - size_nibbles(T)
    constructor_name = Symbol(:ShortString, max_len)
    macro_name = Symbol(:ss, max_len, :_str)

    @eval const $constructor_name = ShortString{$T}
    @eval macro $(macro_name)(s)
        Expr(:call, $constructor_name, s)
    end
end

fsort(v::Vector{ShortString{T}}; rev = false) where {T} =
    sort(v, rev = rev, by = size_content, alg = RadixSort)
fsort!(v::Vector{ShortString{T}}; rev = false) where {T} =
    sort!(v, rev = rev, by = size_content, alg = RadixSort)

fsortperm(v::Vector{ShortString{T}}; rev = false) where {T} = sortperm(v, rev = rev)
