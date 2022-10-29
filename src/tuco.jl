#=

TUCO is a drug lord.
TUCO handles all statistical stuff, including fitness statistics

=#
include("charspace.jl")


# FREQUENCY

function frequencies(txt::String) ::Dict{Char, Float64}
    W = unique(txt)

    freq = [count(isequal(i), txt) for i in W] / length(txt)

    return Dict(W .=> freq)
end



function appearances(token::Int, txt::Txt) ::Int
    if !txt.is_tokenised
        error("Cannot count token appearances in untokenised Txt")
    end

    return count(==(token), txt.tokenised)
end




function vector_frequencies(txt::Txt) ::Vector{Float64}
    if !txt.is_tokenised
        error("Cannot take token frequencies of untokenised Txt")
    end

    return appearances.(txt.character_space.tokens, Ref(txt)) / length(txt)
end

function frequencies(txt::Txt) ::Dict{Int, Float64}
    freq = vector_frequencies(txt)
    return Dict(txt.character_space.tokens .=> freq)
end





function to_dict(vect::Vector{T}) ::Dict{Int, T} where{T}
    return Dict(collect(1:length(vect)) .=> vect)
end

function sort_by_values(d::Dict)
    a = sort(collect(d), by = x -> x[2])
    return getindex.(a, 1)
end
# Returns Vector sorting elements of Dict in increasing value order






function orthodot(txt::Txt, ref_frequencies::Vector{Float64}) ::Float64
    frequencies = vector_frequencies(txt)

    magnitude = sum(frequencies .^ 2) * sum(ref_frequencies .^ 2)

    return sum(frequencies .* ref_frequencies) / sqrt(magnitude)
end



using JLD2
@load "jld2/quadgram_score_dict.jld2" quadgram_scores

const nullfitness = log10(0.1/4224127912)

function quadgramlog(txt::Txt) ::Float64
    if txt.character_space != Alphabet_CSpace
        error("Quadgramlog fitness only works on Alphabet_CSpace")
    end

    L = length(txt) - 3

    score = 0.0
    for i in 1:L
        score += get(quadgram_scores, txt[i:(i+3)], nullfitness)
    end

    return score / L
end






















# eng_quadgrams = Dict()

# alphabet = collect("ABCDEFGHIJKLMNOPQRSTUVWXYZ")

# open("english_quadgrams.txt") do file
#     for ln in eachline(file)
#         i,j = split(ln, " ")
#         i = [findfirst(x -> isequal(x, letter), alphabet) for letter in i]
#         j = parse(Int64, j)
#         eng_quadgrams[i] = log10(j/4224127912) # where 4224127912 is the total number of quadgrams
#     end
# end

# @save "jld2/quadgram_score_dict.jld2" quadgram_scores = eng_quadgrams




# using JLD2
# @load "jld2/english_monogram_frequencies.jld2" eng
# # Vector with v[i] = j is the token index and j is the frequency
