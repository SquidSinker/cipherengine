include("charspace.jl")
import Base.push!, Base.iterate

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
    new_txt = deepcopy(txt)
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

    inverted::Bool

    function Encryption(layers::Vector{AbstractCipher})
        new(layers, false)
    end
end

Encryption(args::AbstractCipher...) = Encryption(collect(args))

function push!(E::Encryption, C::AbstractCipher)
    if E.inverted
        error("Pushing to inverted Encryption not yet implemented")
        return
    end
    push!(E.ciphers, C)
    return E
end

iterate(E::Encryption) = iterate(E.ciphers)
iterate(E::Encryption, state::Int) = iterate(E.ciphers, state)

(C::AbstractCipher)(D::AbstractCipher) = Encryption([D, C])
(C::AbstractCipher)(E::Encryption) = push!(E, C)
(C::AbstractCipher)(n::Nothing) = C
# TODO:
# other way round of line 54
# make combinbing Encryption with Cipher work with inverted Encryptions

function invert!(E::Encryption)
    invert!.(E.ciphers)
    reverse!(E.ciphers)
    E.inverted = !E.inverted
    return E
end
invert(E::Encryption) = invert!(deepcopy(E))

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
    new_txt = deepcopy(txt)
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


mutable struct Retokenise <: AbstractCipher
    OldCSpace::CSpace
    NewCSpace::CSpace
end

function apply!(R::Retokenise, txt::Txt) ::Txt
    if !txt.is_tokenised
        error("Cannot retokenise untokenised Txt")
    end

    untokenise!(txt, R.OldCSpace; restore_case = false, restore_frozen = false)
    tokenise!(txt, R.NewCSpace)

    return txt
end



mutable struct Reassign <: AbstractCipher
    OldCSpace::CSpace
    NewCSpace::CSpace
end

function invert!(R::Union{Reassign, Retokenise})
    R.OldCSpace, R.NewCSpace = R.NewCSpace, R.OldCSpace
    return R
end


function apply!(C::Reassign, txt::Txt) ::Txt
    if !txt.is_tokenised
        error("Cannot apply Cipher to untokenised Txt")
    end

    if txt.character_space != C.OldCSpace
        error("Txt character space does not match Reassign input")
    end

    txt.character_space = C.NewCSpace

    return txt
end