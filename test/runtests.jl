using ShortStrings
using Test, Random

# write your own tests here
r = randstring.(1:15)
@test all(ShortString15.(r) .== r)
a = ShortString15.(r)
@test fsort(a) |> issorted

r = randstring.(1:7)
@test all(ShortString7.(r) .== r)
a = ShortString7.(r)
@test fsort(a) |> issorted

r = randstring.(1:3)
@test all(ShortString{UInt32}.(r) .== r)
a = ShortString{UInt32}.(r)
@test fsort(a) |> issorted

@test all(ShortString3.(r) .== r)
a = ShortString3.(r)
@test fsort(a) |> issorted



@test collect(ShortString3("abc")) == ['a', 'b', 'c']
