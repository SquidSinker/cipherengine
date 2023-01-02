include("charspace.jl")
include("cipher.jl")
include("substitution.jl")
import Base.show
using Combinatorics





# Scytale, Periodic and Columnar
mutable struct Permutation <: AbstractCipher
    n::Int
    permutation::Vector{Int}

    remove_nulls::Bool
    inverted::Bool

    # UNSAFE DO NOT USE
    function Permutation(n::Int, permutation::Vector{Int}, remove_nulls::Bool = false)
        if !isperm(permutation)
            e = ArgumentError("Not a permutation")
            throw(e)
        end

        new(n, permutation, remove_nulls, false)
    end
    # UNSAFE DO NOT USE


end
Permutation(permutation::Vector{Int}, remove_nulls::Bool = false) = Permutation(length(permutation), permutation, remove_nulls)
Permutation(n::Int, remove_nulls::Bool = false) = Permutation(n, collect(1:n), remove_nulls)

function invert!(P::Permutation)
    switch_invert_tag!(P)
    P.permutation = invperm(P.permutation)
end


function switch(S::Permutation, posa::Int, posb::Int) ::Permutation
    return Permutation(S.n, switch(S.permutation, posa, posb), S.remove_nulls)
end

function switch!(S::Permutation, posa::Int, posb::Int) ::Permutation
    switch!(S.permutation, posa, posb)
    return S
end



function show(io::IO, T::Permutation)
    show(io, T.permutation)
end

function show(io::IO, ::MIME"text/plain", T::Permutation)
    println(io, "$(T.n)-element Permutation:")
    show(io, T.permutation)
end


function safe_reshape_2D(vector::Vector{T}, dim::Int, null_token::Int) ::Matrix{T} where T
    r = length(vector) % dim
    if r != 0
        vector = copy(vector)
        append!(vector, fill(null_token, dim - r))
    end

    return reshape(vector, (dim, :))
end

function reinsert_nulls(vect::Vector{Int}, T::Permutation) ::Vector{Int}
    L = length(vect)
    overhang = L % T.n

    if overhang == 0
        return vect
    end

    vector = copy(vect)

    null_ends = T.permutation .> overhang

    num_full_rows = floor(Int, L / T.n)

    for (i,j) in enumerate(null_ends)
        if j
            insert!(vector, num_full_rows * T.n + i, NULL_TOKEN)
        end
    end

    return vector
end



function unshape(vect::Vector{Int}, T::Permutation) ::Matrix{Int}
    new_tokens = reinsert_nulls(vect, T)
    new_tokens = reshape(new_tokens, (T.n, :))

    return new_tokens
end



function apply(T::Permutation, vect::Vector{Int}; safety_checks::Txt) ::Vector{Int}
    if T.inverted # inverse application
        new_tokens = unshape(vect, T)
        new_tokens = vec(new_tokens[inv_permutation, :])

        if T.remove_nulls
            return filter!(!=(NULL_TOKEN), new_tokens)
        else
            return new_tokens
        end

    else # regular application
        new_tokens = safe_reshape_2D(vect, T.n, NULL_TOKEN)
        new_tokens = new_tokens[T.permutation, :]

        new_tokens = vec(new_tokens)

        if T.remove_nulls
            return filter!(!=(NULL_TOKEN), new_tokens)
        else
            return new_tokens
        end

    end

end