import Base.show

mutable struct MatrixTransposition <: AbstractCipher
    n::Int
    remove_nulls::Bool
    inverted::Bool

    function MatrixTransposition(n::Int, remove_nulls::Bool = false)
        new(n, remove_nulls, false)
    end
end

invert!(T::MatrixTransposition) = switch_invert_tag!(T)

function reinsert_nulls(vect::Vector{Int}, T::MatrixTransposition; null_token::Int = 0) ::Vector{Int}
    L = length(vect)
    overhang = L % T.n

    if overhang == 0
        return vect
    end

    null_count = T.n - overhang
    col_length = Int(ceil(L / T.n))

    index = overhang * col_length

    vector = copy(vect)

    for _ in 1:null_count
        index += col_length
        insert!(vector, index, null_token)
    end

    return vector
end

function unshape(vect::Vector{Int}, T::MatrixTransposition) ::Matrix{Int}
    new_tokens = reinsert_nulls(vect, T)
    new_tokens = reshape(new_tokens, (:, T.n))

    return new_tokens
end


function show(io::IO, T::MatrixTransposition)
    println(io, "MatrixTransposition($(T.n))")
end

function show(io::IO, ::MIME"text/plain", T::MatrixTransposition)
    if T.inverted
        inverse_text = " (padding mode inverted)"
    else
        inverse_text = ""
    end

    println(io, "$(T.n)-column Matrix Transposition", inverse_text)
end

function apply(T::MatrixTransposition, vect::Vector{Int}; safety_checks::Txt, null_token::Int = 0) ::Vector{Int}
    if T.inverted # inverse application
        new_tokens = unshape(vect, T)
        new_tokens = vec(permutedims(new_tokens))

        if T.remove_nulls
            return filter!(!=(null_token), new_tokens)
        else
            return new_tokens
        end

    else # regular application
        new_tokens = safe_reshape_2D(vect, T.n, null_token)
        new_tokens = permutedims(new_tokens)

        new_tokens = vec(new_tokens)

        if T.remove_nulls
            return filter!(!=(null_token), new_tokens)
        else
            return new_tokens
        end

    end

end