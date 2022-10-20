function IOC(ciphe::Vector{Int64})
    uniquemems = collect(1:26)
    len = length(ciphe)
    sum = 0
    for i in uniquemems
       n = count(==(i), ciphe)
       sum += n * (n-1)
    end
    return (sum/(len*(len-1)))/26
end

function pIOC(ciphe::Vector{Int64}, n::Int64)
    avgIOC = 0
    for i in 1:n
        avgIOC += IOC(ciphe[i:n:end])
        println(ciphe[i:n:end])
    end
    return avgIOC/n
end
