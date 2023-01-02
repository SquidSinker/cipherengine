# Switches two entries at posa posb in any Vector
function switch!(self::AbstractVector, posa::Int, posb::Int) ::AbstractVector
    self[posa], self[posb] = self[posb], self[posa]
    return self
end

switch(v::Vector{Int}, posa::Int, posb::Int) ::Vector{Int} = switch!(copy(v), posa, posb)



# Pads vector to reshape cleanly into matrix
function safe_reshape_2D(vector::Vector{T}, dim::Int, null_token::Int) ::Matrix{T} where T
    r = length(vector) % dim
    if r != 0
        vector = copy(vector)
        append!(vector, fill(null_token, dim - r))
    end

    return reshape(vector, (dim, :))
end