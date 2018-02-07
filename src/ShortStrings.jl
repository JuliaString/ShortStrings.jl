module ShortStrings

using SortingAlgorithms
export ShortString, ShortString15, ShortString7, ShortString3, fsort

struct ShortString{T} <: AbstractString where T
    size_content::T

    function ShortString{T}(s::String) where T
        sz = sizeof(s)
        if sz > sizeof(T) - 1 # the last byte is used to store the length
            throw(ErrorException("sizeof(::ShortString) must be shorter than or equal to $(sizeof(T) - 1) in length;
            you have supplied a string of size $sz"))
        end

        bits_to_wipe = 8(sizeof(T) - sz)

        content = (T(s |> pointer |> Ptr{T} |> Base.unsafe_load |> ntoh) >> bits_to_wipe) << bits_to_wipe

        new(content | T(sz))
    end

    ShorterString(s) = T(s)
end

Base.endof(s::ShortString) = Int(s.size_content & 0xf)
Base.next(s::ShortString{T}, i::Int) where T = (Char((s.size_content << 8(i-1)) >> 8*(sizeof(T)-1)), i + 1)
Base.sizeof(s::ShortString) = Int(s.size_content & 0xf)
Base.print(s::ShortString) = print(s.size_content)
Base.display(s::ShortString) = display(s.size_content)
Base.convert(::ShortString, s::String) = ShortString(s)
Base.convert(::String, ss::ShortString) = reduce(*, ss)
Base.start(::ShortString) = 1

size_content(s::ShortString) = s.size_content

const ShortString15 = ShortString{UInt128}
const ShortString7 = ShortString{UInt64}
const ShortString3 = ShortString{UInt32}


fsort(v::Vector{ShortString{T}}; rev = false) where T = sort(v, rev = rev, by = size_content, alg = RadixSort)

# struct ShorterString <: AbstractString
#     size_content::UInt64

#     function ShorterString(s::String)
#         sz = sizeof(s)
#         if sz > 7
#             throw(ErrorException("sizeof(::ShorterString) must be shorter than or equal to 7 in length; \
#             you have supplied a string of size $sz"))
#         end

#         content = (UInt64(s |> pointer |> Ptr{UInt64} |> Base.unsafe_load |> ntoh) >> 8(8 - sz)) << 8(8 - sz)

#         new(content | UInt64(sz))
#     end

#     ShorterString(s) = UInt64(s)
# end

# Base.endof(s::ShorterString) = Int(s.size_content & 0xf)
# Base.next(s::ShorterString, i::Int) = (Char((s.size_content << 8(i-1)) >> 8*7), i + 1)
# Base.sizeof(s::ShorterString) = Int(s.size_content & 0xf)
# Base.print(s::ShorterString) = print(s.size_content)
# Base.display(s::ShorterString) = display(s.size_content)
# Base.convert(::ShorterString, s::String) = ShorterString(s)
# Base.convert(::String, ss::ShorterString) = reduce(*, ss)
# Base.start(::ShorterString) = 1

end # module


