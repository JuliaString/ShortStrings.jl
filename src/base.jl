# this is for keeping the basic functionalities

using BitIntegers: @define_integers

import Base: unsafe_getindex, ==, show, promote_rule
using Base: @_inline_meta, @propagate_inbounds, @_propagate_inbounds_meta

struct ShortString{T} <: AbstractString where {T}
    size_content::T
end

# check if a string of size `sz` can be stored in ShortString{T}`
function check_size(T, sz)
    max_len = sizeof(T) - size_bytes(T)  # the last few nibbles are is used to store the length
    if sz > max_len
        throw(ErrorException("sizeof(::$T) must be shorter than or equal to $(max_len) in length; you have supplied a string of size $sz"))
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
    # size_mask(S) will return a mask for getting the size for Shorting Strings in (content size)
    # format, so something like 00001111 in binary.
    #  ~size_mask(S) will yield 11110000 which can be used as maks to extract the content
    content = ntoh(T(ntoh(s.size_content & ~size_mask(S))))
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
    typ = chr >>> 24
    if typ < 0x80
        (reinterpret(Char, chr & 0xFF00_0000), i + 1)
    elseif typ < 0xe0
        (reinterpret(Char, chr & 0xFFFF_0000), i + 2)
    elseif typ < 0xf0
        (reinterpret(Char, chr & 0xFFFF_FF00), i + 3)
    else
        (reinterpret(Char, chr), i + 4)
    end
end

size_bytes(::Type{T}) where {T} = (count_ones(sizeof(T)-1)+7)>>3

size_mask(T) = T((1<<(size_bytes(T)*8)) - 1)
size_mask(s::ShortString{T}) where {T} = size_mask(T)

@inline function Base.isascii(s::ShortString{T}) where {T}
    val = s.size_content << (8*size_bytes(T))
    for i in 1:sizeof(T)
        iszero(val & 0x80) || return false
        val <<= 8  # first byte never matters as will always be
    end
    return true
end

function Base.length(s::ShortString{T}) where T
    isascii(s) && return ncodeunits(s)

    # else have to do it the hard way:
    i = 0
    len = 0
    while i < ncodeunits(s)
        shifted = s.size_content >> (8*(sizeof(T) - i))
        i += if shifted % UInt8 <= 0x7f  # 1 byte character
            1
        elseif shifted % UInt16 <= 0x7ff  # 2 byte character
            2
        elseif shifted % UInt32 <= 0xffff  # 3 byte character
            3
        else  # 4 byte character
            4
        end
        len += 1
    end
    return len
end

@inline _get_word(s::ShortString{T}, i::Int) where {T} =
           (s.size_content >> (8*(sizeof(T) - i - 3)))%UInt32

@inline function _get_char(str::ShortString, pos::Int)
    chr = _get_word(str, pos)
    typ = chr >>> 28
    chr & ~ifelse(typ < 0x8, 0xffffff,
                  ifelse(typ < 0xe, 0x00ffff,
                         ifelse(typ < 0xf, 0x0000ff, 0x000000)))
end

@propagate_inbounds function Base.getindex(str::ShortString, pos::Int=1)
    @_inline_meta()
    @boundscheck checkbounds(str, pos)
    reinterpret(Char, _get_char(str, pos))
end

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

@define_integers 2048 Int2048 UInt2048

for T in (UInt2048, UInt1024, UInt512, UInt256, UInt128, UInt64, UInt32)
    max_len = sizeof(T) - size_bytes(T)
    constructor_name = Symbol(:ShortString, max_len)
    macro_name = Symbol(:ss, max_len, :_str)

    @eval const $constructor_name = ShortString{$T}
    @eval macro $(macro_name)(s)
        Expr(:call, $constructor_name, s)
    end
end

# These are simply for backwards compatibility reasons
#const ss30_str = ss31_str
#const ss62_str = ss63_str
#const ss126_str = ss127_str
const ShortString30  = ShortString31
const ShortString62  = ShortString63
const ShortString126 = ShortString127

fsort(v::Vector{ShortString{T}}; rev = false) where {T} =
    sort(v, rev = rev, by = size_content, alg = RadixSort)
fsort!(v::Vector{ShortString{T}}; rev = false) where {T} =
    sort!(v, rev = rev, by = size_content, alg = RadixSort)

fsortperm(v::Vector{ShortString{T}}; rev = false) where {T} = sortperm(v, rev = rev)
