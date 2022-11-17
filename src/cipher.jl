

abstract type AbstractCipher end

function apply!(C::AbstractCipher, txt::Txt) ::Txt
    if !txt.is_tokenised
        error("Cannot apply cipher to untokenised Txt")
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