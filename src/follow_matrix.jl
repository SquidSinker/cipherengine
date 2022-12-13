#tryna implement follow matrix thing
#fm_score = follow matrix score
#=function fm_score(col1::Vector{Int}, col2::Vector{Int}) :: Float64
#make the follow matrix or sm idfk what its called
    @assert length(col1) == length(col2) "Lengths of both column vectors should be equal"
    followmatrix = []
    for i in 1:length(col1)
        push!(followmatrix, col1[i],col2[i])
    end
    fm_text
    #insert count bigram frequencies HERE
    #return bigram_freq
end
=#
include("tuco.jl")

function follow_score(col1::Vector{Int},col2::Vector{Int}) :: Float64
    #=
    col1,col2 -> followvec=[col1[1],col2[1],col1[2],col2[2]...]
    bigramify!(followvec)
    return bigramfitness(followvec)
    =#
    #@assert length(col1) == length(col2) "Lengths of both column vectors should be equal"
    sum = 0.
    for (a,b) in zip(col1,col2)
        sum += bigram_scores[a,b]
    end
    return sum
end

#=
    input: tuple/vector of vector{int} (columns)
    followmatrix[colj,colk] = P(colj then colk)
    iterate through columns, add entry to follow matrix
    set diagonals to -inf after
=#
function followmatrix(columns::Array{Int})
    n = length(columns[1])
    followmatrix = Array{Float64}(undef, (n,n))
    for i in 1:n
        for j in 1:n
            if i==j
                followmatrix[i,j] = -Inf64
            else
                followmatrix[i,j] = follow_score(columns[i,:n-1],columns[j,:n-1])
            end
        end
    end
    return followmatrix
end

#=
    search for lowest maximum in followmatrix
    maximum()
    argmin(maximum(arr;dims=1))
=#

function orderfollow(followmatrix::Array{Float64})
    n = size(followmatrix, 1)
    order = []
    worstcol = argmin(maximum(followmatrix;dims=1))
    push!(order, worstcol)
    while length(order)<n
        col = order[end]
        bestnextcol = argmax(followmatrix[:, col])
        push!(order, bestnextcol)
    end
end