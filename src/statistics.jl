include("charspace.jl")


function ioc(vtoken::Vector{Int64}, W::CSpace) ::Float64
    len = length(vtoken)
    sum = 0

    for i in 1:length(W.tokenisation)
       n = count(==(i), vtoken)
       sum += n * (n-1)
    end

    return sum / (len*(len-1)) / 26
end



function periodic_ioc(vtoken::Vector{Int64}, n::Int64, W::CSpace) ::Float64
    avgIOC = 0

    for i in 1:n
        avgIOC += ioc(vtoken[i:n:end], W)
    end

    return avgIOC / n
end


function what_ioc(expectedv::Float64, vtoken::Vector{Int64}, W::CSpace, upper_lim::Int64) ::Int64
    #try up to j periodicities, compare with expected value, return value of n which gives closest ioc to expectedvalue of ioc 
    bestioc = abs(1000000-expectedv) # difference between bestioc and expected v
    bestp = 1 #int of the most likely periodicity
    for i in 1:upper_lim
        # compare periodic_ioc of i with bestioc and see which one is closer to the expected ioc
        iperiodic_ioc = abs(expectedv-periodic_ioc(vtoken,i,W))
        if iperiodic_ioc < bestioc
            bestioc=i #ill try implement something which lists the second third etc likeliest periodicity with difference values later icba rn
        end
    end
    return bestioc
end





# sum(weights) is SLOW FOR LARGE LISTS
# front weighted standard deviation: rooted avg of square difference of adjacent values, weighted by a decreasing geometric series
function fw_stdev(data::Vector, r = 0.5)
    weights = [r ^ i for i in 1:length(data)]
    w_total = sum(weights)

    mu = sum(weights .* data) / w_total

    var = sum( (data .- mu).^2 .* weights ) / w_total

    return sqrt(var)
end

# finds period by minimising fw_stdev for every n + ith item
function find_period(data::Vector, upper_lim::Int; mode = "best") ::Int

    errors = []

    for n in 1:upper_lim
        avg_error = 0

        for i in 1:n
            avg_error += fw_stdev(data[i:n:end], 1)
        end

        append!(errors, avg_error / n)
    end


    return argmin(errors)
end