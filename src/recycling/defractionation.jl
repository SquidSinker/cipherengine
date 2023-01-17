include("square_ciphers.jl")
include("tuco.jl")
include("cracks.jl")

t_key = [6,2,1,3,4,5]
key = lazy_tokenise("MNOPQRSTUVWXYZABCDEFGHIKL", Alphabet)
target = ADFGX(key, 10 => 9, t_key)

@load "jld2/samples.jld2" orwell
tokenise!(orwell)

ciphertxt = target(orwell)

################ BLINDFOLD

using Combinatorics
perms = collect(permutations(collect(1:length(t_key))))

blank_key = filter!(!=(10), collect(1:26))
trial = ADFGX(blank_key, 10 => 9, 4)

space = CharSpace("ADFGX")

unshuffle(permutation) = invert!(Encryption(Reassign(Alphabet, space^2), Retokenise(space ^ 2, space), Columnar(permutation)))

scores = Vector{Pair{Vector{Int}, Float64}}()

for trial in perms
    push!(scores, trial => orthodot(unshuffle(trial)(ciphertxt); ordered = false))
end

println("Correct transp key: ", t_key)
filter(x -> x[2] > 0.99, scores)