import Base.==, Base.length, Base.+, Base.*, Base.^, Base.iterate, Base.getindex, Base.setindex!, Base.show, Base.lastindex, Base.copy


"""
    DLMSpace

A characterspace, encoding substrings `::String` as tokens `::Int`.
`dlm` is the delimiter, separating substrings to be tokenised.

# Fields
- `charmap::Vector{String}` maps tokens to substrings `W.charmap[token]` gives `substring`
- `tokenmap::Dict{String, Int}` maps substrings to assigned tokens `W.tokenmap[substring]` gives `token`
- `dlm` is the delimiting string/character
- `size::Int` is the number of encoded substrings / the number of tokens
- `tokens::Vector{Int}` stores all of the encoding tokens, used for iteration
"""
struct DLMSpace <: AbstractCharSpace
    charmap::Vector{String}
    tokenmap::Dict{String, Int}

    dlm

    size::Int
    tokens::Vector{Int}

    function DLMSpace(substrings::Vector{SubString{String}}, dlm)
        charmap = unique(substrings)
        
        tokenmap = Dict{String, Int}()
        for (i, j) in enumerate(charmap)
            tokenmap[j] = i
        end
        
        size = length(charmap)

        new(charmap, tokenmap, dlm, size, collect(1:size))
    end

end

############################################################################################

function CharSpace(text::String, dlm, case_sensitive = false)
    if case_sensitive
        return DLMSpace(split(text, dlm), dlm)
    else
        return DLMSpace(split(uppercase(text), dlm), dlm)
    end
end

==(W1::DLMSpace, W2::DLMSpace) = (W1.charmap == W2.charmap)

"""
    union(W1, W2) -> DLMSpace

Combines the substrings of `W1` and `W2` to create a new characterspace with the union.
"""
function union(W1::DLMSpace, W2::DLMSpace) ::DLMSpace
    if W1.dlm != W2.dlm
        e = ArgumentError("DLMSpaces have different delimiters")
        throw(e)
    end
    return DLMSpace([W1.charmap ; W2.charmap])
end

+(W1::DLMSpace, W2::DLMSpace) ::DLMSpace = union(W1, W2)

function show(io::IO, W::DLMSpace)
    show(io, W.charmap)
end

function show(io::IO, ::MIME"text/plain", W::DLMSpace)
    println(io, "$(W.size)-element Delimited (\"$(W.dlm)\") CharSpace:")
    show(io, W.charmap)
end



##########################################################################################





function apply_case(cases::BitVector, substr::String) ::String
    return String([case ? uppercase(char) : lowercase(char) for (case, char) in zip(cases, substr)])
end


"""
    tokenise(txt::Txt, W::DLMSpace) -> Vector{Int}, Dict{Int, String}

Returns the token vector of `txt`, where raw substrings have been encoded as tokens (integers),
according to the mapping of the characterspace `W` and returns the `frozen` dictionary, which stores the location of substrings that do not get tokenised
"""
function tokenise(txt::Txt, W::DLMSpace) ::Tuple{Vector{Int}, Dict{Int, String}}

    if !txt.case_sensitive && join(W.charmap) != uppercase(join(W.charmap))
        error("Case-insensitive text cannot be tokenised by a case-sensitive CharSpace")
    end

    tokenised = Vector{Int}()
    text = txt.case_sensitive ? txt.raw : uppercase(txt.raw)
    frozen = Dict{Int, String}()

    for substr in split(text, W.dlm)
        if substr in W.charmap
            push!(tokenised, W.tokenmap[substr])
            frozen[length(tokenised)] = " "
        else
            frozen[length(tokenised)] = substr * " "
        end
    end

    return tokenised, frozen
end


"""
    untokenise(txt::Txt, W::DLMSpace; kwargs) -> String

Returns the concatenation of the substrings for tokens in `txt.tokenised`.

# Keyword Arguments
- `restore_frozen = true` controls whether frozen substrings are reinserted
- `restore_case = true` controls whether the original cases are reapplied
"""
function untokenise(txt::Txt, W::DLMSpace; restore_frozen::Bool = true, restore_case::Bool = true) ::String

    if !txt.is_tokenised
        throw(TokeniseError)
    end

    raw = get(txt.frozen, 0, "")
    n = 0
    i = 1
    for token in txt.tokenised
        if !(1 <= token <= W.size)
            continue
        end

        char = W.charmap[token]
        L = length(char)
        if restore_case && !txt.case_sensitive
            raw *= apply_case(txt.cases[i:i + L - 1], char)
        else
            raw *= char
        end
        raw *= get(txt.frozen, n += 1, "")
        i += L
    end

    return raw
end


"""
    tokenise!(txt::Txt, dlm)

Tokenises `txt` in place, updating the `tokenised`, `frozen`, `is_tokenised`, `charspace` fields.

# Examples
```julia-repl
julia> t = Txt("Mr Wood moment")
14-character Txt:
"Mr Wood moment"

julia> tokenise!(t)
12-token Txt (Delimited Chars):
[1, 2, 3]

julia> t.is_tokenised
true
```
"""
function tokenise!(txt::Txt, dlm) ::Txt
    W = CharSpace(txt.raw, dlm, txt.case_sensitive)
    tokenised, frozen = tokenise(txt, W)
    txt.charspace = W
    txt.frozen = frozen
    txt.is_tokenised = true
    txt.tokenised = tokenised

    return txt
end