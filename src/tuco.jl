#=

TUCO is a drug lord.
TUCO handles all statistical stuff, including fitness statistics

=#
using Statistics

jldstem = joinpath(@__DIR__, "..", "jld2")

using JLD2
@load abspath(joinpath(jldstem, "quadgram_scores.jld2")) quadgram_scores
@load abspath(joinpath(jldstem, "bigram_scores.jld2")) bigram_scores
@load abspath(joinpath(jldstem, "poogramfart_scores.jld2")) poogram_scores

@load abspath(joinpath(jldstem, "monogram_frequencies.jld2")) monogram_freq
@load abspath(joinpath(jldstem, "bigram_frequencies.jld2")) bigram_freq




# FREQUENCY ########################################

function appearances(token::Int, txt::Txt) ::Int
    if !txt.is_tokenised
        error("Cannot count token appearances in untokenised Txt")
    end

    return count(==(token), txt.tokenised)
end
function appearances(txt::Txt) ::Vector{Int}
    if !txt.is_tokenised
        error("Cannot count token appearances in untokenised Txt")
    end

    return [count(==(token), txt.tokenised) for token in txt.charspace.tokens]
end




function vector_frequencies(txt::Txt) ::Vector{Float64}
    return appearances(txt) / length(txt)
end

function frequencies(txt::Txt) ::Dict{String, Float64}
    freq = vector_frequencies(txt)
    return Dict(txt.charspace.chars .=> freq)
end





# ORDERLESS MEASURES #########################################

# Index of Coincidence
function ioc(txt::Txt) ::Float64
    len = length(txt)

    tallies = appearances(txt)
    summed = sum(tallies .* (tallies .- 1)) # sum of n(n-1)

    return summed / (len * (len-1)) # n(n-1)/N(N-1) un-normalised, doesnt account for size of W
end


# Periodic index of Coincidence
function periodic_ioc(txt::Txt, n::Int64) ::Float64
    avgIOC = 0

    for i in 1:n
        avgIOC += ioc(txt[i:n:end])
    end

    return avgIOC / n
end


# Cosine similarity of frequencies
function orthodot(txt::Txt, ref_frequencies::Vector{Float64} = monogram_freq; ordered = true) ::Float64
    frequencies = vector_frequencies(txt)

    if !ordered
        frequencies = sort(frequencies)
        ref_frequencies = sort(ref_frequencies)
    end

    magnitude = sum(frequencies .^ 2) * sum(ref_frequencies .^ 2)

    return sum(frequencies .* ref_frequencies) / sqrt(magnitude)
end

# BATCH BINOMIAL ###################################################################################

function batch_binomial_pd(X::Vector{Int}, N::Int, p::Float64) ::Vector{Float64}
    mu = N * p
    var = 2 * mu * (1 - p) # 2 carried through to reduce operations

    M = 7e2 - (maximum(X) - mu)^2 / var

    PX = [exp( M - (x - mu)^2 / var ) for x in X]

    PX = safe_normalise(PX)
    
    #PX[PX .== 0] .= 1e-300

    return PX
end

function safe_normalise(a::Vector) ::Vector
    s = sum(a)
    if s == 0 | isnan(s)
        L = length(a)
        return fill(1 / L, (L,))
    end
    return a / s
end



# batch binomial probabilities A[i,j] that token j represents i (forwards i -> j)
function bbin_probabilities(txt::Txt, ref_frequencies::Vector{Float64} = monogram_freq) ::Matrix{Float64}
    tallies = appearances(txt)
    L = length(txt)

    return permutedims(hcat([batch_binomial_pd(tallies, L, i) for i in ref_frequencies]...))
end



# PERIOD FINDING ALOGRITHM ############################################

# front weighted standard deviation: rooted avg of square difference of adjacent values, weighted by a decreasing geometric series
function fw_var(data::Vector, r = 0.5) ::Float64
    if r == 1
        return var(data)
    end

    weights = [r ^ i for i in 1:length(data)]
    # weight data in geometric series

    w_total = r * (1 - r ^ length(data)) / (1 - r)
    # Calculate sum of weights

    mu = sum(weights .* data) / w_total
    # find mean

    var = sum( (data .- mu).^2 .* weights ) / w_total

    return var
end
fw_std(data::Vector, r = 0.5) ::Float64 = sqrt(fw_var(data, r))



function find_period(data::Vector{Float64}, upper_lim::Int, sigma_threshold::Float64; weight_ratio ::Float64 = 0.65, silent::Bool = false) ::Union{Nothing, Int}
    upper_lim = min(upper_lim, length(data) - 1)
    # test until period > upper_lim

    threshold = fw_std(data, weight_ratio) * sigma_threshold

    for n in 1:upper_lim
        avg_std = 0.

        for i in 1:n
            avg_std += fw_std(data[i:n:end], weight_ratio)
            # Compare n-length chunks of data to themselves, find std
        end

        avg_std /= n

        if avg_std < threshold # if the periodic std is below the threshold
            if !silent
                println("ρ: ", round(avg_std / fw_std(data, weight_ratio); sigdigits = 3), " σ")
            end
            return n
            break
        end
    end

    return nothing
end
find_period(txt::Txt, upper_lim::Int, sigma_threshold::Float64; weight_ratio ::Float64 = 0.65, silent::Bool = false) = find_period(periodic_ioc.(Ref(txt), collect(1:upper_lim)), upper_lim, sigma_threshold; weight_ratio = weight_ratio, silent = silent)





# NUMERICAL ANALYSIS ################################################

# Finding divisors
function divisors(number::Int) ::Vector{Int}
    # Step 1: find all divisors
    divisors = []
    for int in 2:(number >> 1)
        if number % int == 0
            push!(divisors, int)
        end
    end

    push!(divisors, number)

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


# TEXT BLOCKING ANALYSIS ######################################

function blocks(txt::Txt, size::Int)
    return [txt[i - size + 1:i] for i in size:size:lastindex(txt)]
end

function block_apply_stats(f::Function, txt::Txt, block_size::Int)
    data = f.(blocks(txt, block_size))

    mean = mean(data)

    return mean , stdm(data, mean)
end




function rolling(f::Function, txt::Txt, window::Int) ::Vector
    L = length(txt)
    values = Vector(undef, L)
    wing = round(Int, window / 2)
    ########## IMPLEMENT EACHINDEX
    for i in 1:L
        start = i - wing
        final = i + wing

        if start < 1
            if final > L
                error("Window too large")
            end

            start = 1
            final = start + 2 * wing

        elseif final > L
            final = L
            start = final - 2 * wing
        end

        values[i] = f(txt[start:final])
    end

    return values
end


# STRING ANALYSIS ###################################

# Rolling average of data, sampled by window
rolling_average(data::Vector, window::Int) ::Vector{Float64} = real.(Conv1D_reals(data, ones(window) / window))


function char_distribution(txt::Txt, token::Int, window::Int) ::Vector{Float64}
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


function KMP_appearances(unit::Vector{T}, sequence::Vector{T}) where T
    search_index = 1
    ref_index = 1

    target_length = length(unit)

    L = lastindex(sequence)

    valid_pos = Vector{Int}()

    while search_index <= L # through whole text
        if unit[ref_index] == sequence[search_index] # current ind matches
            if ref_index == target_length # current ind is last ind
                push!(valid_pos, search_index - ref_index + 1) # save ind

                search_index += 1 # skip ahead search by unit length
                ref_index = 1 # reset window

            else # current ind is not last ind
                ref_index += 1 # check next ind
                search_index += 1
            end
        else # current ind does not match
            search_index += 1
            ref_index = 1
        end
    end

    return valid_pos
end

function repeat_units(txt::Txt, min_size::Int = 2) ::Dict{Vector{Int}, Int}
    if !txt.is_tokenised
        error("Txt must be tokenised to find repeat units")
    end

    vect = txt.tokenised
    L = lastindex(vect)

    window_start = 1
    window_end = min_size
    last_number = 0

    repeats = Dict{Vector{Int}, Int}()

    min_start_lengths = ones(Int, L) * min_size

    while window_start <= L - 2 * min_size + 1 # while window still repeatable

        window = vect[window_start:window_end]
        repeat_pos = KMP_appearances(window, vect[window_end + 1:end])
        number = length(repeat_pos)

        window_length = window_end - window_start + 1

        for i in repeat_pos # for places with the same start
            min_start_lengths[window_end + i] = window_length + 1 # start checking with length longer than now
        end


        if number == 0 # if no repeats still exist
            if last_number != 0 # if the last one had repeats
                repeats[window[begin:end - 1]] = last_number + 1 # take the last window

                for i in 1:window_length - min_size # start following checks with longer window sizes
                    min_start_lengths[window_start + i] = window_length - i
                end
    
            end

            window_start += 1 # advance search
            # set end so that length is minimum start
            window_end = window_start + min_start_lengths[window_start] - 1
            last_number = 0

        else # if repeats still exist
            window_end += 1 # elongate window
            last_number = number
        end

    end

    return repeats
end


# CODEPENDENCE ANALYSIS ###################################

# raw Substructure Variance
function substructure_variance(txt::Txt, n::Int, ref_frequencies::Vector{Float64} = monogram_freq)
    L = length(txt)

    txt_chunks = [txt[chunk_end - n + 1:chunk_end] for chunk_end in n:n:lastindex(txt)]
    N = ceil(Int, L / n)

    avg_variance = 0.0

    for token in txt.charspace.tokens
        f = ref_frequencies[token]
        var = var(appearances.(token, txt_chunks))

        avg_variance += f * var
    end

    return avg_variance

end

# Auto wrapped function to find sigma error in substruct (hypothesis test)
function substructure_sigma(txt::Txt, n::Int, ref_frequencies::Vector{Float64} = monogram_freq)
    L = length(txt)

    txt_chunks = [txt[chunk_end - n + 1:chunk_end] for chunk_end in n:n:lastindex(txt)]
    N = ceil(Int, L / n)

    avg_sigma_dev = 0.0

    for token in txt.charspace.tokens
        f = ref_frequencies[token]
        actual_var = var(appearances.(token, txt_chunks))
        expected_var = n * f * (1-f) * (1 - 1/N)
        sigma = expected_var / sqrt(N-1)

        avg_sigma_dev += f * (actual_var - expected_var) / sigma
    end

    return avg_sigma_dev

end







# FITNESS FUNCTIONS ########################################

function quadgramlog(txt::Txt; quadgram_scores::Array{Float64, 4} = quadgram_scores) ::Float64
    if txt.charspace != Alphabet
        error("Quadgramlog fitness only works on Alphabet")
    end

    L = length(txt) - 3

    score = 0.

    for i in 1:L
        score += quadgram_scores[ txt[i], txt[i+1], txt[i+2], txt[i+3] ]
    end

    return score / L
end


function bigramlog(T::Txt; bigram_scores::Array{Float64, 2} = bigram_scores)
    if T.charspace != Alphabet
        error("Bigramlog fitness only works on Alphabet")
    end

    sum = 0.

    L = length(T) - 1
    for i in 1:L
        sum += bigram_scores[T[i], T[i+1]]
    end

    return sum / L

end


function bibigramlog_arr(txt::Txt; bibigram_scores::Array{Float64, 2} = bibigram_scores_arr) ::Float64
    if txt.charspace != Bigram_CharSpace
        error("Bibigramlog fitness only works on Bigram_CharSpace")
    end

    L = length(txt) - 1

    score = 0.0
    for i in 1:L
        score += bibigram_scores[ txt.tokenised[i], txt.tokenised[i + 1] ]
    end

    return score / L
end












# 93% improvement
function poogramfart(txt::Txt; poogram_scores::Dict{Int, Float64} = poogram_scores) ::Float64
    if txt.charspace != Alphabet
        error("Poogramfart fitness only works on Alphabet")
    end

    L = length(txt) - 3

    score = 0.0
    for i in 1:L
        score += poogram_scores[ generate_structure_tag(txt.tokenised[i:i+3]) ]
    end

    return score / L
end

# Essentially a hashing algorithm
function generate_structure_tag(quadgram::Vector{Int}) ::Int
    tag = 0

    for (i, item) in enumerate(quadgram)
        ident = 0

        for j in 1:4
            ident |= ((quadgram[j] == item) << (j-1))
        end

        tag |= (ident << (4 * (i-1)))
    end

    return tag
end


# const nullfitness = log10(0.1/4224127912)
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




# fart_matrix = Dict{Int, Float64}()

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
#                 structure = generate_structure_tag([i,j,k,l])
#                 value = get(fart_matrix, structure, nothing)
#                 if isnothing(value)
#                     fart_matrix[structure] = 0.0
#                 end
#                 fart_matrix[structure] += quadgram_scores_arr[i,j,k,l]
#             end
#         end
#     end
# end
