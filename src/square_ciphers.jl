include("substitution.jl")
include("transposition.jl")




function issquare(int::Int) ::Bool
    return isqrt(int) ^ 2 == int
end

Replace(map::Pair{Int, Int}) = Lambda(x -> x == map[1] ? map[2] : x, identity)





function Square(square_key::Vector{Int}, replace::Vector{Pair{Int, Int}}; square_indices::Vector{Char})
    if !issquare(length(square_key))
        error("Input key must be of square integer length (omit tokens to be merged)")
    end

    if any([i[1] in square_key for i in replace])
        error("Tokens in the square key cannot be merged to other tokens (replace must involve only omitted tokens)")
    end

    if length(square_indices) != isqrt(length(square_key))
        error("Number of indices squared must match the square size")
    end

    omitted = [i[1] for i in replace]

    S = Substitution([square_key ; omitted])
    invert!(S)

    square = nothing

    for pair in replace
        square = Replace(pair)(square)
    end

    square = S(square)

    return square
end

function Polybius(square_key::Vector{Int}, replace::Pair{Int, Int}; square_indices::Vector{Char} = ['1', '2', '3', '4', '5'])
    if length(square_key) != 25
        error("Input key must be of length 25 (omit tokens to be merged)")
    end

    if replace[1] in square_key
        error("Tokens in the square key cannot be merged to other tokens (replace must involve only omitted tokens)")
    end

    if length(square_indices) != 5
        error("Polybius requires five indices exactly")
    end

    charspace = CharSpace(square_indices) ^ 2

    polybius = Square(square_key, [replace]; square_indices = square_indices)
    polybius = Reassign(Alphabet, charspace)(polybius)

    return polybius
end


function ADFGX(square_key::Vector{Int}, replace::Pair{Int, Int}, columnar_args...; square_indices::Vector{Char} = ['A', 'D', 'F', 'G', 'X'])
    if length(square_key) != 25
        error("Input key must be of length 25 (omit tokens to be merged)")
    end

    if replace[1] in square_key
        error("Tokens in the square key cannot be merged to other tokens (replace must involve only omitted tokens)")
    end

    if length(square_indices) != 5
        error("Polybius requires five indices exactly")
    end

    charspace = CharSpace(square_indices)

    adfgx = Polybius(square_key, replace; square_indices = square_indices)
    adfgx = Retokenise(charspace ^ 2, charspace)(adfgx)
    adfgx = Columnar(columnar_args...)(adfgx)

    return adfgx
end

