#=

TUCO is a drug lord.
TUCO handles all statistical stuff, including fitness statistics

=#
include("charspace.jl")

using JLD2
@load "jld2/quadgram_scores.jld2" quadgram_scores_arr
@load "jld2/quadgram_scores_dict.jld2" quadgram_scores
@load "jld2/poogramfart_scores.jld2" fart_matrix
@load "jld2/monogram_frequencies.jld2" monogram_freq
@load "jld2/bigram_scores.jld2" bigram_scores
@load "jld2/bigram_frequencies.jld2" bigram_freq
@load "jld2/bibigram_scores_arr.jld2" bibigram_scores_arr


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






# Index of Coincidence
function ioc(txt::Txt) ::Float64
    if !txt.is_tokenised
        error("Txt must be tokenised to perform statistical tests")
    end

    len = length(txt)

    tallies = appearances.(txt.character_space.tokens, Ref(txt)) # n
    summed = sum(tallies .* (tallies .- 1)) # sum of n(n-1)

    return summed / (txt.character_space.size * len * (len-1)) # n(n-1)/N(N-1) normalised
end


# Periodic index of Coincidence
function periodic_ioc(txt::Txt, n::Int64) ::Float64
    avgIOC = 0

    for i in 1:n
        avgIOC += ioc(txt[i:n:end])
    end

    return avgIOC / n
end






# regular standard deviation
function stdev(data::Vector) ::Float64
    l = length(data)
    mu = sum(data) / l

    var = sum(data .^2) / l - mu ^ 2

    return sqrt(var)
end

# front weighted standard deviation: rooted avg of square difference of adjacent values, weighted by a decreasing geometric series
function fw_stdev(data::Vector, r = 0.5) ::Float64
    if r == 1
        return stdev(data)
    end

    weights = [r ^ i for i in 1:length(data)]
    # weight data in geometric series

    w_total = r * (1 - r ^ length(data)) / (1 - r)
    # Calculate sum of weights

    mu = sum(weights .* data) / w_total
    # find mean

    var = sum( (data .- mu).^2 .* weights ) / w_total

    return sqrt(var)
end



function find_period(data::Vector{Float64}, upper_lim::Int, tolerance::Float64; weight_ratio ::Float64 = 0.5) ::Union{Nothing, Int}
    upper_lim = min(upper_lim, length(data) - 1)
    # test until period > upper_lim

    threshold = fw_stdev(data, weight_ratio) * tolerance

    for n in 1:upper_lim
        avg_error = 0

        for i in 1:n
            avg_error += fw_stdev(data[i:n:end], weight_ratio)
            # Compare n-length chunks of data to themselves, find std_dev
        end

        avg_error /= n

        if avg_error < threshold # if the periodic std_dev is below the threshold
            return n
            break
        end
    end

    return nothing
end
find_period(txt::Txt, upper_lim::Int, tolerance::Float64) = find_period(periodic_ioc.(Ref(txt), collect(1:upper_lim)), upper_lim, tolerance)




# Finding divisors
function divisors(number::Int) ::Vector{Int}
    # Step 1: find all divisors
    divisors = []
    for int in 2:(number >> 1)
        if number % int == 0
            push!(divisors, int)
        end
    end

    return divisors
end




# Prime Factorisation Algorithm
function factorise(number::Int) ::Vector{Int}

    # Step 2 repeatedly divide from bottom up (2, 3, 5, 7...)
    factors = []
    for int in divisors(number)
        while number % int == 0
            push!(factors, int)
            number /= int
        end

        if number == 1
            return factors
        end
    end
end




# Rolling average of data, sampled by window
function rolling_average(data::Vector, window::Int) ::Vector{Float64}
    shortend = length(data) - window
    out = Vector{Float64}(undef, shortend)

    for start in 1:shortend
        out[start] = sum(data[start:start+window]) / window
    end

    return out
end


function char_distribution(txt::Txt, window::Int, token::Int) ::Vector{Float64}
    if !txt.is_tokenised
        error("Txt must be tokenised to perform statistical tests")
    end

    shortend = length(txt) - window
    out = Vector{Float64}(undef, shortend) # appearances of token in window

    for start in 1:shortend
        out[start] = appearances(token, txt[start:start+window]) / window
    end

    return rolling_average(out, window)
end


# Entropy
function entropy(txt::Txt)
    if !txt.is_tokenised
        error("Txt must be tokenised to perform statistical tests")
    end

    f = vector_frequencies(txt)
    entropy = sum( - f .* log2.(f))

    return entropy / txt.character_space.size
end












function orthodot(txt::Txt, ref_frequencies::Vector{Float64} = monogram_freq; ordered = true) ::Float64
    frequencies = vector_frequencies(txt)

    if !ordered
        frequencies = sort(frequencies)
        ref_frequencies = sort(ref_frequencies)
    end

    magnitude = sum(frequencies .^ 2) * sum(ref_frequencies .^ 2)

    return sum(frequencies .* ref_frequencies) / sqrt(magnitude)
end



const nullfitness = log10(0.1/4224127912)

function quadgramlog(txt::Txt) ::Float64
    if txt.character_space != Alphabet_CSpace
        error("Quadgramlog fitness only works on Alphabet_CSpace")
    end

    L = length(txt) - 3

    score = 0.0
    for i in 1:L
        score += get(quadgram_scores, txt.tokenised[i:(i+3)], nullfitness)
    end

    return score / L
end


function quadgramlog_arr(txt::Txt) ::Float64
    if txt.character_space != Alphabet_CSpace
        error("Quadgramlog fitness only works on Alphabet_CSpace")
    end

    L = length(txt) - 3

    score = 0.0
    for i in 1:L
        score += quadgram_scores_arr[ txt.tokenised[i:(i+3)]... ]
    end

    return score / L
end


function bibigramlog_arr(txt::Txt) ::Float64
    if txt.character_space != Bigram_CSpace
        error("Bibigramlog fitness only works on Bigram_CSpace")
    end

    L = length(txt) - 1

    score = 0.0
    for i in 1:L
        score += bibigram_scores_arr[ txt.tokenised[i], txt.tokenised[i + 1] ]
    end

    return score / L
end









function poogramfart(txt::Txt) ::Float64
    if txt.character_space != Alphabet_CSpace
        error("Poogramfart fitness only works on Alphabet_CSpace")
    end

    L = length(txt) - 3

    score = 0.0
    for i in 1:L
        score += fart_matrix[ txt.tokenised[i:(i+3)]... ]
    end

    return score / L
end


function poogramfast(txt::Txt) ::Float64
    if txt.character_space != Alphabet_CSpace
        error("Poogramfast fitness only works on Alphabet_CSpace")
    end

    L = length(txt) - 3

    score = 0.0
    for i in 1:L
        T = txt.tokenised[i:(i+3)]
        u = unique(T)
        replace!(T, collect(u[i] => i for i in 1:length(u))...)
        score += fart_matrix[T]
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


# quadgram_scores_arr = Array{Float64}(undef, 26, 26, 26, 26)

# for i in 1:26
#     for j in 1:26
#         for k in 1:26
#             for l in 1:26
#                 quadgram_scores_arr[i,j,k,l] = get(quadgram_scores, [i, j, k, l], nullfitness)
#             end
#         end
#     end
# end




# using JLD2
# @load "jld2/english_monogram_frequencies.jld2" eng
# # Vector with v[i] = j is the token index and j is the frequency




# fart_matrix = Dict{Vector{Int}, Float64}()

# quadgram_scores_arr = 10 .^ quadgram_scores_arr

# function determine_struct(quadgram::Vector{Int})
#     (i,j,k,l) = quadgram

#     structure = Vector{Int}(undef, 4)

#     iter = 1
#     while any(quadgram .!= 0)
#         first_token = quadgram[findfirst(!=(0), quadgram)]
#         indices = findall(==(first_token), quadgram)
#         structure[indices] .= iter
#         quadgram[indices] .= 0
#         iter += 1
#     end


#     return structure
# end

# for i in 1:26
#     for j in 1:26
#         for k in 1:26
#             for l in 1:26
#                 structure = determine_struct([i,j,k,l])
#                 value = get(fart_matrix, structure, nothing)
#                 if isnothing(value)
#                     fart_matrix[structure] = 0.0
#                 end
#                 fart_matrix[structure] += quadgram_scores_arr[i,j,k,l]
#             end
#         end
#     end
# end
