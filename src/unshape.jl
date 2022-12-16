include("tuco.jl")
include("transposition.jl")


mutable struct Unshaper <: AbstractCipher
    columnar::ColumnarType
end
Unshaper(n::Int) = Unshaper(Columnar(n))

function apply(u::Unshaper, vect::Vector{Int}; safety_checks::Txt)
    new_tokens = unshape(vect, u.columnar)
    new_tokens = vec(new_tokens)

    return new_tokens
end