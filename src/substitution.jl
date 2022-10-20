#=

The Substitutionstitution object holds a Vector, where the ith entry is the token that Substitutionstitutes i in the cipher
The only admitted tokens are integers (aka. preprocessed character space)

=#





import Base.length, Base.show, Base.+, Base.-, Base.*, Base.==, Base.getindex, LinearAlgebra.dot

# Substitution FRAMEWORK



# Substitution struct
# S[i] returns j if i -> j
mutable struct Substitution
    mapping::Vector{Int}

    function Substitution(vect::Vector{Int})
        @assert collect(1:length(vect)) == sort(vect) "Substitutions must contain a permutation of integers 1:N"
        new(vect)
    end
end


# Init Substitution from alphabet
function sub_from_alphabet(alphabet::String) ::Substitution
    @assert length(unique(alphabet)) == 26 "Alphabet substitutions must contain all letters of the alphabet once"
    return Substitution([findfirst(==(i), "ABCDEFGHIJKLMNOPQRSTUVWXYZ") for i in alphabet])
end



length(S::Substitution) = length(S.mapping) :: Int



function show(io::IO, S::Substitution)
    println("\n", length(S), "-element Substitution{Char}:")
    print(join(S.mapping, " "))
end



getindex(S::Substitution, i::Int) = S.mapping[i] ::Int


# Checks whether A and B are identical Substitutions
==(a::Substitution, b::Substitution) = (a.mapping == b.mapping)


# if S: i -> j     invert(S): j -> i
invert(S::Substitution) = Substitution([findfirst(x -> isequal(x, i), S) for i in 1:length(S)])

function invert!(self::Substitution)
    self.mapping = [findfirst(x -> isequal(x, i), S) for i in 1:length(S)]
    self
end


# Compounds two Substitutions to make one new
function +(a::Substitution, b::Substitution)
    @assert length(a) == length(b) "Substitutions must have the same length"
    Substitution([b[i] for i in a.mapping])
end

-(a::Substitution, b::Substitution) = a + invert(b)


# Applies Substitution to token vec
function (S::Substitution)(vtoken::Vector{Int}) ::Vector{Int}
    return [S[token] for token in vtoken]
end


# Shifts S mapping by c (mod length(S))
function shift(S::Substitution, c::Int) ::Substitution
    c = mod(c, length(S))
    return Substitution(vcat(S.mapping[c+1:end], S.mapping[1:c]))
end

function shift!(self::Substitution, c::Int)
    c = mod(c, length(self))
    self.mapping = vcat(self.mapping[c+1:end], self.mapping[begin:c])
    self
end


# Switches two entries at posa posb in any Vector
function switch!(self::AbstractVector, posa::Integer, posb::Integer)
    self[posa], self[posb] = self[posb], self[posa]
    self
end



function switch(S::Substitution, posa::Integer, posb::Integer) ::Substitution
    return Substitution(switch!(copy(S.mapping), posa, posb))
end

function switch!(S::Substitution, posa::Integer, posb::Integer)
    S.mapping = switch!(copy(S.mapping), posa, posb)
    S
end


# Switches two random places in a Substitution, within the slice tuple
function mutate(S::Substitution, slice::Tuple{Int, Int} = (1, length(S))) ::Substitution
    switch(S, rand(slice[1]:slice[2]), rand(1:length(S)))
end

function mutate!(S::Substitution, slice::Tuple{Int, Int} = (1, length(S)))
    switch!(S, rand(slice[1]:slice[2]), rand(1:length(S)))
end
