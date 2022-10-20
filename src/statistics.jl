include("charspace.jl")


function ioc(vtoken::Vector{Int64}, W::CSpace) ::Float64
    len = length(vtoken)
    sum = 0

    for i in 1:length(W)
       n = count(==(i), vtoken)
       sum += n * (n-1)
    end

    return sum / (len*(len-1)) / 26
end



function pioc(vtoken::Vector{Int64}, n::Int64, W::CSpace) ::Float64
    avgIOC = 0

    for i in 1:n
        avgIOC += ioc(vtoken[i:n:end], W)
    end

    return avgIOC / n
end


function whatioc(expectedv::Float64, vtoken::Vector{Int64}, W::CSpace, trynum::Int64) ::Int64
    #try up to j periodicities, compare with expected value, return value of n which gives closest ioc to expectedvalue of ioc 
    bestioc = abs(b1000000-expectedv) # difference between bestioc and expected v
    bestp = 1 #int of the most likely periodicity
    for i in 1:trynum
        # compare pioc of i with bestioc and see which one is closer to the expected ioc
        ipioc = abs(expectedv-pioc(vtoken,i,W))
        if ipioc < bestioc
            bestioc=i #ill try implement something which lists the second third etc likeliest periodicity with difference values later icba rn
        end
    end
    return bestioc
end