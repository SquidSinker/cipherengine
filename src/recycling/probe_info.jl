include("reinforcement.jl")

using JLD2

@load "jld2/samples.jld2" orwell







txt = orwell
tokenise!(txt, Alphabet)
ref = quadgramlog(orwell)



S = Substitution("EFGWXZDHIJANOUYVBKLMTPQCRS", Alphabet)
#S = Substitution(Alphabet)
apply!(S, txt)

println(invert(S))


using JLD2
@load "jld2/english_monogram_frequencies.jld2" eng

fitnesses = Vector{Float64}()
densities = Vector{Float64}()

for mu in 1:20
    for reps in 1:15
        test = invert(S)
        for _ in 1:mu
            mutate!(test)
        end

        (f, density) = probe_info_density(test, S, orwell, quadgramlog, ref)
        # println(f, " gives density ", density)
        push!(fitnesses, f)
        push!(densities, density)
    end
    println("Completed mutagen level: $(mu)")
end

scatter(fitnesses, densities)

using DelimitedFiles

writedlm("fitnesses.csv",  fitnesses, ',')
writedlm("information_densities.csv",  densities, ',')