using JLD2

@load "english_monogram_frequencies.jld2" english_frequencies

alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
english_frequencies = Dict(enumerate(english_frequencies))

@save "english_monogram_frequencies_.jld2" english_frequencies