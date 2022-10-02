#=

The Substitutionstitution object holds a Vector, where the ith entry is the token that Substitutionstitutes i in the cipher
The only admitted tokens are integers (aka. preprocessed character space)

=#





import Base.length, Base.show, Base.+, Base.-, Base.*, Base.==, Base.getindex, LinearAlgebra.dot

# Substitution FRAMEWORK




mutable struct Substitution
    mapping::Vector{Int}
end

function Substitution(alphabet::String)
    @assert length(unique(alphabet)) == 26
    Substitution([findfirst(x -> isequal(x, i), "ABCDEFGHIJKLMNOPQRSTUVWXYZ") for i in alphabet])
end





length(S::Substitution) = length(S.mapping)



function show(io::IO, S::Substitution)
    println("\n", length(S), "-element Substitution{Char}:")
    print(join(S.mapping, " "))
end



getindex(S::Substitution, i::Int) = S.mapping[i]



==(a::Substitution, b::Substitution) = (a.mapping == b.mapping)



invert(S::Substitution) = Substitution([findfirst(x -> isequal(x, i), S) for i in 1:length(S)])

function invert!(self::Substitution)
    self.mapping = [findfirst(x -> isequal(x, i), S) for i in 1:length(S)]
    self
end



function +(a::Substitution, b::Substitution)
    @assert length(a) == length(b)
    Substitution([b[i] for i in a.mapping])
end

-(a::Substitution, b::Substitution) = a + invert(b)



function (S::Substitution)(vtoken::Vector{Int})
    return [S[token] for token in vtoken]
end



function shift(S::Substitution, c::Int)
    c = mod(c, length(S))
    return Substitution(vcat(S.mapping[c+1:end], S.mapping[1:c]))
end

function shift!(self::Substitution, c::Int)
    c = mod(c, length(self))
    self.mapping = vcat(self.mapping[c+1:end], self.mapping[begin:c])
    self
end



function switch!(self::AbstractVector, posa::Integer, posb::Integer)
    self[posa], self[posb] = self[posb], self[posa]
    self
end



function switch(S::Substitution, posa::Integer, posb::Integer)
    return Substitution(switch!(copy(S.mapping), posa, posb))
end

function switch!(S::Substitution, posa::Integer, posb::Integer)
    S.mapping = switch!(copy(S.mapping), posa, posb)
end



function mutate(S::Substitution, slice::Tuple{Int, Int} = (1, length(S)))
    switch(S, rand(slice[1]:slice[2]), rand(1:length(S)))
end

function mutate!(S::Substitution, slice::Tuple{Int, Int} = (1, length(S)))
    switch!(S, rand(slice[1]:slice[2]), rand(1:length(S)))
end
