module rxciphers

# Write your package code here.



include("cracks.jl") # > genetics + substitution > array_f + tuco > cipher > charspace
export crack_Caesar, crack_Affine, crack_Vigenere, crack_Periodic_Affine
# cipher
export Encryption, AbstractCipher
export push!, iterate
export apply, apply!, invert, invert!
export Lambda, Retokenise, Reassign
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
export reduce, union
export getindex, ^, ==, +, show, length, iterate, setindex!, lastindex, copy
export Txt, tokenise, untokenise, tokenise!, untokenise!
export nchar!, nchar, reduce!

end
