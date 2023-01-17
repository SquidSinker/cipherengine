include("tuco.jl")
using Distributions


function p_transposition(txt::Txt, ref_frequencies::Vector{Float64} = monogram_freq) ::Float64
    if length(ref_frequencies) != txt.charspace.size
        error("Reference frequencies must be of the same length as Txt CharSpace")
    end

    L = length(txt)

    token_counts = appearances.(txt.charspace.tokens, Ref(txt))

    distr = Multinomial(L, ref_frequencies)

    return pdf(distr, token_counts)
end
