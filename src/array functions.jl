# Switches two entries at posa posb in any Vector
function switch!(self::AbstractVector, posa::Int, posb::Int) ::AbstractVector
    self[posa], self[posb] = self[posb], self[posa]
    return self
end

switch(v::Vector{Int}, posa::Int, posb::Int) ::Vector{Int} = switch!(copy(v), posa, posb)



function splice!(self::AbstractVector, ind::Int, start::Int, finish::Int) ::AbstractVector

    if start <= finish
        if start <= ind <= finish
            error("Insertion index must not be within spliced segment")
        end

        if ind < start
            permute!(self, [1:ind - 1 ; start:finish ; ind:start - 1 ; finish + 1:lastindex(self)])
        else
            permute!(self, [1:start - 1 ; finish + 1:ind - 1 ; start:finish ; ind:lastindex(self)])
        end
    else
        if !(finish < ind < start)
            error("Insertion index must not be within spliced segment")
        end

        permute!(self, [finish + 1:ind - 1 ; start:lastindex(self) ; 1:finish; ind:start - 1])
    end

    return self
end

function splice(self::AbstractVector, ind::Int, start::Int, finish::Int) ::AbstractVector

    if start <= finish
        if start <= ind <= finish
            error("Insertion index must not be within spliced segment")
        end

        if ind < start
            return self[[1:ind - 1 ; start:finish ; ind:start - 1 ; finish + 1:lastindex(self)]]
        else
            return self[[1:start - 1 ; finish + 1:ind - 1 ; start:finish ; ind:lastindex(self)]]
        end
    else
        if !(finish < ind < start)
            error("Insertion index must not be within spliced segment")
        end
        
        return self[[finish + 1:ind - 1 ; start:lastindex(self) ; 1:finish; ind:start - 1]]
    end
end


# Pads vector to reshape cleanly into matrix
function safe_reshape_2D(vector::Vector{T}, dim::Int, null_token::Int) ::Matrix{T} where T
    r = length(vector) % dim
    if r != 0
        vector = copy(vector)
        append!(vector, fill(null_token, dim - r))
    end

    return reshape(vector, (dim, :))
end


# checks if vector is permutation and returns vector
function checkperm(vector::Vector{Int}) ::Vector{Int}
    if !isperm(vector)
        e = ArgumentError("not a permutation")
        throw(e)
    end

    return vector
end


# generates affine pattern with coefficoent a and bias b
function affine(a::Int, b::Int, size::Int) ::Vector{Int}
    if gcd(a, size) != 1
        println("WARNING: Affine parameter $(a)x + $(b) (mod $(size)) is a singular transformation and cannot be inverted")
    end

    s = collect(1:size)
    s *= a
    s .+= (b - a) # Shifted to account for one-base indexing, standardising
    s = mod.(s, size)
    s .+= 1

    return s
end


# circularly shifts vector so that item is at the start
function circorigin(a::Vector{T}, item::T) ::Vector{T} where T
    ind = findfirst(==(item), a)
    return circshift(a, 1 - ind)
end



# NORMALISATION ####################################
function normalise!(arr::Array{Float64}; dims::Int) ::Array{Float64}
    arr ./= sum(arr; dims = dims)
    return arr
end
function normalise!(arr::Array{Float64}) ::Array{Float64}
    arr /= sum(arr)
    return arr
end