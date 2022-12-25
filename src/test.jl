using Test
include("test_results.jl")

include("charspace.jl")
include("substitution.jl")
include("periodic_substitution.jl")
include("cracks.jl")
include("tuco.jl")
include("transposition.jl")

@load "jld2/samples.jld2" orwell
const NULL_TXT = Txt("")

function test_cspace()
    t = orwell.raw
    T = Txt(t)
    @test tokenise!(T).tokenised == orwell_tokens
    @test untokenise!(T).raw == t

    return nothing
end

function test_substitution()
    S = Substitution(26)
    @test S.mapping == collect(1:26)
    @test S.tokens == S.mapping
    @test S.size == 26

    @test Atbash(15).mapping == atbash_15_mapping

    Caesar_test = Caesar(2, 26)
    @test Caesar_test.mapping == caesar_2_26_mapping

    Affine_test = Affine(3, 5, Alphabet_CSpace)
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
    @test frequency_matched_substitution(orwell).mapping == freq_match_orwell_mapping

    return nothing
end

function test_periodic_substitution()
    tokenise!(orwell)

    Vigenere_test = Vigenere("ABBA", Alphabet_CSpace)
    @test [i.mapping for i in Vigenere_test] == vigenere_ABBA_mappings

    Periodic_Affine_test = Periodic_Affine([1,3,5], [7,6,5], 26)
    @test [i.mapping for i in Periodic_Affine_test] == periodic_affine_123_765_mappings

    vigenere_enc = Vigenere_test(orwell)
    @test vigenere_enc.tokenised == vigenere_ABBA_orwell_tokens
    @test crack_Vigenere(vigenere_enc) == Vigenere_test

    periodic_affine_enc = Periodic_Affine_test(orwell)
    @test periodic_affine_enc.tokenised == periodic_affine_123_765_orwell_tokens
    @test crack_Periodic_Affine(periodic_affine_enc) == Periodic_Affine_test

    return nothing
end

function test_transposition()
    tokenise!(orwell)

    Columnar_test = Columnar([1,4,3,2])
    columnar_enc = Columnar_test(orwell)
    @test columnar_enc.tokenised == columnar_1432_orwell_tokens

    invert!(Columnar_test)
    @test Columnar_test(columnar_enc).tokenised == orwell_tokens

    Permutation_test = Permutation([1,5,3,2,4])
    permutation_enc = Permutation_test(orwell)
    @test permutation_enc.tokenised == permutation_15324_orwell_tokens

    invert!(Permutation_test)
    @test Permutation_test(permutation_enc).tokenised == orwell_tokens

    println("AMSCO, Railfence remain untested")

    return nothing
end