using MurmurHash3: mmhash128_a

function Base.hash(x::ShortString, h::UInt)
    h += Base.memhash_seed
    last(mmhash128_a(sizeof(x), bswap(x.size_content), h%UInt32)) + h
end
