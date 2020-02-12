using ShortStrings
using Test, Random

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

@test ss15"Short String!!!" === ShortString15("Short String!!!")
@test ss7"ShrtStr" === ShortString7("ShrtStr")
@test ss3"ss3" === ShortString3("ss3")

@test_throws ErrorException ShortString{UInt128}("Short String!!!!")
@test_throws ErrorException ShortString15("Short String!!!!")
@test_throws ErrorException ss15"Short String!!!!"

@test_throws ErrorException ShortString{UInt64}("ShortStr")
@test_throws ErrorException ShortString7("ShortStr")
@test_throws ErrorException ss7"ShortStr"

@test_throws ErrorException ShortString{UInt32}("Short")
@test_throws ErrorException ShortString3("Short")
@test_throws ErrorException ss3"Short"
