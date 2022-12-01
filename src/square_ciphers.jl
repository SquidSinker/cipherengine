include("substitution.jl")
include("transposition.jl")

function ReplaceCharAndShiftFunc(i::Int, rep::Pair{Int, Int})
    i = i == rep.first ? rep.second : i
    i = i >= rep.first ? i - 1 : i
    return i
end

ReplaceCharAndShift(rep::Pair{Int, Int}) ::AbstractCipher = Lambda(i::Int -> ReplaceCharAndShiftFunc(i, rep), identity)


function ADFGX(S::Substitution, T::AbstractTransposition, rep::Pair = 10 => 9) ::Encryption
    if S.size != 26
        error("ADFGX ciphertree only applies to Alphabetic text (size of W must be 26)")
    end
    x = ReplaceCharAndShift(rep)
    x = S(x)
    x = Retokenisation(ADFGX_CSpace, Alphabet_CSpace)(x)
    x = T(x)
    return x
end
ADFGX(permutation::Vector{Int}) = ADFGX(Substitution(26), Columnar(permutation))
ADFGX() = ADFGX(Substitution(args_S, 26), Columnar(args_T))


function Polybius(S::Substitution) ::Encryption
    if S.size != 26
        error("ADFGX ciphertree only applies to Alphabetic text (size of W must be 26)")
    end
    return 
end

using JLD2
S = rand_substitution(26)
T = Columnar([5,1,4,3,2], true)
@load "jld2/samples.jld2" orwell
e = ADFGX(S, T)
tokenise!(orwell)
prwell = e(orwell)