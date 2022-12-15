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
    block_l = length(N.row_perm) ^ 2

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
    sqrtlen = Integer(sqrt(length(plaintext)))
    if !(isinteger(sqrtlen))
        error("input must be square")
    end
    plainmatrix = reshape(plaintext, (sqrtlen, sqrtlen))
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
    sqrtlen = Integer(sqrt(length(ciphertext)))
    if !(isinteger(sqrtlen))
        error("input must be square")
    end
    invpermrow = [findfirst(==(i), permrow) for i in 1:sqrtlen]
    invpermcolumn = [findfirst(==(i), permcolumn) for i in 1:sqrtlen]
    ciphematrix = reshape(ciphertext, (sqrtlen, sqrtlen))
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

include("m10.jl")

using Combinatorics
perms5 = permutations(collect(1:5))

optimise(x -> invert(x)(T), vec([NihilistTransposition(a, b, false) for (a,b) in product(perms5, perms5)]), quadgramlog)