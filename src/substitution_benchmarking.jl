include("reinforcement.jl")


test_gen = 25
test_number = 150



using JLD2

@load "jld2/samples.jld2" orwell



txt = orwell
tokenise!(txt, Alphabet_CSpace)
# Prepare sample text


# target_S = Substitution("NSVZHEFGAWXYUBKOTPQCRLMIJD", Alphabet_CSpace)
# apply!(target_S, txt)
# # Apply Substitution

# inv_target_S = invert(target_S)




print("Beginning benchmark...")

fitnesses = Vector{Vector{Float64}}(undef, test_number)
solve_lengths = Vector{Int}(undef, test_number)

for i in 1:test_number
    rand_target = rand_substitution(26)
    rand_txt = apply(rand_target, orwell)


    ## RUN
    fit, gen = benchmark_linear_reinforcement(invert!(rand_target), rand_txt, test_gen,
    10,
    uniform_choice_weights,
    quadgramlog,
    monogram_freq,
    10.;
    lineage_habit = "floored ascent"
    )


    fitnesses[i] = fit
    solve_lengths[i] = gen

    println(i)
end


fitnesses = hcat(fitnesses...)

avg_fitness = sum(fitnesses, dims = 2) / test_number
stdev_solve = stdev(solve_lengths)
avg_solve = sum(solve_lengths) / test_number



name = "reinforcement_10_u_10_fa"

using DelimitedFiles
writedlm("sub_bench_" * name * ".csv", avg_fitness, ",")
println("Solved in average: $(avg_solve) generations (σ = $(stdev_solve))")



using Plots
plot(avg_fitness)