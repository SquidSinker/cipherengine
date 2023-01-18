include("cipher.jl")

mutable struct Diagonal <: AbstractCipher
    n::Int
    skew::Bool
    reverse::Bool

    inverted::Bool

    function Diagonal(n::Int, skew::Bool = false, reverse::Bool = false)
        new(n, skew, reverse, false)
    end
end
invert!(D::Diagonal) = switch_invert_tag!(D)


using LinearAlgebra

function get_diagonals(matrix::Matrix) ::Vector
    (a,b) = size(matrix)

    return [diag(matrix, n) for n in 1-a:b-1]
end

function fuse_diagonals(a::Int, b::Int, diagonals::Vector{Vector{Int}})
    diagm(a, b, [num => diag for (num, diag) in zip(1-a:b-1, diagonals)]...)
end

function apply(D::Diagonal, vect::Vector{Int}; safety_checks::Txt)
    if D.inverted
        new_tokens = copy(vect)

        a = D.n
        b = Int(length(vect) / D.n)

        diagonals = Vector{Vector{Int}}(undef, a + b - 1)

        diag_total = a + b - 1
        max_diag = min(a,b)
        for i in 1:diag_total
            if i < max_diag
                diagonals[i] = [popat!(new_tokens, 1) for _ in 1:i]
            elseif i > diag_total - max_diag
                diagonals[i] = [popat!(new_tokens, 1) for _ in 1:a + b - i]
            else
                diagonals[i] = [popat!(new_tokens, 1) for _ in 1:max_diag]
            end
        end

        if D.reverse
            reverse!.(diagonals)
        end

        new_tokens = fuse_diagonals(a, b, diagonals)

        if D.skew
            reverse(new_tokens; dims = 1)
        end

        return vec(new_tokens)

    else
        new_tokens = reshape(vect, (D.n, :))

        if D.skew
            reverse(new_tokens; dims = 1)
        end

        new_tokens = get_diagonals(new_tokens)

        if D.reverse
            reverse!.(new_tokens)
        end

        return vcat(new_tokens...)
    end
end