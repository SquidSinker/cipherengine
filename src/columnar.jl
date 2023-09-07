import Base.show
using Combinatorics


mutable struct Columnar <: AbstractCipher
    n::Int
    permutation::Vector{Int}

    remove_nulls::Bool

    inverted::Bool

    function Columnar(n::Int, permutation::Vector{Int}, remove_nulls::Bool, inverted::Bool)
        if length(checkperm(permutation)) != n
            error("Permutation must be of the same length as the reshape")
        end

        new(n, permutation, remove_nulls, inverted)
    end
end
Columnar(n::Int, remove_nulls::Bool = false) = Columnar(n, collect(1:n), remove_nulls, false)
Columnar(permutation::Vector{Int}, remove_nulls::Bool = false) = Columnar(length(permutation), permutation, remove_nulls, false)

Columnar(colon::Colon, n::Int) = Tuple(permutations(collect(1:n)))




function switch(S::Columnar, posa::Int, posb::Int) ::Columnar
    return Columnar(S.n, switch(S.permutation, posa, posb), S.remove_nulls, S.inverted)
end

function switch!(S::Columnar, posa::Int, posb::Int) ::Columnar
    switch!(S.permutation ::Vector{Int}, posa, posb)
    return S
end

function shift!(self::Columnar, shift::Int) ::Columnar
    self.permutation = circshift(self.permutation, shift)
    return self
end

function shift(self::Columnar, shift::Int)
    shift!(deepcopy(self), shift)
end




function show(io::IO, T::Columnar)
    show(io, T.permutation)
end

function show(io::IO, ::MIME"text/plain", T::Columnar)
    if T.inverted
        inverse_text = "Inverse "
    else
        inverse_text = ""
    end

    println(io, "$(T.n)-column ", inverse_text, "Columnar Transposition:")
    show(io, T.permutation)
end

function reinsert_nulls(vect::Vector{Int}, T::Columnar; null_token::Int) ::Vector{Int}
    L = length(vect)
    overhang = L % T.n

    if overhang == 0
        return vect
    end

    vector = copy(vect)

    null_ends = T.permutation .> overhang

    row_length = ceil(Int, L / T.n)

    for (i,j) in enumerate(null_ends)
        if j
            insert!(vector, i * row_length, null_token)
        end
    end

    return vector
end



function unshape(vect::Vector{Int}, T::Columnar; null_token::Int) ::Array{Int}
    new_tokens = reinsert_nulls(vect, T; null_token = null_token)

    new_tokens = reshape(new_tokens, (:, T.n))
    new_tokens = permutedims(new_tokens)

    return new_tokens
end



function apply(T::Columnar, vect::Vector{Int}; safety_checks::Txt, null_token::Int = 0) ::Vector{Int}
    if T.inverted # inverse application
        new_tokens = unshape(vect, T; null_token = null_token)

        inv_permutation = [findfirst(==(i), T.permutation) for i in 1:T.n]

        new_tokens = vec(new_tokens[inv_permutation, :])

        if T.remove_nulls
            return filter!(!=(null_token), new_tokens)
        else
            return new_tokens
        end

    else # regular application
        new_tokens = safe_reshape_2D(vect, T.n, null_token)

        new_tokens = permutedims(new_tokens[T.permutation, :])

        new_tokens = vec(new_tokens)

        if T.remove_nulls
            return filter!(!=(null_token), new_tokens)
        else
            return new_tokens
        end

    end

end


invert!(T::Columnar) = switch_invert_tag!(T)









# mutable struct Railfence <: AbstractCipher
#     n::Int
#     offset::Int

#     inverted::Bool

#     function Railfence(n::Int, offset::Int = 0, inverted::Bool = false)
#         new(n - 1, mod(offset, 2 * n - 2), inverted)
#     end

# end
# Railfence(n::Int, colon::Colon) = Tuple(collect(1:2*(n-1)))

# function show(io::IO, T::Railfence)
#     if T.inverted
#         inverse_text = "Inverse "
#     else
#         inverse_text = ""
#     end

#     println(io, "$(T.n + 1)-rail ", inverse_text, "Railfence (offset = $(T.offset))")
# end



# function unshape(vect::Vector{Int}, T::Railfence) ::Array{Int}
#     new_tokens = copy(vect)

#     L = length(vect) + T.offset
#     reinsert_pos = Vector{Int}()
#     num_rows = ceil(Int, L / T.n)
#     matrix_size = (T.n + 1) * num_rows

#     num_trailing = T.n - L % T.n + 1

#     append!(reinsert_pos, collect(2:2:num_rows), collect(matrix_size-num_rows+1:2:matrix_size)) # alternating zeros
#     append!(reinsert_pos, collect( 1 .+ (0:T.offset-1) * num_rows)) # offset zeros
#     if 1 & num_rows == 0
#         append!(reinsert_pos, collect( (1:num_trailing) * num_rows))
#     else
#         append!(reinsert_pos, collect( ((T.n+2-num_trailing):T.n+1) * num_rows))
#     end
#     sort!(reinsert_pos)

#     for i in unique(reinsert_pos)
#         insert!(new_tokens, i, 0)
#     end

#     new_tokens = reshape(new_tokens, (num_rows, :))
#     new_tokens = permutedims(new_tokens)

#     return new_tokens
# end


# function apply(T::Railfence, vect::Vector{Int}; safety_checks::Txt) ::Vector{Int}


#     if T.inverted
#         new_tokens = unshape(vect, T)
        
#         for i in 2:2:lastindex(new_tokens, 2)
#             new_tokens[:, i] .= reverse(new_tokens[:, i])
#         end

#         new_tokens = new_tokens[begin:end-1, :]

#         return vec(new_tokens)

#     else
#         new_tokens = copy(vect)

#         for _ in 1:T.offset
#             insert!(new_tokens, 1, 0)
#         end

#         new_tokens = safe_reshape_2D(new_tokens, T.n, 0)
#         new_tokens = [new_tokens; zeros(Int, 1, size(new_tokens)[2] )]

#         for i in 2:2:lastindex(new_tokens, 2)
#             new_tokens[:, i] .= reverse(new_tokens[:, i])
#         end

#         new_tokens = permutedims(new_tokens)

#         return vec(new_tokens)
#     end

# end



# invert!(T::Union{Columnar, Railfence}) = switch_invert_tag!(T)




# mutable struct Amsco1 <: AbstractCipher
#     blocks::Vector{Int}
#     permutation::Vector{Int}
#     inverted::Bool
#     Amsco1(blocks::Vector{Int}, permutation::Vector{Int}, inverted::Bool = false) = new(blocks, permutation, inverted)
# end

# mutable struct Amsco2 <: AbstractCipher
#     blocks::Vector{Int}
#     permutation::Vector{Int}
#     shift::Int
#     inverted::Bool
#     function Amsco2(blocks::Vector{Int}, permutation::Vector{Int}, shift::Int = 1, inverted::Bool = false)
#         if length(permutation) != length(blocks)
#             error("Amsco2 requires a permutation with the same period as the number of block lengths")
#         end
#         new(blocks, permutation, shift, inverted)
#     end
# end

# invert!(A::Union{Amsco1, Amsco2}) = switch_invert_tag!(A)

# function apply(A::Union{Amsco1, Amsco2}, v::Vector{Int}; safety_checks::Txt) ::Vector{Int}
    
#     block_total = sum(A.blocks)
#     period = length(A.permutation)
#     rows = ceil(Int, length(v) / block_total * length(A.blocks) / period )
#     mat = fill(Vector{Int}(), rows, period)

#     u = copy(v)
#     r = 1
#     c = 0

#     if !A.inverted
#         while length(u) > 0
#             c += 1
#             if c > period
#                 c = 1
#                 r += 1
#             end
#             if A isa Amsco1
#                 i = A.blocks[((r - 1) * period + c - 1) % length(A.blocks) + 1]
#             else
#                 i = A.blocks[(c - 1 + A.shift*(r-1)) % period + 1]
#             end
#             mat[r, c] = length(u) ≥ i ? u[1:i] : u[1:end]
#             u = u[i+1:end]
#         end
        
#         mat = mat[:, A.permutation]
#         return vcat(mat...)
    
#     else

#         u = copy(v)
#         for c in A.permutation
#             for r in 1:rows
#                 if A isa Amsco1
#                     i = A.blocks[((r - 1) * period + c - 1) % length(A.blocks) + 1]
#                 else
#                     i = A.blocks[(c - 1 + A.shift*(r-1)) % period + 1]
#                 end
#                 mat[r, c] = length(u) ≥ i ? u[1:i] : u[1:end]
#                 u = u[i+1:end]
#             end
#         end
#         return vcat(permutedims(mat, (2, 1))...)

#     end

# end