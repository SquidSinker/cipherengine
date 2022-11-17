include("charspace.jl")
include("cipher.jl")
import Base.show

NULL = 0



abstract type AbstractTransposition <: AbstractCipher end

function invert!(T::AbstractTransposition)
    T.inverted = !T.inverted
    return T
end






# Scytale, Periodic and Columnar
mutable struct ColumnarType <: AbstractTransposition
    n::Int
    permutation::Vector{Int}
    transposed::Bool

    remove_nulls::Bool

    inverted::Bool

    function ColumnarType(n::Int, permutation::Vector{Int}, transposed::Bool, remove_nulls::Bool = false, inverted::Bool = false)
        if length(permutation) != n
            error("Permutation must be of the same length as the reshape")
        end

        if sort(permutation) != collect(1:n)
            error("Permutation must contain all integers from 1 to n only once")
        end

        new(n, permutation, transposed, remove_nulls, inverted)
    end
end
ColumnarType(n::Int, permutation::Nothing, transposed::Bool, remove_nulls::Bool = false, inverted::Bool = false) = ColumnarType(n, collect(1:n), transposed, remove_nulls, inverted)
ColumnarType(permutation::Vector{Int}, transposed::Bool, remove_nulls::Bool = false, inverted::Bool = false) = ColumnarType(length(permutation), permutation, transposed, remove_nulls, inverted)


function Scytale(n::Int)
    return ColumnarType((n, :), nothing, true)
end

function Columnar(permutation::Vector{Int})
    return ColumnarType(permutation, true)
end

function Permutation(permutation::Vector{Int})
    return ColumnarType(permutation, false)
end


function show(io::IO, T::ColumnarType)
    show(io, T.permutation)
end

function show(io::IO, ::MIME"text/plain", T::ColumnarType)
    if T.inverted
        inverse_text = "Inverse "
    else
        inverse_text = ""
    end

    println(io, "$(T.n)-column ", inverse_text, "ColumnarType Transposition (transpose = $(T.transposed)):")
    show(io, T.permutation)
end


function safe_reshape_2D(vector::Vector{T}, dim, null_token::Int) ::Matrix{T} where T
    r = length(vector) % dim

    if r != 0
        pad_number = dim - length(vector) % dim

        vector = deepcopy(vector)
        for i in 1:pad_number
            push!(vector, null_token)
        end
    end

    return reshape(vector, (dim, :))
end

function reinsert_nulls!(vect::Vector{Int}, T::ColumnarType, null_token::Int) ::Vector{Int}
    L = length(vect)
    overhang = L % T.n

    if overhang == 0
        return vect
    end

    vector = copy(vect)

    null_ends = T.permutation .> overhang


    if T.transposed
        row_length = ceil(Int, L / T.n)

        for (i,j) in enumerate(reverse!(null_ends))
            if j
                insert!(vector, (T.n + 1 - i) * row_length, null_token)
            end
        end


    else
        num_full_columns = L - (overhang)

        for (i,j) in enumerate(null_ends)
            if j
                insert!(vector, num_full_columns * T.n + i, null_token)
            end
        end

    end

    return vector
end

function apply(T::ColumnarType, vect::Vector{Int}; safety_checks::Txt) ::Vector{Int}
    if T.inverted # inverse application
        new_tokens = reinsert_nulls!(vect, T, NULL)
        new_tokens = reshape(new_tokens, (:, T.n))

        if T.transposed
            new_tokens = permutedims(new_tokens)
        end

        inv_permutation = [findfirst(==(i), T.permutation) for i in 1:T.n]

        new_tokens = vec(new_tokens[inv_permutation, :])

        if T.remove_nulls
            return deleteat!(new_tokens, findall(==(NULL), new_tokens))
        else
            return new_tokens
        end

    else # regular application
        new_tokens = safe_reshape_2D(vect, T.n, NULL)

        if T.transposed
            new_tokens = permutedims(new_tokens[T.permutation, :])
        else
            new_tokens = new_tokens[T.permutation, :]
        end

        new_tokens = vec(new_tokens)

        if T.remove_nulls
            return deleteat!(new_tokens, findall(==(NULL), new_tokens))
        else
            return new_tokens
        end

    end

end












mutable struct Railfence <: AbstractTransposition
    n::Int
    offset::Int

    inverted::Bool

    function Railfence(n::Int, offset::Int = 0, inverted::Bool = false)
        new(n - 1, mod(offset, 2 * n - 2), inverted)
    end

end

function show(io::IO, T::Railfence)
    if T.inverted
        inverse_text = "Inverse "
    else
        inverse_text = ""
    end

    println(io, "$(T.n + 1)-rail ", inverse_text, "Railfence (offset = $(T.offset))")
end



function apply(T::Railfence, vect::Vector{Int}; safety_checks::Txt) ::Vector{Int}
    new_tokens = copy(vect)

    if T.inverted
        L = length(vect) + T.offset
        reinsert_pos = Vector{Int}()
        num_rows = ceil(Int, L / T.n)
        matrix_size = (T.n + 1) * num_rows

        num_trailing = T.n - L % T.n + 1

        append!(reinsert_pos, collect(2:2:num_rows), collect(matrix_size-num_rows+1:2:matrix_size)) # alternating zeros
        append!(reinsert_pos, collect( 1 .+ (0:T.offset-1) * num_rows)) # offset zeros
        if 1 & num_rows == 0
            append!(reinsert_pos, collect( (1:num_trailing) * num_rows))
        else
            append!(reinsert_pos, collect( ((T.n+2-num_trailing):T.n+1) * num_rows))
        end
        sort!(reinsert_pos)

        for i in unique(reinsert_pos)
            insert!(new_tokens, i, 0)
        end

        new_tokens = reshape(new_tokens, (num_rows, :))
        new_tokens = permutedims(new_tokens)
        
        for i in 2:2:lastindex(new_tokens, 2)
            new_tokens[:, i] .= reverse(new_tokens[:, i])
        end

        new_tokens = new_tokens[begin:end-1, :]

        return vec(new_tokens)

    else
        for i in 1:T.offset
            insert!(new_tokens, 1, 0)
        end

        new_tokens = safe_reshape_2D(new_tokens, T.n, 0)
        new_tokens = [new_tokens; zeros(Int, 1, size(new_tokens)[2] )]

        for i in 2:2:lastindex(new_tokens, 2)
            new_tokens[:, i] .= reverse(new_tokens[:, i])
        end

        new_tokens = permutedims(new_tokens)

        return vec(new_tokens)
    end

end