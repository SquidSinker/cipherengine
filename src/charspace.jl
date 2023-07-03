import Base.==, Base.length, Base.+, Base.*, Base.^, Base.iterate, Base.getindex, Base.setindex!, Base.show, Base.lastindex, Base.copy

const NULL_TOKEN = 0


"""
    NCharSpace{N}

A characterspace, encoding substrings `::String` as tokens `::Int`.
`N` is an integer parameter: the length of encoded substrings in characters.

# Fields
- `charmap::Vector{String}` maps tokens to substrings `W.charmap[token]` gives `substring`
- `tokenmap::Dict{String, Int}` maps substrings to assigned tokens `W.tokenmap[substring]` gives `token`
- `units::Vector{String}` stores the most reduced version of encoded substrings
- `unit_length::Int` stores the length of an individual unit
- `linear::LinearIndices` maps a composite n-token to n unit tokens
- `cartesian::CartesianIndices` maps n unit tokens to a single composite n-token
- `size::Int` is the number of encoded substrings / the number of tokens
- `tokens::Vector{Int}` stores all of the encoding tokens, used for iteration
"""
struct NCharSpace{N}
    charmap::Vector{String}
    tokenmap::Dict{String, Int}

    units::Vector{String}
    unit_length::Int

    linear::LinearIndices{N, NTuple{N, Base.OneTo{Int64}}}
    cartesian::CartesianIndices{N, NTuple{N, Base.OneTo{Int64}}}

    size::Int
    tokens::Vector{Int}

    # DO NOT USE UNSAFE
    function NCharSpace{N}(charmap::Vector{String}, tokenmap::Dict{String, Int}, units::Vector{String}, unit_length::Int, size::Int, tokens::Vector{Int}) where N
        if !((N isa Int) && (N > 0))
            e = DomainError("Parameter must be an Natural number")
            throw(e)
        end

        shape = Tuple(length(units) for _ in 1:N)
        linear = LinearIndices(shape)
        cartesian = CartesianIndices(shape)

        new{N}(charmap, tokenmap, units, unit_length, linear, cartesian, size, tokens)
    end
    # DO NOT USE UNSAFE

end

findparam(W::NCharSpace{N}) where N = N

"""
Creates an `NCharSpace{1}` (the most reduced version) from the arguments
"""
function CharSpace(chars::Vector{String}) ::NCharSpace{1}
    uchars = unique(chars)
    size = length(uchars)

    first_size = length(uchars[1])
    if !all(x -> length(x) == first_size, uchars) # check all sizes are the same
        e = ArgumentError("Characters have different lengths")
        throw(e)
    end

    tokenmap = Dict{String, Int}()
    for (i, j) in enumerate(uchars)
        tokenmap[j] = i
    end

    units = copy(uchars)

    NCharSpace{1}(uchars, tokenmap, units, first_size, size, collect(1:size))
end

"""
    ^(W::NCharSpace{1}, n::Int) -> NCharSpace{n}

Returns a composite version of `W`, encoding substrings made of `n` unit substrings to single tokens.

# Examples
```julia-repl
julia> Decimal
10-element CharSpace:
["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]

julia> W = Decimal^2
100-element 2-char CharSpace:
["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]

julia> tokenise.(["1", "2"], Ref(Decimal))
2-element Vector{Int64}:
 2
 3

julia> W.linear[2,3]
22

julia> W.charmap[22]
"12"
```
"""
function ^(W::NCharSpace{1}, n::Int) ::NCharSpace{n}
    size = W.size ^ n

    charmap = Vector{String}(undef, size)
    tokenmap = Dict{String, Int}()
    for (i, c) in enumerate(Iterators.product(ntuple(i -> W.charmap, n)...))
        string = join(c)

        charmap[i] = string
        tokenmap[string] = i
    end

    return NCharSpace{n}(charmap, tokenmap, W.units, W.unit_length, size, collect(1:size))
end

function charspacereduce(W::NCharSpace{N}) ::NCharSpace{1} where N
    if N == 1
        return W
    else
        return CharSpace(W.units)
    end
end

"""
    nchar(W::NCharSpace{N}, n::Int) -> NCharSpace{n}

Produces the order `n` `NCharSpace` from `W.units`
"""
function nchar(W::NCharSpace{N}, n::Int) where N
    if n == 1
        return charspacereduce(W)
    elseif N == 1
        return W ^ N
    else
        return charspacereduce(W) ^ n
    end
end

############################################################################################

CharSpace(chars::Vector{Char}) = CharSpace(string.(chars))
CharSpace(chars::String) = CharSpace(string.(collect(chars)))
CharSpace(W::NCharSpace{N}) where N = charspacereduce(W)

==(W1::NCharSpace{A}, W2::NCharSpace{B}) where {A, B} = (A == B) && (W1.charmap == W2.charmap) && (W1.units == W2.units)

"""
    union(W1, W2) -> NCharSpace{1}

Combines the unit substrings of `W1` and `W2` (must be in reduced form) to create a new characterspace with the union.
"""
function union(W1::NCharSpace{1}, W2::NCharSpace{1}) ::NCharSpace{1}
    if W1.unit_length != W2.unit_length
        e = ArgumentError("CharSpaces have different substring lengths")
        throw(e)
    end
    return CharSpace([W1.charmap ; W2.charmap])
end

"""
    tokenise(s::String, W::NCharSpace{N}) -> Int, Nothing

Returns the token assigned to `s`

Returns `nothing` if `s` is not in `W`

# Examples
```julia-repl
julia> tokenise("C", Alphabet)
3

julia> tokenise("1", Alphabet)

julia> tokenise("01", Decimal^2)
11

```
"""
function tokenise(char::String, W::NCharSpace) ::Union{Nothing, Int}
    try return W.tokenmap[char]
    catch err
        if err isa KeyError
            return nothing
        else
            throw(err)
        end
    end
end

"""
    untokenise(token::Int, W::NCharSpace) -> String

Returns the substring that is assigned `token` in `W`

# Examples
```julia-repl
julia> untokenise(3, Alphabet)
"C"

julia> untokenise(15, Decimal^2)
"41"
```
"""
function untokenise(int::Int, W::NCharSpace) ::String
    return W.charmap[int]
end


+(W1::NCharSpace{1}, W2::NCharSpace{1}) ::NCharSpace{1} = union(W1, W2)

function show(io::IO, W::NCharSpace{N}) where N
    show(io, W.charmap)
end

function show(io::IO, ::MIME"text/plain", W::NCharSpace{N}) where N
    if N == 1
        insert = ""
    else
        insert =  " $(N)-char"
    end

    println(io, "$(W.size)-element", insert, " CharSpace:")
    show(io, W.units)
end



"""
    checktoken(token::Int, W::NCharSpace)

Throws `ArgumentError` if the token does not exist in `W`, otherwise returns `token`
"""
function checktoken(token::Int, W::NCharSpace)
    b = 0 <= token <= W.size
    if b
        return token
    else
        e = ArgumentError("Token does not exist in character space")
        throw(e)
    end
end




##########################################################################################
"""
    Txt

A wrapper for strings that handles tokenisation

# Fields
- `raw` stores the latest string version of the text, is updated on construction and `untokenise`
- `cases` is a `BitVector` containing the case of each corresponding `Char` in the `raw`, initialised only on construction
- `charspace` stores the `NCharSpace{N}` of the text
- `tokenised` stores the token values, is updated under most cipher calls
- `frozen` stores a `Dict` of `index => string` for substrings that are not tokenised, so they may be reinserted
"""
mutable struct Txt
    raw::String
    case_sensitive::Bool
    cases::Union{Nothing, BitVector}
    charspace::Union{Nothing, NCharSpace{N}} where N
    tokenised::Union{Nothing, Vector{Int}}
    frozen::Union{Nothing, Dict{Int, String}}
    is_tokenised::Bool
    
end

"""
    Txt(text::String, case_sensitive::Bool = false)

Constructs Txt wrapper for `text` in the untokenised state

# Examples
```julia-repl
julia> Txt("A bright sunny day.")
19-character Txt:
"A bright sunny day."
```
"""
Txt(text, case_sensitive = false) = Txt(text, case_sensitive, isuppercase.(collect(text)), nothing, nothing, nothing, false)

const TokeniseError = ErrorException("Txt is not tokenised")
"""
    checktokenised(txt::Txt) -> Vector{Int}

If `txt` is not tokenised (`txt.is_tokenised == false`), throws a `TokeniseError`.
Otherwise, it returns the token vector `txt.tokenised`.
"""
function checktokenised(txt::Txt) ::Vector{Int}
    if txt.is_tokenised
        return txt.tokenised
    end

    throw(TokeniseError)
end

length(txt::Txt) ::Int = length(checktokenised(txt))

function ==(T1::Txt, T2::Union{Txt, Vector{Int}}) ::Bool
    if !T1.is_tokenised
        throw(TokeniseError)
    end

    if T2 isa Vector{Int}
        V2 = T2
    elseif !T2.is_tokenised
        throw(TokeniseError)
    else
        V2 = T2.tokenised
    end

    return T1.tokenised == V2
end

==(T1::Vector{Int}, T2::Txt) ::Bool = ==(T2, T1)

iterate(txt::Txt) = iterate(checktokenised(txt))
iterate(txt::Txt, state::Int) = iterate(txt.tokenised, state)

function getindex(txt::Txt, args) ::Union{Int, Txt}
    if !txt.is_tokenised
        throw(TokeniseError)
    end

    if args isa Int
        return txt.tokenised[args]
    end 
    
    t = copy(txt)
    t.tokenised = getindex(t.tokenised, args)

    return t
end

setindex!(txt::Txt, X, i::Int) = setindex!(checktokenised(txt), X, i)
lastindex(txt::Txt) = lastindex(checktokenised(txt))

function copy(txt::Txt) ::Txt
    if txt.is_tokenised
        return Txt(txt.raw, txt.case_sensitive, txt.cases, txt.charspace, copy(txt.tokenised), txt.frozen, txt.is_tokenised)
    else
        return Txt(txt.raw, txt.case_sensitive, txt.cases, txt.charspace, txt.tokenised, txt.frozen, txt.is_tokenised)
    end
end

function show(io::IO, txt::Txt)
    if txt.is_tokenised
        show(io, txt.tokenised)
    else
        show(io, txt.raw)
    end
end

function show(io::IO, ::MIME"text/plain", txt::Txt)
    if txt.is_tokenised
        N = findparam(txt.charspace)
        if N == 1
            insert = ""
        else
            insert = " ($(N)-gram tokens)"
        end

        println(io, "$(length(txt))-token", txt.case_sensitive ? " case-sensitive" : "", " Txt", insert, ":")
        show(io, txt.tokenised)
    else
        println(io, "$(length(txt.raw))-character", txt.case_sensitive ? " case-sensitive" : "", " Txt:")
        show(io, txt.raw)
    end
end


function txtnchar!(txt::Txt, n::Int) ::Txt
    if !txt.is_tokenised
        throw(TokeniseError)
    end

    if length(txt.tokenised) % n != 0
        e = ArgumentError("Txt length is not divisible by $n")
        throw(e)
    end

    W = txt.charspace ^ n
    txt.tokenised = [W.linear[ txt.tokenised[i - n + 1:i]... ] for i in n:n:lastindex(txt.tokenised)]
    txt.charspace = W
    return txt
end

function txtnchar(txt::Txt, n::Int) ::Txt
    if !txt.is_tokenised
        throw(TokeniseError)
    end

    if length(txt.tokenised) % n != 0
        e = ArgumentError("Txt length is not divisible by $n")
        throw(e)
    end

    W = txt.charspace ^ n
    new_tokenised = [W.linear[ txt.tokenised[i - n + 1:i]... ][1] for i in n:n:lastindex(txt.tokenised)]
    return Txt(txt.raw, txt.case_sensitive, txt.cases, W, new_tokenised, txt.frozen, txt.is_tokenised)
end

function txtreduce!(txt::Txt) ::Txt
    if !txt.is_tokenised
        throw(TokeniseError)
    end

    W = nchar(txt.charspace, 1)
    new_tokenised = Vector{Int}()
    for i in txt.tokenised
        append!(new_tokenised, Tuple(txt.charspace.cartesian[i]))
    end
    txt.tokenised = new_tokenised
    txt.charspace = W
    return txt
end

function txtreduce(txt::Txt) ::Txt
    if !txt.is_tokenised
        throw(TokeniseError)
    end
    
    W = nchar(txt.charspace, 1)
    new_tokenised = Vector{Int}()
    for i in txt.tokenised
        append!(new_tokenised, Tuple(txt.charspace.cartesian[i]))
    end
    return Txt(txt.raw, txt.case_sensitive, txt.cases, W, new_tokenised, txt.frozen, txt.is_tokenised)
end

"""
    nchar(txt::Txt, n::Int) -> Txt

Retokenises `txt` with `n` character substrings, assigning a `NCharSpace{N}` of order `N = n`.
If `txt.charspace` has order greater than 1, first the text is reduced (`reduce(txt)`).

# Examples
```julia-repl
julia> example
24-character Txt:
"Literally George Orwell."

julia> tokenise!(example)
21-token Txt:
[12, 9, 20, 5, 18, 1, 12, 12, 25, 7  …  15, 18, 7, 5, 15, 18, 23, 5, 12, 12]

julia> nexample = nchar(example, 3)
7-token Txt (3-gram tokens):
[13064, 447, 16522, 9575, 2878, 15329, 7727]

julia> untokenise(nexample[1], nexample.charspace)
"LIT"
```
"""
function nchar(txt::Txt, n::Int) ::Txt
    N = findparam(txt.charspace)

    if n == 1
        return txtreduce(txt)
    elseif N == 1
        return txtnchar(txt, n)
    else
        return txtnchar(txtreduce(txt), n)
    end
end

function nchar!(txt::Txt, n::Int)
    N = findparam(txt.charspace)

    if n == 1
        return txtreduce!(txt)
    elseif N == 1
        return txtnchar!(txt, n)
    else
        return txtnchar!(txtreduce!(txt), n)
    end
end

"""
    tokenise(txt::Txt, W::NCharSpace{1} = Alphabet) -> Vector{Int}, Dict{Int, String}

Returns the token vector of `txt`, where raw substrings have been encoded as tokens (integers),
according to the mapping of the characterspace `W` and returns the `frozen` dictionary, which stores the location of substrings that do not get tokenised
"""
function tokenise(txt::Txt, W::NCharSpace{1} = Alphabet) ::Tuple{Vector{Int}, Dict{Int, String}}

    if !txt.case_sensitive && join(W.charmap) != uppercase(join(W.charmap))
        error("Case-insensitive text cannot be tokenised by a case-sensitive CharSpace")
    end

    tokenised = Vector{Int}()
    text = txt.case_sensitive ? txt.raw : uppercase(txt.raw)
    frozen = Dict{Int, String}()

    while length(text) > 0
        char_index = findfirst(startswith.(text, W.charmap))

        if isnothing(char_index) # if text doesn't start with any of W.chars
            frozen[length(tokenised)] = get(frozen, length(tokenised), "") * text[1]
            i = nextind(text, 1)
            text = text[i:end] # shave text by 1
            continue
        end

        push!(tokenised, char_index) # add token to tokenised
        text = text[W.unit_length + 1:end] # shave text by 1 unit
    end

    return tokenised, frozen
end

# function jagged_tokenise(txt::Txt, W::CharSpace, blocks::Vector{Int}, null::Union{Char, String, Vector{Char}} = "X") ::Tuple{Vector{Int}, Dict{Int, String}}

#     txt = deepcopy(txt)
#     tokenise!(txt)
#     untokenise!(txt; restore_frozen = false, restore_case = false)
    
#     if maximum(blocks) < W.n
#         error("Maximum block size cannot be greater than CharSpace character length")
#     end

#     tokenised = Vector{Int}()
#     text = txt.case_sensitive ? txt.raw : uppercase(txt.raw)
#     frozen = Dict{Int, String}()

#     while length(text) > 0
#         char_index = findfirst(startswith.(text, W.chars))

#         if isnothing(char_index) # if text doesn't start with any of W.chars
#             frozen[length(tokenised)] = get(frozen, length(tokenised), "") * text[1]
#             i = nextind(text, 1)
#             text = text[i:end] # shave text by 1
#             continue
#         end

#         push!(tokenised, char_index) # add token to tokenised
#         text = text[W.n+1:end] # shave text by n
#     end

#     return tokenised, frozen
# end


"""
    untokenise(txt::Txt, W::NCharSpace; kwargs) -> String

Returns the concatenation of the substrings for tokens in `txt.tokenised`.

# Keyword Arguments
- `restore_frozen = true` controls whether frozen substrings are reinserted
- `restore_case = true` controls whether the original cases are reapplied
"""
function untokenise(txt::Txt, W::NCharSpace{1}; restore_frozen::Bool = true, restore_case::Bool = true) ::String

    if !txt.is_tokenised
        throw(TokeniseError)
    end

    if isnothing(W)
        W = txt.charspace
    end

    raw = get(txt.frozen, 0, "")
    n = 0
    for token in txt.tokenised
        if !(1 <= token <= W.size)
            continue
        end
        char = W.charmap[token]
        if restore_case && !txt.case_sensitive
            raw *= txt.cases[1 + length(raw)] ? uppercase(char) : lowercase(char)
        else
            raw *= char
        end
        raw *= get(txt.frozen, n += 1, "")
    end

    return raw
end
untokenise(txt::Txt; restore_frozen::Bool = true, restore_case::Bool = true) ::String = untokenise(txt, txt.charspace; restore_frozen = restore_frozen, restore_case = restore_case)
untokenise(txt::Txt, nothing::Nothing; restore_frozen::Bool = true, restore_case::Bool = true) ::String = untokenise(txt, txt.charspace; restore_frozen = restore_frozen, restore_case = restore_case)
untokenise(txt::Txt, W::NCharSpace{N} where N; restore_frozen::Bool = true, restore_case::Bool = true) ::String = untokenise(nchar(txt, 1))

"""
    tokenise!(txt::Txt, W::NCharSpace{1} = Alphabet)

Tokenises `txt` in place, updating the `tokenised`, `frozen`, `is_tokenised`, `charspace` fields.

# Examples
```julia-repl
julia> t = Txt("Mr Wood moment")
14-character Txt:
"Mr Wood moment"

julia> tokenise!(t)
12-token Txt:
[13, 18, 23, 15, 15, 4, 13, 15, 13, 5, 14, 20]

julia> t.is_tokenised
true
```
"""
function tokenise!(txt::Txt, W::NCharSpace{1} = Alphabet) ::Txt
    tokenised, frozen = tokenise(txt, W)
    txt.charspace = W
    txt.frozen = frozen
    txt.is_tokenised = true
    txt.tokenised = tokenised

    return txt
end

"""
    untokenise!(txt::Txt, W::Union{NCharSpace{1}, Nothing} = nothing; kwargs)

Unokenises `txt` in place, updating the `raw::String` field and `is_tokenised` and clearing `tokenised`

# Examples
```julia-repl
julia> t
12-token Txt:
[13, 18, 23, 15, 15, 4, 13, 15, 13, 5, 14, 20]

julia> untokenise!(t)
14-character Txt:
"Mr Wood moment"
```
"""
function untokenise!(txt::Txt, W::Union{NCharSpace, Nothing} = nothing; restore_frozen::Bool = true, restore_case::Bool = true) ::Txt
    raw = untokenise(txt, W, restore_case = restore_case)
    txt.charspace = nothing
    txt.tokenised = nothing
    txt.frozen = nothing
    txt.cases = isuppercase.(collect(raw))
    txt.is_tokenised = false
    txt.raw = raw

    return txt
end


Alphabet = CharSpace("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
# Bigram_CharSpace = Alphabet ^ 2
# Trigram_CharSpace = Alphabet ^ 3
# Quadgram_CharSpace = Alphabet ^ 4
Decimal = CharSpace("0123456789")
Hexadecimal = CharSpace("0123456789ABCDEF")
# Polybius_CharSpace = CharSpace("12345") ^ 2
# ADFGX_CharSpace = CharSpace("ADFGX") ^ 2
# ADFGVX_CharSpace = CharSpace("ADFGVX") ^ 2
# ADFCube_CharSpace = CharSpace("ADF") ^ 3
# Binary5_CharSpace = CharSpace("01") ^ 5
# Ternary3_CharSpace = CharSpace("012") ^ 3