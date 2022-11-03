include("charspace.jl")
include("tuco.jl")

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

#################DEPRECATED#
# function what_ioc(expectedv::Float64, vtoken::Vector{Int64}, W::CSpace, upper_lim::Int64) ::Int64
#     #try up to j periodicities, compare with expected value, return value of n which gives closest ioc to expectedvalue of ioc 
#     bestioc = abs(1000000-expectedv) # difference between bestioc and expected v
#     bestp = 1 #int of the most likely periodicity
#     for i in 1:upper_lim
#         # compare periodic_ioc of i with bestioc and see which one is closer to the expected ioc
#         iperiodic_ioc = abs(expectedv-periodic_ioc(vtoken,i,W))
#         if iperiodic_ioc < bestioc
#             bestioc=i #ill try implement something which lists the second third etc likeliest periodicity with difference values later icba rn
#         end
#     end
#     return bestioc
# end
###########################






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

##########DEPRECATED#######
# finds period by minimising fw_stdev for every n + ith item
# function find_period(data::Vector{Float64},  upper_lim::Int) ::Int
#     upper_lim = min(upper_lim, length(data) - 1)

#     errors = Vector{Float64}(undef, upper_lim)

#     for n in 1:upper_lim
#         avg_error = 0

#         for i in 1:n
#             avg_error += fw_stdev(data[i:n:end], 0.5)
#         end

#         errors[n] = avg_error / n
#     end

#     print(errors)
#     errors .*= [10 ^ i for i in 1:upper_lim]
#     print(errors)

#     return argmin(errors)
# end
######################


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
    for int in 2:number
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
            break
        end
    end

    return factors
end

###################DEPRECATED#
# function rollavg(vtoken::Vector{Int64},#=W::Vector{Int64},=# W::CSpace, window::Int64)
#     println("AMONGUS")
#     tokens = W.tokens
#     #tokens = W
#     avglist = []
#     for t in tokens
#         tavglist = []
#         for i in 1:(length(vtoken)-(window))
#             push!(tavglist, count(x->x==t,vtoken[i:i+(window-1)]))
#         end
#         push!(avglist,tavglist)
#     end
#     return avglist
# end
##############################




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