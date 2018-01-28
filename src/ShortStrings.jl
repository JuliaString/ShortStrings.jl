module ShortStrings

using SortingAlgorithms
export ShortString, ShorterString

struct ShortString <: AbstractString
    size_content::UInt128

    function ShortString(s::String)
        sz = sizeof(s)
        if sz > 15
            throw(ErrorException("sizeof(::ShortString) must be shorter than or equal to 15 in length; \
            you have supplied a string of size $sz"))
        end

        content = (UInt128(s |> pointer |> Ptr{UInt128} |> Base.unsafe_load |> ntoh) >> 8(16 - sz)) << 8(16 - sz)

        new(content | UInt128(sz))
    end

    ShortString(s::U) where U <: Unsigned = UInt128(s)
end

Base.endof(s::ShortString) = Int(s.size_content & 0xf)
Base.next(s::ShortString, i::Int) = (Char((s.size_content << 8(i-1)) >> 8*15), i + 1)
Base.sizeof(s::ShortString) = Int(s.size_content & 0xf)
Base.print(s::ShortString) = print(s.size_content)
Base.display(s::ShortString) = display(s.size_content)
Base.convert(::ShortString, s::String) = ShortString(s)
Base.convert(::String, ss::ShortString) = reduce(*, ss)
Base.start(::ShortString) = 1

struct ShorterString <: AbstractString
    size_content::UInt64

    function ShorterString(s::String)
        sz = sizeof(s)
        if sz > 7
            throw(ErrorException("sizeof(::ShorterString) must be shorter than or equal to 7 in length; \
            you have supplied a string of size $sz"))
        end

        content = (UInt64(s |> pointer |> Ptr{UInt64} |> Base.unsafe_load |> ntoh) >> 8(8 - sz)) << 8(8 - sz)

        new(content | UInt64(sz))
    end

    ShorterString(s) = UInt64(s)
end

Base.endof(s::ShorterString) = Int(s.size_content & 0xf)
Base.next(s::ShorterString, i::Int) = (Char((s.size_content << 8(i-1)) >> 8*7), i + 1)
Base.sizeof(s::ShorterString) = Int(s.size_content & 0xf)
Base.print(s::ShorterString) = print(s.size_content)
Base.display(s::ShorterString) = display(s.size_content)
Base.convert(::ShorterString, s::String) = ShorterString(s)
Base.convert(::String, ss::ShorterString) = reduce(*, ss)
Base.start(::ShorterString) = 1

end # module


