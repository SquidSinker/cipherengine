#=

The Substitution object holds a Vector, where the ith entry is the token that substitutes i in the cipher
The only admitted tokens are integers (aka. preprocessed character space)

=#





import Base.length, Base.show, Base.+, Base.-, Base.*, Base.==, Base.getindex, LinearAlgebra.dot

# SUB FRAMEWORK

mutable struct Sub
    mapping::Vector{Char}
end





length(S::Sub) = length(S.mapping)



function show(io::IO, S::Sub)
    println("\n", length(S), "-element Substitution{Char}:")
    print(join(S.mapping, " "))
end



getindex(S::Sub, i::Int) = S.mapping[i]



==(a::Sub, b::Sub) = (a.mapping == b.mapping)



invert(S::Sub) = Sub([findfirst(x -> isequal(x, i), S) for i in 1:length(S)])

function invert!(self::Sub)
    self.mapping = [findfirst(x -> isequal(x, i), S) for i in 1:length(S)]
    self
end



function +(a::Sub, b::Sub)
    @assert length(a) == length(b)
    Sub([b[i] for i in a.mapping])
end

-(a::Sub, b::Sub) = a + invert(b)



function (S::Sub)(vtoken::Vector{Int})
    return [S[token] for token in vtoken]
end



function shift(S::Sub, c::Int)
    c = mod(c, length(S))
    return Sub(vcat(S.mapping[c+1:end], S.mapping[1:c]))
end

function shift!(self::Sub, c::Int)
    c = mod(c, length(self))
    self.mapping = vcat(self.mapping[c+1:end], self.mapping[begin:c])
    self
end



function switch!(self::AbstractVector, posa::Integer, posb::Integer)
    self[posa], self[posb] = self[posb], self[posa]
    self
end



function switch(S::Sub, posa::Integer, posb::Integer)
    return Sub(switch!(copy(S.mapping), posa, posb))
end

function switch!(S::Sub, posa::Integer, posb::Integer)
    S.mapping = switch!(copy(S.mapping), posa, posb)
end



function mutate(S::Sub, slice::Tuple{Int, Int} = (1, length(S)))
    switch(S, rand(slice[1]:slice[2]), rand(1:length(S)))
end

function mutate!(S::Sub, slice::Tuple{Int, Int} = (1, length(S)))
    switch!(S, rand(slice[1]:slice[2]), rand(1:length(S)))
end
