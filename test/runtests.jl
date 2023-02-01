using RxCiphers
using Test
using JLD2
include("test results.jl")

@testset "RxCiphers.jl" begin

    @load "jld2/samples.jld2"

    # NCharSpace
    t = orwell.raw
    T = Txt(t)
    @test tokenise!(T).tokenised == orwell_tokens
    @test untokenise!(T).raw == t

    W_test = CharSpace(["1", "2", "3"])
    W_squared = W_test ^ 2
    @test W_squared.charmap == w_squared_charmap
    @test W_squared.reducemap[2, 3] == 8
    @test W_squared.reducemap[8] == [2, 3]
    @test W_squared.units == W_test.charmap
    @test nchar(W_squared, 1) == W_test
    # Remains:
    # Txt nchar
    # union
    # Base. overloads



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
    # Remains:
    # shift, switch, mutate
    # Base. overloads



    # Periodic Substitution
    tokenise!(orwell)

    Vigenere_test = Vigenere("ABBA", Alphabet)
    @test [i.mapping for i in Vigenere_test] == vigenere_ABBA_mappings

    Periodic_Affine_test = Periodic_Affine([1,3,5], [7,6,5], 26)
    @test [i.mapping for i in Periodic_Affine_test] == periodic_affine_123_765_mappings

    vigenere_enc = Vigenere_test(orwell)
    @test vigenere_enc.tokenised == vigenere_ABBA_orwell_tokens
    @test crack_Vigenere(vigenere_enc) == Vigenere_test

    periodic_affine_enc = Periodic_Affine_test(orwell)
    @test periodic_affine_enc.tokenised == periodic_affine_123_765_orwell_tokens
    @test crack_Periodic_Affine(periodic_affine_enc) == Periodic_Affine_test
    # Remains:
    # Base. overloads

    # AbstractCipher & Encryption

    # Remains:
    # __constr__
    # push!, iterate
    # apply, invert
    # Lambda, Retokenise, Reassign

    # Tuco

    # Remains:
    # __gramlogs, orthodot
    # appearances, frequencies
    # ioc, periodic_ioc
    # bbin_probabilities
    # find_period (retested in Periodic Substitution)
    # divisors, factorise
    # blocks, block_apply_stats, rolling, rolling_average, char_distribution
    # substructure_sigma, substructure_variance

    # Array functions

    # Remains:
    # switch, switch!
    # safe_reshape_2D
    # checkperm
    # affine
    # normalise!
end
