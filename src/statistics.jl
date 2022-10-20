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
