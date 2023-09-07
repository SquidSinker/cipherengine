module RxCiphers

include("cipher.jl") # -> charspace.jl (NCharSpace & Txt)
include("array functions.jl")
include("tuco.jl")
include("periodic substitution.jl") # -> substitution.jl (Substitution)
include("permutation.jl")
include("matrix transposition.jl")
include("cracks.jl") # -> genetics.jl
export crack_Caesar, crack_Affine
export crack_Vigenere, crack_Periodic_Affine
# cipher
export Encryption, AbstractCipher
export push!, iterate
export apply, apply!, invert, invert!
export Lambda, Retokenise, Reassign
# permutation
export Permutation, invPermutation
# matrix transposition
export MatrixTransposition
# periodic substitution
export PeriodicSubstitution, Vigenere, Periodic_Affine
export length, getindex, iterate, setindex!, ==, show
export apply, invert!
# substitution
export Substitution, frequency_matched_Substitution, Atbash, Caesar, Affine
export apply, length, +, -, ==, show, getindex, iterate, invert!, shift!, switch, switch!, mutate, mutate!
# tuco
export quadgramlog, bigramlog, poogramfart, orthodot
export monogram_freq, bigram_freq, bigram_scores, quadgram_scores, poogram_scores
export appearances, frequencies, vector_frequencies
export ioc, periodic_ioc
export bbin_probabilities
export find_period
export divisors, factorise
export blocks, block_apply_stats, rolling, rolling_average, char_distribution, KMP_appearances, repeat_units
export substructure_variance, substructure_sigma
# charspace
export NCharSpace, CharSpace, Alphabet, Decimal, Hexadecimal
export union
export getindex, ^, ==, +, show, length, iterate, setindex!, lastindex, copy
export Txt, tokenise, untokenise, tokenise!, untokenise!, checktoken
export nchar!, nchar
export TokeniseError, checktokenised
# array functions
export switch, switch!
export safe_reshape_2D
export checkperm
export affine
export normalise!
# text samples
include("samples.jl")
export TxtSamples

end

# CURRENTLY SUPPORTED
# Monoalphabetic Substitution (inc. Caesar, Affine, Atbash)
# Polyalphabetic Substitution (inc. Vigenere, PAffine)
# Permutation Transposition

# TO ADD
# Fix the include tree it is horrible

# Matrix Transposition (and Columnar)
# Stupid Transpositions (Scytale, Redefence)
# Square Ciphers

# Nihilist set (subst. transp.)
# Keystream (generator; Autokey; OTP)
# Grid Shift (therefore Cadenus)
# Diagonal cipher
# Convolution (token safe)

# bruteforce + optimise function