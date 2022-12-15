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
    return plainmatrix
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
    return transpose(ciphematrix)
end
