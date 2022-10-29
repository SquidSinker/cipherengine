include("reinforcement.jl")

using JLD2

@load "jld2/samples.jld2" orwell







txt = orwell
tokenise!(txt, Alphabet_CSpace)




S = Substitution("ABKLMNOPQCRSVZHIJDEFGWXYUT", Alphabet_CSpace)
#S = Substitution(Alphabet_CSpace)
apply!(S, txt)

@show S




println("Beginning test...")



function Choice_Weights(t, F, n)
    return ones(n) / n
end

using JLD2
@load "jld2/english_monogram_frequencies.jld2" eng


# using BenchmarkTools
# @btime (PMatrix, cracked) = linear_reinforcement(txt, 100, 10, Choice_Weights, quadgramlog, eng, 3.0; lineage_habit = "floored ascent")



(PMatrix, cracked, fitnesses, divergences) = debug_linear_reinforcement(S, txt, 100, 10, Choice_Weights, quadgramlog, eng, 3.0; lineage_habit = "floored ascent")
plot(fitnesses, label = "S fitness")
plot!(divergences, label = "ppM divergence")