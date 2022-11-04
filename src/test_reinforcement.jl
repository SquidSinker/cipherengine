include("reinforcement.jl")

using JLD2

@load "jld2/samples.jld2" orwell
@load "jld2/bigram_frequencies_vec.jld2" bigram_freq_vec




W = Alphabet_CSpace ^ 2

txt = orwell
tokenise!(txt, W)




S = Caesar(50, W)
#S = Substitution(Alphabet_CSpace)
apply!(S, txt)

@show S




println("Beginning test...")

function fitness(a::Txt) ::Float64
    txt = a
    untokenise!(txt)
    tokenise!(txt, Alphabet_CSpace)

    return quadgramlog(txt)
end



# using BenchmarkTools
# @btime (PMatrix, cracked) = linear_reinforcement(txt, 100, 10, Choice_Weights, quadgramlog, eng, 3.0; lineage_habit = "floored ascent")



(PMatrix, cracked, fitnesses, divergences) = debug_linear_reinforcement(S, txt, 500, 10, uniform_choice_weights, fitness, bigram_freq_vec, 7.0; lineage_habit = "floored ascent")
plot(fitnesses, label = "S fitness")
plot!(divergences, label = "ppM divergence")