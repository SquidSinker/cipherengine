#=

TUCO is a drug lord.
TUCO handles all statistical stuff, including fitness statistics

=#




# FREQUENCY

function frequencies(txt::String)
    W = unique(txt)

    freq = [count(isequal(i), txt) for i in W] / length(txt)

    return Dict(W .=> freq)
end

function frequencies(vtoken::Vector{Int})
    W = unique(vtoken)

    freq = [count(isequal(i), vtoken) for i in W] / length(vtoken)

    return Dict(W .=> freq)
end



function orthodot(freq1::Dict, freq2::Dict)
    V1, V2 = [values(freq1)], [values(freq2)]
    k = intersect(keys(freq1),keys(freq2))
    v1, v2 = [freq[i] for i in k], [freq2[i] for i in k]
    return dot(v1, v2)/sqrt(dot(V1, V1)*dot(V2, V2))
end

using JLD2

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

# @save "quadgram_score_dict.jld2" quadgram_scores = eng_quadgrams

@load "quadgram_score_dict.jld2" quadgram_scores

const nullfitness = log10(0.1/4224127912)

function quadgramlog(vtoken::Vector{Int}; quadgrams::Dict = quadgram_scores)
    @assert length(unique(vtoken)) <= 26

    k = keys(quadgrams)

    score = 0
    for i in 1:(length(vtoken)-3)
        gram = vtoken[i:(i+3)]
        if gram in k
            score += quadgrams[gram]
        else
            score += nullfitness
        end
    end

    return score / (length(vtoken) - 3)
end