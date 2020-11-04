# this is for keeping the basic functionalities

using BitIntegers: @define_integers

import Base: unsafe_getindex, ==, show, promote_rule
using Base: @_inline_meta, @propagate_inbounds, @_propagate_inbounds_meta
import Base.GC: @preserve

struct ShortString{T} <: AbstractString where {T}
    size_content::T
end

# check if a string of size `sz` can be stored in ShortString{T}`
function check_size(T, sz)
    max_len = sizeof(T) - size_bytes(T)  # the last few bytes are used to store the length
    if sz > max_len
        throw(ErrorException("sizeof(::$T) must be shorter than or equal to $(max_len) in length; you have supplied a string of size $sz"))
    end
end

size_bytes(::Type{T}) where {T} = (count_ones(sizeof(T)-1)+7)>>3

size_mask(T) = T((1<<(size_bytes(T)*8)) - 1)
size_mask(s::ShortString{T}) where {T} = size_mask(T)

const CHUNKSZ   = sizeof(UInt)
const CHUNKBITS = sizeof(UInt) == 4 ? 32 : 64

@inline function _ss(::Type{T}, str::String, sz) where {T}
    if sizeof(T) <= sizeof(UInt)
        unsafe_load(reinterpret(Ptr{T}, pointer(str)))
    else
        pnt = reinterpret(Ptr{UInt}, pointer(str))
        fin = pnt + sz
        val = T(unsafe_load(pnt))
        off = CHUNKBITS
        while (pnt += CHUNKSZ) <= fin
            val |= T(unsafe_load(pnt)) << off
            off += CHUNKBITS
        end
        val
    end
end

# This can be optimized later, right now, it's just working 1 byte at a time
# to avoid accessing past the end
@inline function _ss(::Type{T}, str::SubString{String}, sz) where {T}
    pnt = pointer(str)
    fin = pnt + sz
    val = T(unsafe_load(pnt))
    off = 8
    while (pnt += 1) <= fin
        val |= T(unsafe_load(pnt)) << off
        off += 8
    end
    val
end

function ShortString{T}(s::Union{String,SubString{String}}) where {T}
    sz = sizeof(s)
    sz === 0 && return ShortString{T}(T(0))
    check_size(T, sz)
    bw = 8(sizeof(T) - sz)
    @preserve s ShortString{T}((ntoh(_ss(T, s, sz)) >>> bw) << bw | T(sz))
end

ShortString{T}(s::ShortString{T}) where {T} = s

function ShortString{T}(s::ShortString{S}) where {T, S}
    sz = sizeof(s)
    check_size(T, sz)
    # Flip it so empty bytes are at start, grow/shrink it, flip it back
    # size_mask(S) will return a mask for getting the size for Shorting Strings in (content size)
    # format, so something like 00001111 in binary.
    #  ~size_mask(S) will yield 11110000 which can be used as a mask to extract the content
    content = ntoh(T(ntoh(s.size_content & ~size_mask(S))))
    ShortString{T}(content | T(sz))
end

"""Amount to shift ShortString value by for each UInt sized chunk"""
const SHFT_INT = UInt === UInt32 ? 2 : 3

function String(s::ShortString{T}) where {T}
    len = sizeof(s)
    len === 0 && return ""
    val = ntoh(s.size_content)
    sv = Base.StringVector(len)
    # Loop over UInt64 sized chunks here
    pnt = reinterpret(Ptr{UInt}, pointer(sv))
    for i = 1:(len + sizeof(UInt) - 1) >>> SHFT_INT
        unsafe_store!(pnt, val % UInt)
        val >>>= SHFT_INT
        pnt += sizeof(UInt)
    end
    String(sv)
end

Base.codeunit(s::ShortString) = UInt8
Base.codeunit(s::ShortString, i) = codeunits(String(s), i)
Base.codeunit(s::ShortString, i::Integer) = codeunit(String(s), i)
Base.codeunits(s::ShortString) = codeunits(String(s))

Base.convert(::ShortString{T}, s::String) where {T} = ShortString{T}(s)
Base.convert(::String, ss::ShortString) = String(ss)

Base.sizeof(s::ShortString) = Int(s.size_content & size_mask(s))

Base.firstindex(::ShortString) = 1
Base.isvalid(s::ShortString, i::Integer) = isvalid(String(s), i)
Base.lastindex(s::ShortString) = sizeof(s)
Base.ncodeunits(s::ShortString) = sizeof(s)

Base.show(io::IO, str::ShortString) = show(io, String(str))

@inline function _get_word(s::ShortString{T}, i::Int) where {T}
    sz = sizeof(T)
    if sz <= 4
        # Shift up by 0-3 bytes
        (s.size_content%UInt32) << (8*(i + 3 - sz))
    else
        (s.size_content >>> (8*(sz - i - 3)))%UInt32
    end
end

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

@inline function Base.isascii(s::ShortString{T}) where {T}
    val = s.size_content >>> (8*size_bytes(T))
    for i in 1:(sizeof(T)-size_bytes(T))
        iszero(val & 0x80) || return false
        val >>>= 8
    end
    return true
end

function Base.length(s::ShortString{T}) where T
    isascii(s) && return ncodeunits(s)

    # else have to do it the hard way:
    i = 0
    len = 0
    while i < ncodeunits(s)
        shifted = s.size_content >>> (8*(sizeof(T) - i))
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

fsort(v::Vector{ShortString{T}}; rev = false) where {T} =
    sort(v, rev = rev, by = size_content, alg = RadixSort)
fsort!(v::Vector{ShortString{T}}; rev = false) where {T} =
    sort!(v, rev = rev, by = size_content, alg = RadixSort)

fsortperm(v::Vector{ShortString{T}}; rev = false) where {T} = sortperm(v, rev = rev)
