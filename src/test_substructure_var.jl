include("tuco.jl")
include("transposition.jl")

@load "jld2/samples.jld2" orwell f_random
tokenise!(orwell)
tokenise!(f_random)

# no_cipher = Lambda(identity, identity)
# column_1 = Columnar([5,1,3,2,4])
# column_2 = Columnar([4,3,1,2,5])
# matrix = Scytale(5)
# permute = Permutation([3,2,1,4,5])

# for cipher in (identity, column_1, column_2, matrix, permute)
#     println(:(cipher), " : ", substructure_sigma(cipher(orwell), 5))
# end

c = Columnar([1,6,4,2,3,5])
t = c(orwell)

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
