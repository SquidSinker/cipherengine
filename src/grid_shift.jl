include("cipher.jl")

mutable struct GridShift <: AbstractCipher
    shifts::Vector{Int}
    col_length::Int
end

function shifter(v::Vector{Int}, shifts::Vector{Int})
    v = reshape(v, (length(shifts), :))

    for (i,j) in enumerate(shifts)
        v[i, :] = circshift(v[i, :], j)
    end

    return vec(v)
end

function apply(S::GridShift, vect::Vector{Int}; safety_checks::Txt)
    new_tokens = copy(vect)

    L = length(vect)
    block_l = length(S.shifts) * S.col_length

    if L % block_l != 0
        error("idk just fix")
    end

    blocks = [vect[1 + b - block_l:b] for b in block_l:block_l:lastindex(vect)]

    new_tokens = vcat([shifter(i, S.shifts) for i in blocks]...)

    return new_tokens
end