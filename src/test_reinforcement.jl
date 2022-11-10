include("reinforcement.jl")

using JLD2

@load "jld2/samples.jld2" orwell
@load "jld2/bigram_frequencies_vec.jld2" bigram_freq_vec

W = Bigram_CSpace

txt = orwell
tokenise!(txt, W)




S = Affine(3, 5, W)
#S = Substitution(Alphabet_CSpace)
apply!(S, txt)

@show S




println("Beginning test...")


# using BenchmarkTools
# @btime (PMatrix, cracked) = linear_reinforcement(txt, 100, 10, Choice_Weights, quadgramlog, eng, 3.0; lineage_habit = "floored ascent")



(PMatrix, cracked, fitnesses, divergences) = debug_linear_reinforcement(S, txt, 100, 2000, uniform_choice_weights, bibigramlog_arr, bigram_freq_vec, 7.0; lineage_habit = "floored ascent")
plot(fitnesses, label = "S fitness")
plot!(divergences / maximum(divergences), label = "ppM divergence")