import Base.==, Base.length, Base.+, Base.*, Base.^, Base.iterate, Base.getindex, Base.setindex!

# a case-insensitive text will be converted to uppercase so use uppercase for case-insensitive CSpaces
struct CSpace
    chars::Vector{String}
    n::Int
    size::Int
    tokens::Vector{Int}
    function CSpace(chars::Vector{String})
        uchars = unique(chars)
        ngram_size = length(uchars[1])
        if any(length.(uchars) .!= ngram_size)
            error("Each character in a CSpace must be the same length")
        end
        new(uchars, ngram_size, length(uchars), 1:length(uchars))
    end
end

CSpace(chars::Vector{Char}) = CSpace(string.(chars))
CSpace(chars::String) = CSpace(string.(collect(chars)))
CSpace(W::CSpace) = W

==(W1::CSpace, W2::CSpace) = W1.chars == W2.chars

function union(W1::CSpace, W2::CSpace)
    if W1.n != W2.n 
        error("Cannot combine CSpaces with different character lengths")
    end
    return CSpace(unique(vcat(W1.chars, W2.chars)))
end

function combine(W1::CSpace, W2::CSpace)
    new_chars = Vector{String}()
    for i in W1.chars
        for j in W2.chars
            push!(new_chars, i * j)
        end
    end
    return CSpace(new_chars)
end

ngramify(W::CSpace, n::Int) = n == 1 ? W : combine(W, ngramify(W, n - 1))
digramify(W::CSpace) = ngramify(W, 2)

+(W1::CSpace, W2::CSpace) = union(W1, W2)
*(W1::CSpace, W2::CSpace) = combine(W1, W2)
^(W::CSpace, n::Int) = ngramify(W, n)


mutable struct Txt
    raw::String
    case_sensitive::Bool
    cases::Union{Nothing, Vector{Bool}}
    CSpace::Union{Nothing, CSpace}
    tokenised::Union{Nothing, Vector{Int}}
    frozen::Union{Nothing, Dict{Int, String}}
    is_tokenised::Bool

    Txt(text, case_sensitive = false) = new(text, case_sensitive, isuppercase.(collect(text)), nothing, nothing, nothing, false)
end

length(txt::Txt) = !isnothing(txt.tokenised) ? length(txt.tokenised) : error("Txt has not been tokenised")

function ==(T1::Txt, T2::Union{Txt, Vector{Int}})
    if !T1.is_tokenised
        error("Untokenised Txt objects cannot be compared")
    end

    if T2 isa Vector{Int}
        V2 = T2
    elseif !T2.is_tokenised
        error("Untokenised Txt objects cannot be compared")
    else
        V2 = T2.tokenised
    end

    return T1.tokenised == V2
end

==(T1::Vector{Int}, T2::Txt) = ==(T2, T1)

iterate(txt::Txt) = txt.is_tokenised ? iterate(txt.tokenised) : error("Untokenised Txt objects cannot be iterated")
iterate(txt::Txt, state::Int) = iterate(txt.tokenised, state)
getindex(txt::Txt, i::Int) = txt.is_tokenised ? txt.tokenised[i] : error("Cannot get index of untokenised Txt")
setindex!(txt::Txt, X, i::Int) = txt.is_tokenised ? txt.tokenised[i] = X : error("Cannot set index of untokenised Txt")


function tokenise(txt::Txt, W::CSpace)

    if !txt.case_sensitive && join(W.chars) != uppercase(join(W.chars))
        error("Case-insensitive text cannot be tokenised by a case-sensitive CSpace")
    end

    tokenised = Vector{Int}()
    text = txt.case_sensitive ? txt.raw : uppercase(txt.raw)
    frozen = Dict{Int, String}()

    while length(text) > 0
        char_index = findfirst(startswith.(text, W.chars))
        if isnothing(char_index)
            frozen[length(tokenised)] = get(frozen, length(tokenised), "") * text[1]
            text = text[2:end]
            continue
        end
        push!(tokenised, char_index)
        text = text[W.n+1:end]
    end

    return tokenised, frozen
end


function untokenise(txt::Txt, W::Union{CSpace, Nothing} = nothing; restore_frozen::Bool = true, restore_case::Bool = true)

    if !txt.is_tokenised
        error("Text which hasn't been tokenised can't be untokenised")
    end

    if isnothing(W)
        W = txt.CSpace
    end

    if W.n != txt.CSpace.n
        restore_case = false
    end

    raw = get(txt.frozen, 0, "")
    n = 0
    for token in txt.tokenised
        char = W.chars[token]
        if restore_case && !txt.case_sensitive
            raw *= txt.cases[1 + length(raw)] ? uppercase(char) : lowercase(char)
        else
            raw *= char
        end
        raw *= get(txt.frozen, n += 1, "")
    end

    return raw
end


function tokenise!(txt::Txt, W::CSpace)
    tokenised, frozen = tokenise(txt, W)
    txt.CSpace = W
    txt.frozen = frozen
    txt.is_tokenised = true
    txt.tokenised = tokenised
end

function untokenise!(txt::Txt, W::Union{CSpace, Nothing} = nothing; restore_frozen::Bool = true, restore_case::Bool = true)
    raw = untokenise(txt, W, restore_case = restore_case)
    txt.CSpace = nothing
    txt.tokenised = nothing
    txt.frozen = nothing
    txt.cases = isuppercase.(collect(raw))
    txt.is_tokenised = false
    txt.raw = raw
end


Alphabet_CSpace = CSpace("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
Digits_CSpace = CSpace("1234567890")
Polybius_CSpace = CSpace("12345") ^ 2
ADFGX_CSpace = CSpace("ADFGX") ^ 2
ADFGVX_CSpace = CSpace("ADFGVX") ^ 2
ADFCube_CSpace = CSpace("ADF") ^ 3
Binary5_CSpace = CSpace("01") ^ 5
Ternary3_CSpace = CSpace("012") ^ 3