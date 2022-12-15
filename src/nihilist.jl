include("cipher.jl")


mutable struct NihilistTransposition <: AbstractCipher
    row_perm::Vector{Int}
    col_perm::Vector{Int}

    rows_first::Bool

    inverted::Bool

    function NihilistTransposition(row_perm::Vector{Int}, col_perm::Vector{Int}, rows_first::Bool = true)
        new(row_perm, col_perm, rows_first, false)
    end
end

invert!(N::NihilistTransposition) = switch_invert_tag!(N)

function apply(N::NihilistTransposition, v::Vector{Int}; safety_checks::Txt)
    if N.rows_first
        order = "rows"
    else
        order = "columns"
    end

    vect = copy(v)

    L = length(vect)
    block_l = length(N.row_perm) * length(N.col_perm)

    if L % block_l != 0
        error("idk just fix")
    end

    blocks = [vect[1 + b - block_l:b] for b in block_l:block_l:lastindex(vect)]

    if N.inverted
        return vcat([nihilist_trans_dec(i, N.row_perm, N.col_perm, order) for i in blocks]...)

    else
        return vcat([nihilist_trans_enc(i, N.row_perm, N.col_perm, order) for i in blocks]...)

    end

end


function nihilist_trans_enc(plaintext::Vector, permrow, permcolumn, order="rows")

    len1 = length(permcolumn)
    len2 = length(permrow)

    plainmatrix = reshape(plaintext, (len1, len2))
    if order == "rows"
        plainmatrix = plainmatrix[:, permrow]
        plainmatrix = plainmatrix[permcolumn, :]
    elseif order == "columns"
        plainmatrix = plainmatrix[permcolumn, :]
        plainmatrix = plainmatrix[:, permrow]
    else
        error("argument order must be rows or columns")
    end
    return vec(plainmatrix)
end

function nihilist_trans_dec(ciphertext::Vector, permrow, permcolumn, order="rows")

    len1 = length(permcolumn)
    len2 = length(permrow)

    invpermrow = [findfirst(==(i), permrow) for i in 1:len2]
    invpermcolumn = [findfirst(==(i), permcolumn) for i in 1:len1]
    ciphematrix = reshape(ciphertext, (len1, len2))
    if order == "columns"
        ciphematrix = ciphematrix[:, invpermrow]
        ciphematrix = ciphematrix[invpermcolumn, :]
    elseif order == "rows"
        ciphematrix = ciphematrix[invpermcolumn, :]
        ciphematrix = ciphematrix[:, invpermrow]
    else
        error("argument order must be rows or columns")
    end
    return vec(ciphematrix)
end