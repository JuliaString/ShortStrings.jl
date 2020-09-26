export hash

import Base.hash

Base.hash(x::ShortString, args...; kwargs...) = hash(x.size_content, args...; kwargs...)

Base.hash(x::ShortString, h::UInt) = hash(x.size_content, h)
