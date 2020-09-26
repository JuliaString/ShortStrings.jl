# this is for keeping the basic functionalities

import Base:unsafe_getindex, ==, show, promote_rule

struct ShortString{T} <: AbstractString where T
    size_content::T
end


function ShortString{T}(s::Union{String, SubString{String}}) where T
    sz = sizeof(s)
    max_len = sizeof(T) - size_nibbles(T)
    if sz > max_len # the last byte is used to store the length
        throw(ErrorException("sizeof(::ShortString) must be shorter than or equal to $(max_len) in length; you have supplied a string of size $sz"))
    end
    bits_to_wipe = 8(sizeof(T) - sz)
    # TODO some times this can throw errors for longish strings
    # Exception: EXCEPTION_ACCESS_VIOLATION at 0x1e0b7afd -- bswap at C:\Users\RTX2080\.julia\packages\BitIntegers\xU40U\src\BitIntegers.jl:332 [inlined]
    # ntoh at .\io.jl:541 [inlined]
    content = (T(s |> pointer |> Ptr{T} |> Base.unsafe_load |> ntoh) >> bits_to_wipe) << bits_to_wipe
    ShortString{T}(content | T(sz))
end

String(s::ShortString) = String(reinterpret(UInt8, [s.size_content|>ntoh])[1:sizeof(s)])

Base.codeunit(s::ShortString) = codeunit(String(s))
Base.codeunit(s::ShortString, i) = codeunits(String(s), i)
Base.codeunit(s::ShortString, i::Integer) = codeunit(String(s), i)
Base.codeunits(s::ShortString) = codeunits(String(s))
Base.convert(::ShortString{T}, s::String) where T = ShortString{T}(s)
Base.convert(::String, ss::ShortString) = String(ss)
Base.display(s::ShortString) = display(String(s))
Base.firstindex(::ShortString) = 1
Base.isvalid(s::ShortString, i::Integer) = isvalid(String(s), i)
Base.iterate(s::ShortString) = iterate(String(s))
Base.iterate(s::ShortString, i::Integer) = iterate(String(s), i)
Base.lastindex(s::ShortString) = sizeof(s)
Base.ncodeunits(s::ShortString) = ncodeunits(String(s))
Base.print(s::ShortString) = print(String(s))
Base.show(io::IO, str::ShortString) = show(io, String(str))
Base.sizeof(s::ShortString{T}) where T = Int(s.size_content & size_mask(T))

size_nibbles(::Type{<:Union{UInt16, UInt32, UInt64, UInt128}}) = 1
size_nibbles(::Type{<:Union{Int16, Int32, Int64, Int128}}) = 1
size_nibbles(::Type{<:Union{UInt256, UInt512, UInt1024}}) = 2
size_nibbles(::Type{<:Union{Int256, Int512, Int1024}}) = 2
size_nibbles(::Type{T}) where T = ceil(log2(sizeof(T))/4)

size_mask(T) = UInt(exp2(4*size_nibbles(T)) - 1)


# function Base.getindex(s::ShortString, i::Integer)
#     getindex(String(s), i)
# end

# function Base.getindex(s::ShortString, args...; kwargs...)
#     getindex(String(s), args...; kwargs...)
# end

Base.collect(s::ShortString) = collect(String(s))

==(s::ShortString, b::AbstractString) = begin
    String(s) == b
end

promote_rule(::Type{String}, ::Type{ShortString{S}}) where S = String
promote_rule(::Type{ShortString{T}}, ::Type{ShortString{S}}) where {T,S} = ShortString{promote_rule(T,S)}

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

fsort(v::Vector{ShortString{T}}; rev = false) where T = sort(v, rev = rev, by = size_content, alg = RadixSort)
fsort!(v::Vector{ShortString{T}}; rev = false) where T = sort!(v, rev = rev, by = size_content, alg = RadixSort)

fsortperm(v::Vector{ShortString{T}}; rev = false) where T = sortperm(v, rev = rev)
