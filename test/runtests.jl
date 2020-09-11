using ShortStrings
using BitIntegers: UInt256, UInt512, UInt1024, @define_integers
using Test, Random

function basic_test(constructor, max_len)
    @testset "$constructor" begin
        r = randstring.(1:max_len)
        @test all(constructor.(r) .== r)
        a = constructor.(r)
        @test fsort(a) |> issorted

        @test collect(constructor("z"^max_len)) == fill('z', max_len)
        @test_throws ErrorException constructor("a"^(max_len+1))
    end
end

basic_test(ShortString3, 3)
basic_test(ShortString7, 7)
basic_test(ShortString15, 15)
basic_test(ShortString30, 30)
basic_test(ShortString62, 62)
basic_test(ShortString126, 126)

basic_test(ShortString{UInt16}, 1)
basic_test(ShortString{UInt32}, 3)
basic_test(ShortString{UInt64}, 7)
basic_test(ShortString{UInt128}, 15)
basic_test(ShortString{UInt256}, 30)
basic_test(ShortString{UInt512}, 62)
basic_test(ShortString{UInt1024}, 126)

@define_integers 2048 MyInt2048 MyUInt2048
basic_test(ShortString{MyUInt2048}, 254)

@test ss126"Be honest, do you actually need a string longer than this. Seriously. C'mon this is pretty long." === ShortString126("Be honest, do you actually need a string longer than this. Seriously. C'mon this is pretty long.")
@test ss62"Basically a failly long string really" === ShortString62("Basically a failly long string really")
@test ss30"A Longer String!!!" === ShortString30("A Longer String!!!")

@test ss15"Short String!!!" === ShortString15("Short String!!!")
@test ss7"ShrtStr" === ShortString7("ShrtStr")
@test ss3"ss3" === ShortString3("ss3")
