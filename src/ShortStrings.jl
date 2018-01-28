module ShortStrings

using SortingAlgorithms
export ShortString

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
# Base.sort(x::AbstractVector{ShortString}; kwargs...) = sort(x, by = x->x.size_content, alg = RadixSort; kwargs...)

end # module
