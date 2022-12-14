using Plots
include("square_ciphers.jl")
include("tuco.jl")

key = lazy_tokenise("ABCDEFGHIKLMNOPQRSTUVWXYZ", Alphabet_CSpace)
cipher = ADFGX(key, 10 => 9, [1,4,6,2,3,5])

@load "jld2/very_orwell.jld2" very_orwell
tokenise!(very_orwell)

ciphertxt = cipher(very_orwell)

plot()

for i in 1:5
    plot!(char_distribution(ciphertxt, 3000, i))
end

plot!()