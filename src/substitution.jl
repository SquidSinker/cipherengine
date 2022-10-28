import Base.length, Base.show, Base.+, Base.-, Base.==, Base.getindex
include("charspace.jl")

#=

The Substitutionstitution object holds a Vector, where the ith entry is the token that Substitutionstitutes i in the cipher
The only admitted tokens are integers (aka. preprocessed character space)

=#


# S[i] returns j if i -> j
mutable struct Substitution
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



length(S::Substitution) ::Int = S.size

function show(io::IO, S::Substitution)
    show(io, S.mapping)
end

function show(io::IO, ::MIME"text/plain", S::Substitution)
    println(io, "$(S.size)-element Substitution:")
    show(io, S.mapping)
end



getindex(S::Substitution, i::Int) ::Int = getindex(S.mapping, i)


# Checks whether A and B are identical Substitutions
==(a::Substitution, b::Substitution) ::Bool = (a.mapping == b.mapping) && (a.size == b.size)


# if S: i -> j     invert(S): j -> i
invert(S::Substitution) = Substitution([findfirst(==(i), S.mapping) for i in S.tokens], S.size, S.tokens)

function invert!(self::Substitution) ::Substitution
    self.mapping = [findfirst(==(i), self.mapping) for i in self.tokens]
    return self
end


# Compounds two Substitutions to make one new
function +(a::Substitution, b::Substitution) ::Substitution
    if a.size != b.size
        error("Substitutions must have the same length")
    end

    Substitution([b[i] for i in a.mapping], b.character_space)
end

-(a::Substitution, b::Substitution) ::Substitution = a + invert(b)


# Applies Substitution to Integer Vectors
function apply(S::Substitution, vect::Vector{Int}) ::Vector{Int}
    return getindex.(Ref(S), vect)
end

function apply!(S::Substitution, vect::Vector{Int}) ::Vector{Int}
    copyto!(vect, apply(S, vect))
    return vect
end


# Applies Substitution to Txt
function apply!(S::Substitution, txt::Txt) ::Txt
    if !txt.is_tokenised
        error("Cannot apply Substitution to untokenised Txt")
    end

    if txt.character_space.size != S.size
        error("Substitution size must match size of Character Space")
    end

    apply!(S, txt.tokenised)
    return txt
end

apply(S::Substitution, txt::Txt) ::Txt = apply!(S, deepcopy(txt))



(S::Substitution)(txt::Txt) ::Txt = apply(S, txt)



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
function Atbash(args) ::Substitution
    s = Substitution(args)
    reverse!(s.mapping)

    return s
end