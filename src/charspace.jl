import Base.==, Base.length, Base.+, Base.*, Base.^, Base.iterate, Base.getindex, Base.setindex!, Base.show, Base.lastindex

# a case-insensitive text will be converted to uppercase so use uppercase for case-insensitive CSpaces
struct CSpace
    chars::Vector{String}
    n::Int
    size::Int
    tokens::Vector{Int}

    function CSpace(chars::Vector{String})
        uchars = unique(chars)
        size = length(uchars)

        ngram_size = length(uchars[1]) # get size of first char
        if any(length.(uchars) .!= ngram_size) # check all sizes are the same
            error("Each character in a CSpace must be the same length")
        end

        new(uchars, ngram_size, size, collect(1:size))
    end
end

CSpace(chars::Vector{Char}) = CSpace(string.(chars))
CSpace(chars::String) = CSpace(string.(collect(chars)))
CSpace(W::CSpace) = W

==(W1::CSpace, W2::CSpace) = W1.chars == W2.chars

function union(W1::CSpace, W2::CSpace) ::CSpace
    if W1.n != W2.n 
        error("Cannot combine CSpaces with different character lengths")
    end
    return CSpace(unique(vcat(W1.chars, W2.chars)))
end

function combine(W1::CSpace, W2::CSpace) ::CSpace
    new_chars = Vector{String}(undef, W1.size * W2.size)

    e = 1
    for i in W1.chars
        for j in W2.chars
            new_chars[e] = i * j
            e += 1
        end
    end
    return CSpace(new_chars)
end

ngramify(W::CSpace, n::Int) ::CSpace = n == 1 ? W : combine(W, ngramify(W, n - 1))
digramify(W::CSpace) ::CSpace = ngramify(W, 2)

function tokenise(char::String, W::CSpace) ::Union{Nothing, Int}
    return findfirst(==(char), W.chars)
end

function untokenise(int::Int, W::CSpace) ::String
    return W.chars[int]
end

+(W1::CSpace, W2::CSpace) ::CSpace = union(W1, W2)
*(W1::CSpace, W2::CSpace) ::CSpace = combine(W1, W2)
^(W::CSpace, n::Int) ::CSpace = ngramify(W, n)

function show(io::IO, W::CSpace)
    show(io, W.chars)
end

function show(io::IO, ::MIME"text/plain", W::CSpace)
    println(io, "$(W.size)-element $(W.n)-gram Character Space:")
    show(io, W.chars)
end

mutable struct Txt
    raw::String
    case_sensitive::Bool
    cases::Union{Nothing, Vector{Bool}}
    character_space::Union{Nothing, CSpace}
    tokenised::Union{Nothing, Vector{Int}}
    frozen::Union{Nothing, Dict{Int, String}}
    is_tokenised::Bool

    Txt(text, case_sensitive = false) = new(text, case_sensitive, isuppercase.(collect(text)), nothing, nothing, nothing, false)
end

length(txt::Txt) ::Int = txt.is_tokenised ? length(txt.tokenised) : error("Txt has not been tokenised")

function ==(T1::Txt, T2::Union{Txt, Vector{Int}}) ::Bool
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

==(T1::Vector{Int}, T2::Txt) ::Bool = ==(T2, T1)

iterate(txt::Txt) = txt.is_tokenised ? iterate(txt.tokenised) : error("Untokenised Txt objects cannot be iterated")
iterate(txt::Txt, state::Int) = iterate(txt.tokenised, state)

function getindex(txt::Txt, args) ::Union{Int, Txt}
    if !txt.is_tokenised
        error("Cannot get index of untokenised Txt")
    end

    if args isa Int
        return txt.tokenised[args]
    end 
    
    t = deepcopy(txt)
    t.tokenised = getindex(t.tokenised, args)

    return t
end

setindex!(txt::Txt, X, i::Int) = txt.is_tokenised ? txt.tokenised[i] = X : error("Cannot set index of untokenised Txt")
lastindex(txt::Txt) = lastindex(txt.tokenised)

function show(io::IO, txt::Txt)
    if txt.is_tokenised
        show(io, txt.tokenised)
    else
        show(io, txt.raw)
    end
end

function show(io::IO, ::MIME"text/plain", txt::Txt)
    if txt.is_tokenised
        println(io, "$(length(txt))-token", txt.case_sensitive ? " case-sensitive" : "", " Txt:")
        show(io, txt.tokenised)
    else
        println(io, "$(length(txt.raw))-character", txt.case_sensitive ? " case-sensitive" : "", " Txt:")
        show(io, txt.raw)
    end
end


function tokenise(txt::Txt, W::CSpace = Alphabet_CSpace) ::Tuple{Vector{Int}, Dict{Int, String}}

    if !txt.case_sensitive && join(W.chars) != uppercase(join(W.chars))
        error("Case-insensitive text cannot be tokenised by a case-sensitive CSpace")
    end

    tokenised = Vector{Int}()
    text = txt.case_sensitive ? txt.raw : uppercase(txt.raw)
    frozen = Dict{Int, String}()

    while length(text) > 0
        char_index = findfirst(startswith.(text, W.chars))

        if isnothing(char_index) # if text doesn't start with any of W.chars
            frozen[length(tokenised)] = get(frozen, length(tokenised), "") * text[1]
            i = nextind(text, 1)
            text = text[i:end] # shave text by 1
            continue
        end

        push!(tokenised, char_index) # add token to tokenised
        text = text[W.n+1:end] # shave text by n
    end

    return tokenised, frozen
end


function untokenise(txt::Txt, W::Union{CSpace, Nothing} = nothing; restore_frozen::Bool = true, restore_case::Bool = true) ::String

    if !txt.is_tokenised
        error("Text which hasn't been tokenised can't be untokenised")
    end

    if isnothing(W)
        W = txt.character_space
    end

    if W.n != txt.character_space.n
        restore_case = false
    end

    raw = get(txt.frozen, 0, "")
    n = 0
    for token in txt.tokenised
        if !(token in W.tokens)
            continue
        end
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


function tokenise!(txt::Txt, W::CSpace = Alphabet_CSpace) ::Txt
    tokenised, frozen = tokenise(txt, W)
    txt.character_space = W
    txt.frozen = frozen
    txt.is_tokenised = true
    txt.tokenised = tokenised

    return txt
end

function untokenise!(txt::Txt, W::Union{CSpace, Nothing} = nothing; restore_frozen::Bool = true, restore_case::Bool = true) ::Txt
    raw = untokenise(txt, W, restore_case = restore_case)
    txt.character_space = nothing
    txt.tokenised = nothing
    txt.frozen = nothing
    txt.cases = isuppercase.(collect(raw))
    txt.is_tokenised = false
    txt.raw = raw

    return txt
end


Alphabet_CSpace = CSpace("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
Bigram_CSpace = Alphabet_CSpace ^ 2
Trigram_CSpace = Alphabet_CSpace ^ 3
Quadgram_CSpace = Alphabet_CSpace ^ 4
Decimal_CSpace = CSpace("0123456789")
Hex_CSpace = CSpace("0123456789ABCDEF")
Polybius_CSpace = CSpace("12345") ^ 2
ADFGX_CSpace = CSpace("ADFGX") ^ 2
ADFGVX_CSpace = CSpace("ADFGVX") ^ 2
ADFCube_CSpace = CSpace("ADF") ^ 3
Binary5_CSpace = CSpace("01") ^ 5
Ternary3_CSpace = CSpace("012") ^ 3