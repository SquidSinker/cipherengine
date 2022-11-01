include("charspace.jl")
import Base.permutecols!!
mutable struct Transposition
    permutation::Vector{Int}
end
#IDK HOW TO STRUCTS IMA J MAKE THE FUNCTIONS
function columnar(permutation::Vector{Int}, vtoken::Vector{Int})
    A = reshape!(vtoken, (len(permutation),undef))
    A = Base.permutecols!!(A, permutation)
    A = transpose(A)
    return vec(A)
end

function scytale(n::Int, vtoken::Vector{Int})
    A = reshape!(vtoken,(n,undef))
    A = transpose(A)
    return vec(A)
end

function periodic(permutation::Vector{Int}, vtoken::Vector{Int})
    A = reshape!(vtoken,(n,undef))
    A = Base.permutecols!!(A, permutation)
    return vec(A)
end

function railfence(n::Int, vtoken::Vector{Int})
    A = reshape!(vtoken, (n-1,undef))
    A = vcat!(A, zeroes(n-1))
    #A = reverse_cols idk abt this one
    A = transpose(A)
    A = vec(A)
    return deleteat!(A, A .== 0)
end