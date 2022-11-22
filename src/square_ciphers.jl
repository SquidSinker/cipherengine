include("substitution.jl")
include("transposition.jl")


ReplaceChar(c1, c2) ::Cipher = Lambda(v::Vector{Int} -> replace(v, (c1 => c2)), identity)


function ADFGX(S, T) ::Encryption
    if S.size != 26
        error("ADFGX ciphertree only applies to Alphabetic text (size of W must be 26)")
    end
    x = Retokenisation(ADFGX_CSpace, Alphabet_CSpace)(S)
    x = T(x)

    return x
end
ADFGX(args_T) = ADFGX(Substitution(26), Columnar(args_T))
ADFGX(args_S, args_T) = ADFGX(Substitution(args_S, 26), Columnar(args_T))

function Polybius() ::Encryption