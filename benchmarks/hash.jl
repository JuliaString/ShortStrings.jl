using ShortStrings, BenchmarkTools

# these two should be on par
@benchmark hash($(ShortString{UInt128}("this is a test")), $(zero(UInt)))
@benchmark hash($(rand(UInt128)), $(zero(UInt)))


# faster for some reason
@benchmark hash($"this is a test", $(zero(UInt)))


# these two should be on par
@benchmark hash($(ShortString{UInt128}("this is a test")))
@benchmark hash($(rand(UInt128)))


# faster
@benchmark hash($"this is a test")
