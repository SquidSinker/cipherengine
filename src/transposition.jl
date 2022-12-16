include("charspace.jl")
include("cipher.jl")
import Base.show
using Combinatorics





# Scytale, Periodic and Columnar
mutable struct ColumnarType <: AbstractCipher
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
    return ColumnarType(n, nothing, true)
end

function Columnar(permutation::Vector{Int})
    return ColumnarType(permutation, true, true)
end
Columnar(n::Int) = Columnar(collect(1:n))
Columnar(colon::Colon, n::Int) = Tuple(permutations(collect(1:n)))

function Permutation(permutation::Vector{Int})
    return ColumnarType(permutation, false, true)
end
Permutation(colon::Colon, n::Int) = Tuple(permutations(collect(1:n)))

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

function reinsert_nulls(vect::Vector{Int}, T::ColumnarType) ::Vector{Int}
    L = length(vect)
    overhang = L % T.n

    if overhang == 0
        return vect
    end

    vector = copy(vect)

    null_ends = T.permutation .> overhang


    if T.transposed
        row_length = ceil(Int, L / T.n)

        for (i,j) in enumerate(null_ends)
            if j
                insert!(vector, i * row_length, NULL_TOKEN)
            end
        end


    else
        num_full_rows = floor(Int, L / T.n)

        for (i,j) in enumerate(null_ends)
            if j
                insert!(vector, num_full_rows * T.n + i, NULL_TOKEN)
            end
        end

    end

    return vector
end



function unshape(vect::Vector{Int}, T::ColumnarType) ::Array{Int}
    new_tokens = reinsert_nulls(vect, T)

    if T.transposed
        new_tokens = reshape(new_tokens, (:, T.n))
        new_tokens = permutedims(new_tokens)
    else
        new_tokens = reshape(new_tokens, (T.n, :))
    end

    return new_tokens
end



function apply(T::ColumnarType, vect::Vector{Int}; safety_checks::Txt) ::Vector{Int}
    if T.inverted # inverse application
        new_tokens = unshape(vect, T)

        inv_permutation = [findfirst(==(i), T.permutation) for i in 1:T.n]

        new_tokens = vec(new_tokens[inv_permutation, :])

        if T.remove_nulls
            return filter!(!=(NULL_TOKEN), new_tokens)
        else
            return new_tokens
        end

    else # regular application
        new_tokens = safe_reshape_2D(vect, T.n, NULL_TOKEN)

        if T.transposed
            new_tokens = permutedims(new_tokens[T.permutation, :])
        else
            new_tokens = new_tokens[T.permutation, :]
        end

        new_tokens = vec(new_tokens)

        if T.remove_nulls
            return deleteat!(new_tokens, findall(==(NULL_TOKEN), new_tokens))
        else
            return new_tokens
        end

    end

end












mutable struct Railfence <: AbstractCipher
    n::Int
    offset::Int

    inverted::Bool

    function Railfence(n::Int, offset::Int = 0, inverted::Bool = false)
        new(n - 1, mod(offset, 2 * n - 2), inverted)
    end

end
Railfence(n::Int, colon::Colon) = Tuple(collect(1:2*(n-1)))

function show(io::IO, T::Railfence)
    if T.inverted
        inverse_text = "Inverse "
    else
        inverse_text = ""
    end

    println(io, "$(T.n + 1)-rail ", inverse_text, "Railfence (offset = $(T.offset))")
end



function unshape(vect::Vector{Int}, T::Railfence) ::Array{Int}
    new_tokens = copy(vect)

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

    return new_tokens
end


function apply(T::Railfence, vect::Vector{Int}; safety_checks::Txt) ::Vector{Int}


    if T.inverted
        new_tokens = unshape(vect, T)
        
        for i in 2:2:lastindex(new_tokens, 2)
            new_tokens[:, i] .= reverse(new_tokens[:, i])
        end

        new_tokens = new_tokens[begin:end-1, :]

        return vec(new_tokens)

    else
        new_tokens = copy(vect)

        for _ in 1:T.offset
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



invert!(T::Union{ColumnarType, Railfence}) = switch_invert_tag!(T)




mutable struct Amsco1 <: AbstractCipher
    blocks::Vector{Int}
    permutation::Vector{Int}
    inverted::Bool
    Amsco1(blocks::Vector{Int}, permutation::Vector{Int}, inverted::Bool = false) = new(blocks, permutation, inverted)
end

invert!(A::Amsco1) = A.inverted = !A.inverted

function (A::Amsco1)(v::Vector{Int}) ::Vector{Int}
    
    block_total = sum(A.blocks)
    period = length(A.permutation)
    rows = ceil(Int, length(v) / block_total * length(A.blocks) / period )
    mat = fill(Vector{Int}(), rows, period)

    u = copy(v)
    r = 1
    c = 0

    if !A.inverted
        while length(u) > 0
            c += 1
            if c > period
                c = 1
                r += 1
            end
            i = A.blocks[((r - 1) * period + c - 1) % length(A.blocks) + 1]
            mat[r, c] = length(u) ≥ i ? u[1:i] : u[1:end]
            u = u[i+1:end]
        end
        
        mat = mat[:, A.permutation]
        return vcat(mat...)
    
    else

        u = copy(v)
        for c in A.permutation
            for r in 1:rows
                i = A.blocks[((r - 1) * period + c - 1) % length(A.blocks) + 1]
                mat[r, c] = length(u) ≥ i ? u[1:i] : u[1:end]
                u = u[i+1:end]
            end
        end
        return vcat(permutedims(mat, (2, 1))...)

    end

end

