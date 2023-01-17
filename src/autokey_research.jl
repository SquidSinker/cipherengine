using JLD2
include("keystream.jl")
include("tuco.jl")

@load "jld2/samples.jld2" orwell

tokenise!(orwell)
C = Autokey("BRONX", Alphabet)

ciphertxt = C(orwell)

entropies = Vector{Float64}(undef, 15)
temp_K = invert!(Keystream(ciphertxt))
for i in 1:15
    entropies[i] = ioc(temp_K(ciphertxt[i+1:end]))
end

using Plots
bar(entropies)