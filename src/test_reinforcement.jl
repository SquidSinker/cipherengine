include("reinforcement.jl")

using JLD2

@load "jld2/samples.jld2" orwell







txt = orwell
tokenise!(txt, Alphabet_CSpace)




S = Substitution("NSVZHEFGAWXYUBKOTPQCRLMIJD", Alphabet_CSpace)
#S = Substitution(Alphabet_CSpace)
apply!(S, txt)

@show S




println("Beginning test...")




# using BenchmarkTools
# @btime (PMatrix, cracked) = linear_reinforcement(txt, 100, 10, Choice_Weights, quadgramlog, eng, 3.0; lineage_habit = "floored ascent")



(PMatrix, cracked, fitnesses, divergences) = debug_linear_reinforcement(S, txt, 100, 10, uniform_choice_weights, quadgramlog, monogram_freq, 3.0; lineage_habit = "floored ascent")
plot(fitnesses, label = "S fitness")
plot!(divergences, label = "ppM divergence")