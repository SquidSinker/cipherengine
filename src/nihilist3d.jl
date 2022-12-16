include("cipher.jl")


mutable struct Nihilist3D <: AbstractCipher
    row_perm::Vector{Int}
    col_perm::Vector{Int}
    z_perm::Vector{Int}

    inverted::Bool

    function Nihilist3D(row_perm::Vector{Int}, col_perm::Vector{Int}, z_perm::Vector{Int})
        new(row_perm, col_perm, z_perm, false)
    end
end

invert!(N::Nihilist3D) = switch_invert_tag!(N)

function apply(N::Nihilist3D, v::Vector{Int}; safety_checks::Txt)

    vect = copy(v)

    L = length(vect)
    block_l = length(N.row_perm) * length(N.col_perm) * length(N.z_perm)

    if L % block_l != 0
        error("idk just fix")
    end

    blocks = [vect[1 + b - block_l:b] for b in block_l:block_l:lastindex(vect)]

    if N.inverted
        return vcat([nihilist_3D_dec(i, N.row_perm, N.col_perm, N.z_perm) for i in blocks]...)

    else
        return vcat([nihilist_3D_enc(i, N.row_perm, N.col_perm, N.z_perm) for i in blocks]...)

    end

end


function nihilist_3D_enc(plaintext::Vector, permrow, permcolumn, permz)

    len1 = length(permcolumn)
    len2 = length(permrow)
    len3 = length(permz)

    plainmatrix = reshape(plaintext, (len1, len2, len3))

    plainmatrix = plainmatrix[:, permrow, :]
    plainmatrix = plainmatrix[permcolumn, :, :]
    plainmatrix = plainmatrix[:, :, permz]

    return vec(plainmatrix)
end

function nihilist_3D_dec(ciphertext::Vector, permrow, permcolumn, permz)

    len1 = length(permcolumn)
    len2 = length(permrow)
    len3 = length(permz)

    invpermrow = [findfirst(==(i), permrow) for i in 1:len2]
    invpermcolumn = [findfirst(==(i), permcolumn) for i in 1:len1]
    invpermz = [findfirst(==(i), permz) for i in 1:len3]

    ciphematrix = reshape(ciphertext, (len1, len2, len3))

    
    ciphematrix = ciphematrix[:, :, invpermz]
    ciphematrix = ciphematrix[invpermcolumn, :, :]
    ciphematrix = ciphematrix[:, invpermrow, :]

    return vec(ciphematrix)
end