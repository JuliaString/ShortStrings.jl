using ShortStrings
using BitIntegers: UInt256, UInt512, UInt1024, @define_integers
using Test, Random

include("getindex.jl")

function basic_test(constructor, max_len)
    @testset "$constructor" begin
        for string_type in (String, SubString{String})
            @testset "$string_type" begin
                basic_test(string_type, constructor, max_len)
            end
        end
    end
end

function basic_test(string_type, constructor, max_len)
    r = string_type.(randstring.(1:max_len))
    @test all(constructor.(r) .== r)
    @test all(hash(constructor.(r)) .== hash(r))

    a = constructor.(r)
    @test fsort(a) |> issorted

    @test collect(constructor("z"^max_len)) == fill('z', max_len)
    @test_throws ErrorException constructor("a"^(max_len+1))

    # equality
    @test constructor("c"^max_len) == "c"^max_len
    @test "c"^max_len == constructor("c"^max_len)
    @test constructor("c"^max_len) == constructor("c"^max_len)
    @test constructor("c"^max_len) != constructor("d"^max_len)
    @test constructor("c"^max_len) != constructor("c"^(max_len-1))
    @test constructor("c"^(max_len-1)) != constructor("c"^max_len)
    @test constructor("c"^max_len) != "c"^(max_len-1)
    @test constructor("c"^(max_len-1)) != "c"^max_len
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


@testset "equality of different sized ShortStrings" begin
    @test ShortString15("ab") == ShortString3("ab")
    @test ShortString3("ab") == ShortString15("ab")

    @test ShortString30("x") != ShortString3("y")
    @test ShortString30("y") != ShortString3("x")

    # this one is too big to fit in the other
    @test ShortString15("abcd") != ShortString3("ab")
    @test ShortString3("ab") != ShortString15("abcd")
end

@testset "cmp" begin
    @test cmp(ShortString3("abc"), ShortString3("abc")) == 0
    @test cmp(ShortString3("ab"), ShortString3("abc")) == -1
    @test cmp(ShortString3("abc"), ShortString3("ab")) == 1
    @test cmp(ShortString3("ab"), ShortString3("ac")) == -1
    @test cmp(ShortString3("ac"), ShortString3("ab")) == 1
    @test cmp(ShortString3("α"), ShortString3("a")) == 1
    @test cmp(ShortString3("b"), ShortString3("β")) == -1

    @test cmp(ShortString3("abc"), "abc") == 0
    @test cmp(ShortString3("ab"), "abc") == -1
    @test cmp(ShortString3("abc"), "ab") == 1
    @test cmp(ShortString3("ab"), "ac") == -1
    @test cmp(ShortString3("ac"), "ab") == 1
    @test cmp(ShortString3("α"), "a") == 1
    @test cmp(ShortString3("b"), "β") == -1
end

@testset "Construction from other ShortStrings" begin
    @test ShortString7(ShortString3("ab")) == "ab"
    @test ShortString7(ShortString3("ab")) isa ShortString7

    @test ShortString3(ShortString7("ab")) == "ab"
    @test ShortString3(ShortString7("ab")) isa ShortString3

    @test ShortString7(ShortString7("ab")) == "ab"
    @test ShortString7(ShortString7("ab")) isa ShortString7

    @test_throws ErrorException ShortString3(ShortString7("123456"))
end

@testset "promote rule" begin
    @test vcat(ShortString3["ab", "cd"], ShortString7["abcd", "efgc"]) ==  vcat(ShortString3["ab", "cd"], ["abcd", "efgc"])
    @test vcat(ShortString3["ab", "cd"], ShortString7["abcd", "efgc"]) ==  vcat(["ab", "cd"], ShortString7["abcd", "efgc"])
end
