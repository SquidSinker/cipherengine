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

# using Plots
# range = 2:20
# x = collect(range)

# unshaped = [Unshaper(n)(t) for n in range]

# data = [substructure_sigma(txt,n) for (txt,n) in zip(unshaped, range)]



# bar(x, data)
