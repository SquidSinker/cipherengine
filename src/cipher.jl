include("charspace.jl")
import Base.push!, Base.iterate

abstract type AbstractCipher end

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




mutable struct Encryption
    ciphers::Vector{AbstractCipher}

    inverted::Bool

    function Encryption(layers::Vector{AbstractCipher})
        new(layers, false)
    end
end

Encryption(args::AbstractCipher...) = Encryption(args)

function push!(E::Encryption, C::AbstractCipher)
    push!(E.ciphers, C)
    return E
end

iterate(E::Encryption) = iterate(E.ciphers)

(C::AbstractCipher)(D::AbstractCipher) = Encryption([C, D])
(C::AbstractCipher)(E::Encryption) = push!(Encryption, C)

function invert!(E::Encryption)
    invert!.(E.ciphers)
    reverse!(E.ciphers)
    return E
end

function apply!(E::Encryption, txt::Txt) ::Txt
    if !txt.is_tokenised
        error("Cannot apply Encryption to untokenised Txt")
    end

    for layer in E
        txt.tokenised = apply(layer, txt.tokenised; safety_checks = txt)
    end

    return txt
end

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