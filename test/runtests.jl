using rxciphers
using Test
using JLD2
include("test_results.jl")
BASE_FOLDER = dirname(dirname(pathof(rxciphers)))

@testset "rxciphers.jl" begin
    # Write your tests here.

    @load "jld2/samples.jld2"

    # NCharSpace
    t = orwell.raw
    T = Txt(t)
    @test tokenise!(T).tokenised == orwell_tokens
    @test untokenise!(T).raw == t

    # Substitution
    S = Substitution(26)
    @test S.mapping == collect(1:26)
    @test S.tokens == S.mapping
    @test S.size == 26

    @test Atbash(15).mapping == atbash_15_mapping

    Caesar_test = Caesar(2, 26)
    @test Caesar_test.mapping == caesar_2_26_mapping

    Affine_test = Affine(3, 5, Alphabet)
    @test Affine_test.mapping == affine_3_5_26_mapping

    tokenise!(orwell)

    caesar_enc = apply(Caesar_test, orwell)
    @test caesar_enc.tokenised == caesar_2_26_orwell_tokens
    @test crack_Caesar(caesar_enc) == Caesar_test

    affine_enc = apply(Affine_test, orwell)
    @test affine_enc.tokenised == affine_3_5_26_orwell_tokens
    @test crack_Affine(affine_enc) == Affine_test

    invert!(Affine_test)
    @test Affine_test.mapping == affine_3_5_26_mapping_inv

    @test Caesar(2, 10) + Caesar(3, 10) == Caesar(5, 10)
    @test frequency_matched_Substitution(orwell).mapping == freq_match_orwell_mapping

end
