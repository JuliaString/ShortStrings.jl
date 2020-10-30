export hash

import Base.hash

Base.hash(x::ShortString, h::UInt) = hash(String(x), h)
