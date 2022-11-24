import Base.length, Base.show, Base.+, Base.-, Base.==, Base.getindex, Base.iterate
import Random.shuffle!
include("charspace.jl")
include("cipher.jl")

#=

The Substitutionstitution object holds a Vector, where the ith entry is the token that Substitutionstitutes i in the cipher
The only admitted tokens are integers (aka. preprocessed character space)

=#


# S[i] returns j if i -> j
mutable struct Substitution <: AbstractCipher
    mapping::Vector{Int}
    size::Int
    tokens::Vector{Int}

    function Substitution(vect::Vector{Int}, size::Int, tokens::Vector{Int})
        if tokens != sort(vect)
            error("Substitutions must contain a permutation of all tokens")
        end

        new(vect, size, tokens)
    end
end


# Alternate methods
Substitution(vect::Vector{Int}, size::Int) ::Substitution = Substitution(vect, size, collect(1:size)) # Tokenless
function Substitution(size::Int) ::Substitution # Identity
    v = collect(1:size)
    return Substitution(v, size, deepcopy(v))
end


Substitution(vect::Vector{Int}, W::CSpace) ::Substitution = Substitution(vect, W.size, W.tokens)
Substitution(str::String, W::CSpace) ::Substitution = W.n == 1 ? Substitution(string.(collect(str)), W) : error("Substitution from string method requires 1-gram Character Space")
Substitution(W::CSpace) ::Substitution = Substitution(W.size)

# Init Substitution from permutation of chars
function Substitution(chars::Vector{String}, W::CSpace) ::Substitution
    if !issetequal(chars, W.chars)
        error("Substitutions must contain all tokenised characters only once")
    end

    return Substitution([findfirst(==(i), W.chars) for i in chars], W)
end


# Finds forwards substitution matching tokens sorted by frequency
function frequency_matched_substitution(txt::Txt, ref_frequencies::Vector{Float64} = monogram_freq)
    f = sort_by_values(frequencies(txt)) # vector of token indices (Ints) sorted in ascending frequencies

    ref_frequencies = sort_by_values(to_dict(ref_frequencies))

    return Substitution([f[findfirst(==(i), ref_frequencies)] for i in 1:txt.character_space.size], txt.character_space) # starts with letters arranged by frequencies against ref_frequencies
end

function rand_substitution(size::Int) ::Substitution
    s = Substitution(size)
    shuffle!(s.mapping)
    return s
end
rand_substitution(W::CSpace) ::Substitution = rand_substitution(W.size)


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
==(a::Substitution, b::Substitution) ::Bool = (a.mapping == b.mapping) && (a.size == b.size)


# if S: i -> j     invert(S): j -> i
function invert!(self::Substitution) ::Substitution
    self.mapping = [findfirst(==(i), self.mapping) for i in self.tokens]
    return self
end


# Compounds two Substitutions to make one new
function +(a::Substitution, b::Substitution) ::Substitution
    if a.size != b.size
        error("Substitutions must have the same length")
    end

    Substitution([b[i] for i in a], b.character_space)
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


# Switches two entries at posa posb in any Vector
function switch!(self::AbstractVector, posa::Int, posb::Int) ::AbstractVector
    self[posa], self[posb] = self[posb], self[posa]
    return self
end

switch(v::AbstractVector, posa::Int, posb::Int) ::AbstractVector = switch!(deepcopy(v), posa, posb)


# Switches two entries in a Substitution
function switch(S::Substitution, posa::Int, posb::Int) ::Substitution
    return Substitution(switch(S.mapping, posa, posb), S.size, S.tokens)
end

function switch!(S::Substitution, posa::Int, posb::Int) ::Substitution
    switch!(S.mapping ::Vector{Int}, posa, posb)
    return S
end


# Switches two random places in a Substitution, within the slice tuple
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
