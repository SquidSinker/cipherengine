import Base.length, Base.show, Base.+, Base.-, Base.==, Base.getindex, Base.iterate
import Random.shuffle!
include("charspace.jl")
include("cipher.jl")
include("array functions.jl")
#=

The Substitution object holds a Vector, where the ith entry is the token that Substitutes i in the cipher
DO NOT USE INNER CONSTRUCTOR
=#


# S[i] returns j if i -> j
mutable struct Substitution <: AbstractCipher
    mapping::Vector{Int}
    size::Int
    tokens::Vector{Int}

    # DO NOT USE
    function Substitution(vect::Vector{Int}, size::Int, tokens::Vector{Int}, check_vect::Bool = true) # UNSAFE
        new(checkperm(vect), size, tokens)
    end
    # DO NOT USE


end


# Unsafe outer constructors
unsafe_Substitution(vect::Vector{Int}, size::Int) ::Substitution = Substitution(vect, size, collect(1:size)) # Tokenless UNSAFE
unsafe_Substitution(vect::Vector{Int}, W::CSpace) ::Substitution = Substitution(vect, W.size, W.tokens) # UNSAFE


# Safe outer constructors
Substitution(vect::Vector{Int}) ::Substitution = unsafe_Substitution(vect, length(vect)) # sizeless
function Substitution(size::Int) ::Substitution # Identity
    v = collect(1:size)
    return Substitution(v, size, copy(v), false)
end
function Substitution(chars::Vector{String}, W::CSpace) ::Substitution # Construct Substitution from permutation of chars
    if !issetequal(chars, W.chars)
        error("Substitutions must contain all tokenised characters only once")
    end

    return Substitution([findfirst(==(i), W.chars) for i in chars], W.size, W.tokens, false)
end
Substitution(W::CSpace) ::Substitution = Substitution(W.size)





# Finds forwards substitution matching tokens sorted by frequency
function frequency_matched_Substitution(txt::Txt, ref_frequencies::Vector{Float64} = monogram_freq)
    if length(ref_frequencies) != txt.character_space.size
        error("Reference frequencies must be provided for each token (length equal to CSpace size)")
    end

    f = sortperm(vector_frequencies(txt)) # ranking of empirical frequencies in ascending order

    ref_frequencies = sortperm(ref_frequencies) # ranking of expected frequencies in ascending order

    return Substitution([f[findfirst(==(i), ref_frequencies)] for i in txt.character_space.tokens], txt.character_space.size, txt.character_space.tokens, false) # starts with letters arranged by frequencies against ref_frequencies
end




length(S::Substitution) ::Int = S.size

function show(io::IO, S::Substitution)
    show(io, S.mapping)
end

function show(io::IO, ::MIME"text/plain", S::Substitution)
    println(io, "$(S.size)-element Substitution:")
    show(io, S.mapping)
end



getindex(S::Substitution, i::Int) ::Int = getindex(S.mapping, i)
iterate(S::Substitution) = iterate(S.mapping)
iterate(S::Substitution, i::Integer) = iterate(S.mapping, i)


# Checks whether A and B are identical Substitutions
==(a::Substitution, b::Substitution) ::Bool = (a.mapping == b.mapping)


# if S: i -> j     invert(S): j -> i
function invert!(S::Substitution) ::Substitution
    S.mapping = invperm(S.mapping)
    return S
end


# Compounds two Substitutions to make one new
function +(a::Substitution, b::Substitution) ::Substitution
    if a.size != b.size
        error("Substitutions must have the same length")
    end

    Substitution([b[i] for i in a])
end

-(a::Substitution, b::Substitution) ::Substitution = a + invert(b)


# Applies Substitution to Integer Vectors
function apply(S::Substitution, vect::Vector{Int}; safety_checks::Txt) ::Vector{Int}
    if safety_checks.character_space.size != S.size
        println("WARNING: Substitution size does not match size of Character Space")
    end

    return getindex.(Ref(S), vect)
end





function shift!(self::Substitution, shift::Int) ::Substitution
    self.mapping = circshift(self.mapping, shift)
    return self
end


# Switches two entries in a Substitution
function switch(S::Substitution, posa::Int, posb::Int) ::Substitution # SAFE
    return Substitution(switch(S.mapping, posa, posb), S.size, S.tokens, false)
end

function switch!(S::Substitution, posa::Int, posb::Int) ::Substitution
    switch!(S.mapping ::Vector{Int}, posa, posb)
    return S
end


# Switches a random place in a Substitution, within the slice tuple, with another spot
function mutate(S::Substitution, slice::Tuple{Int, Int} = (1, length(S))) ::Substitution
    switch(S, rand(slice[1]:slice[2]), rand(1:length(S)))
end

function mutate!(S::Substitution, slice::Tuple{Int, Int} = (1, length(S))) ::Substitution
    switch!(S, rand(slice[1]:slice[2]), rand(1:length(S)))
end




# Presets
function Atbash(size::Int) ::Substitution
    s = Substitution(size)
    reverse!(s.mapping)

    return s
end
Atbash(W::CSpace) ::Substitution = Atbash(W.size)

function Caesar(shift::Int, size::Int) ::Substitution
    s = Substitution(size)
    shift!(s, mod(-shift, size))

    return s
end
Caesar(shift::Int, W::CSpace) ::Substitution = Caesar(shift::Int, W.size)
Caesar(colon::Colon, size::Int) ::Tuple = Tuple(1:size)

function Affine(a::Int, b::Int, size::Int) ::Substitution
    if gcd(a, size) != 1
        println("WARNING: Affine parameter $(a)x + $(b) (mod $(size)) is a singular transformation and cannot be inverted")
    end

    s = Substitution(size)
    s.mapping *= a
    s.mapping .+= (b - a) # Shifted to account for one-base indexing, standardising
    s.mapping = mod.(s.mapping, size)
    s.mapping .+= 1

    return s
end
Affine(a::Int, b::Int, W::CSpace) ::Substitution = Affine(a, b, W.size)
Affine(colon::Colon, b::Int, size::Int) ::Tuple = Tuple(filter!(x -> gcd(x, size) == 1, collect(1:size)))
Affine(a::Int, colon::Colon, size::Int) ::Tuple = Tuple(1:size)