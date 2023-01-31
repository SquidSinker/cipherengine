include("charspace.jl")
import Base.push!, Base.iterate, Base.insert!, Base.copy, Base.append!, Base.getindex, Base.setindex!, Base.show, Base.length

abstract type AbstractCipher end

# OVERRIDES:
# preferably override apply(cipher, vector; safety_checks)
# if Txt obj necessary, override apply!(cipher, txt)
function apply!(C::AbstractCipher, txt::Txt) ::Txt
    if !txt.is_tokenised
        error("Cannot apply Cipher to untokenised Txt")
    end

    txt.tokenised = apply(C, txt.tokenised; safety_checks = txt)

    return txt
end

function apply(C::AbstractCipher, txt::Txt) ::Txt
    new_txt = copy(txt)
    apply!(C, new_txt)

    return new_txt
end

(C::AbstractCipher)(txt::Txt) = apply(C, txt)

invert(C::AbstractCipher) = invert!(deepcopy(C))

# Type unsafe general inverter "lazy"
function switch_invert_tag!(x)
    x.inverted = !x.inverted
    return x
end



mutable struct Encryption
    ciphers::Vector{AbstractCipher}

    function Encryption(layers::Vector{T}) where T <: AbstractCipher
        new(layers)
    end
end

Encryption(args::AbstractCipher...) = Encryption(collect(args))

function copy(E::Encryption)
    return Encryption(deepcopy(E.ciphers))
end

length(E::Encryption) = length(E.ciphers)
getindex(E::Encryption, inds) = getindex(E.ciphers, inds)
setindex!(E::Encryption, val::AbstractCipher, inds) = setindex!(E.ciphers, val, inds)

function push!(E::Encryption, C::AbstractCipher)
    push!(E.ciphers, C)
    return E
end

function insert!(E::Encryption, index::Int, C::AbstractCipher)
    insert!(E.ciphers, index, C)
    return E
end

function append!(E1::Encryption, E2::Vararg{Encryption, N}) ::Encryption where N
    append!(E1.ciphers, (i.ciphers for i in E2)...)
    return E1
end

iterate(E::Encryption) = iterate(E.ciphers)
iterate(E::Encryption, state::Int) = iterate(E.ciphers, state)

function show(io::IO, E::Encryption)
    show(io, E.ciphers)
end

function show(io::IO, ::MIME"text/plain", E::Encryption)
    println(io, "$(length(E))-element Encryption:")
    show(io, E.ciphers)
end

# TO DO
# cipher tags

(C::AbstractCipher)(D::AbstractCipher) = Encryption([D, C])
(C::AbstractCipher)(E::Encryption) = push!(copy(E), C)
(C::AbstractCipher)(n::Nothing) = C
(E::Encryption)(C::AbstractCipher) = insert!(copy(E), 1, C)
(E1::Encryption)(E2::Encryption) = append!(copy(E2), E1)


function invert!(E::Encryption)
    invert!.(E.ciphers)
    reverse!(E.ciphers)
    return E
end
invert(E::Encryption) = invert!(copy(E))

function apply!(E::Encryption, txt::Txt) ::Txt
    if !txt.is_tokenised
        error("Cannot apply Encryption to untokenised Txt")
    end

    for layer in E
        apply!(layer, txt)
    end

    return txt
end

# It is faster to create one copy and mutate than create copies every time
function apply(E::Encryption, txt::Txt) ::Txt
    new_txt = copy(txt)
    apply!(E, new_txt)

    return new_txt
end

(E::Encryption)(txt::Txt) = apply(E, txt)






mutable struct Lambda <: AbstractCipher
    func::Function
    inv_func::Union{Function, Nothing}

    function Lambda(f::Function, inv_func::Union{Function, Nothing} = nothing)
        new(f, inv_func)
    end
end

function invert!(L::Lambda)
    if isnothing(L.inv_func)
        error("Inverse function not given, cannot invert")
    end

    L.func, L.inv_func = L.inv_func, L.func
    return L
end

apply(L::Lambda, v::Vector{Int}; safety_checks::Txt) = L.func.(v)


# mutable struct Retokenise <: AbstractCipher
#     OldCharSpace::NCharSpace{1}
#     NewCharSpace::NCharSpace{1}
# end

# function apply!(R::Retokenise, txt::Txt) ::Txt
#     if !txt.is_tokenised
#         error("Cannot retokenise untokenised Txt")
#     end

#     untokenise!(txt, R.OldCharSpace; restore_case = false, restore_frozen = false)
#     tokenise!(txt, R.NewCharSpace)

#     return txt
# end



# mutable struct Reassign <: AbstractCipher
#     OldCharSpace::NCharSpace{1}
#     NewCharSpace::NCharSpace{1}
# end

# function invert!(R::Union{Reassign, Retokenise})
#     R.OldCharSpace, R.NewCharSpace = R.NewCharSpace, R.OldCharSpace
#     return R
# end


# function apply!(C::Reassign, txt::Txt) ::Txt
#     if !txt.is_tokenised
#         error("Cannot apply Cipher to untokenised Txt")
#     end

#     if txt.charspace != C.OldCharSpace
#         error("Txt character space does not match Reassign input")
#     end

#     txt.charspace = C.NewCharSpace

#     return txt
# end