import Base.length, Base.show, Base.+, Base.-, Base.==, Base.getindex
include("charspace.jl")

#=

The Substitutionstitution object holds a Vector, where the ith entry is the token that Substitutionstitutes i in the cipher
The only admitted tokens are integers (aka. preprocessed character space)

=#






# Substitution struct with attached CSpace binding
# S[i] returns j if i -> j
mutable struct Substitution
    mapping::Vector{Int}
    character_space::CSpace

    function Substitution(vect::Vector{Int}, W::CSpace)
        @assert collect(1:length(W.tokenised)) == sort(vect) "Substitutions must contain a permutation of all tokens (Integers 1:N)"
        new(vect, W)
    end
end


# Init Substitution from string
function substitution_from_string(string::String, W::CSpace) ::Substitution
    if !W.case_sensitive
        string = lowercase(string)
    end

    @assert issetequal(string, W.tokenised) "String substitutions must contain all tokenised characters only once"
    return Substitution([findfirst(==(i), W.tokenised) for i in string], W)
end



# Identity substitution constructor
function Substitution(W::CSpace)
    return Substitution(collect(1:length(W.tokenised)), W)
end



length(S::Substitution) = length(S.mapping) ::Int



function show(io::IO, S::Substitution)
    println("\n", length(S), "-element Substitution:")
    println(join(collect(1:length(S)), " "))
    println(join(S.mapping, " "))
end



getindex(S::Substitution, i::Int) = S.mapping[i] ::Int


# Checks whether A and B are identical Substitutions
==(a::Substitution, b::Substitution) = (a.mapping == b.mapping) && (a.character_space == b.character_space)


# if S: i -> j     invert(S): j -> i
invert(S::Substitution) = Substitution([findfirst(==(i), S.mapping) for i in 1:length(S)], S.character_space)

function invert!(self::Substitution)
    self.mapping = [findfirst(==(i), self.mapping) for i in 1:length(self)]
    self
end


# Compounds two Substitutions to make one new
function +(a::Substitution, b::Substitution)
    @assert length(a) == length(b) "Substitutions must have the same length"
    @assert a.character_space == b.character_space "Character spaces must be the same"
    Substitution([b[i] for i in a.mapping], b.character_space)
end

-(a::Substitution, b::Substitution) = a + invert(b)


# Applies Substitution to token vec
function (S::Substitution)(vtoken::Vector{Int}) ::Vector{Int}
    return [S[token] for token in vtoken]
end



function shift!(self::Substitution, shift::Int)
    self.mapping = circshift(self.mapping, shift)
    return self
end


# Switches two entries at posa posb in any Vector
function switch!(self::AbstractVector, posa::Integer, posb::Integer)
    self[posa], self[posb] = self[posb], self[posa]
    return self
end



function switch(S::Substitution, posa::Integer, posb::Integer) ::Substitution
    return Substitution(switch!(copy(S.mapping), posa, posb), S.character_space)
end

function switch!(S::Substitution, posa::Integer, posb::Integer)
    S.mapping = switch!(copy(S.mapping), posa, posb)
    return S
end


# Switches two random places in a Substitution, within the slice tuple
function mutate(S::Substitution, slice::Tuple{Int, Int} = (1, length(S))) ::Substitution
    switch(S, rand(slice[1]:slice[2]), rand(1:length(S)))
end

function mutate!(S::Substitution, slice::Tuple{Int, Int} = (1, length(S)))
    switch!(S, rand(slice[1]:slice[2]), rand(1:length(S)))
end
