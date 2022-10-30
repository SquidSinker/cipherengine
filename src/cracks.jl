include("substitution.jl")
include("tuco.jl")
include("statistics.jl")


# ALL on ALPHABETIC CSPACE (to English)

# Returns elemnt of input Vector that maximises x -> fitness(f(x))
function optimise(f::Function, inputs::AbstractVector, fitness::Function)
    scores = fitness.(f.(inputs))

    return inputs[argmax(scores)]
end



using JLD2
@load "jld2/english_monogram_frequencies.jld2" eng

function crack_Caesar(txt::Txt) ::Substitution
    return invert!(optimise(x -> apply(x, txt), [Caesar(i, 26) for i in 1:26], x -> orthodot(x, eng)))
end

function crack_Affine(txt::Txt) ::Substitution
    coprimes = collect(1:26)
    filter!(x -> gcd(26, x) == 1, coprimes)

    return invert!(optimise(x -> apply(x, txt), [Affine(a, b, 26) for a in coprimes for b in 1:26], x -> orthodot(x, eng)))
end



function crack_Vigenere(txt::Txt, upper_period_lim::Int = 20) ::Vector{Substitution}
    period = find_period(periodic_ioc.(Ref(txt), collect(1:upper_period_lim)), upper_period_lim)

    vigenere = [Substitution(26) for _ in 1:period]

    for i in 1:period
        vigenere = optimise(x -> apply(x, txt), [setindex!(copy(vigenere), Caesar(shift, 26), i) for shift in 1:26], quadgramlog)
    end

    invert!.(vigenere)
    return vigenere
end

function crack_Periodic_Affine(txt::Txt, upper_period_lim::Int = 20) ::Vector{Substitution}
    coprimes = collect(1:26)
    filter!(x -> gcd(26, x) == 1, coprimes) # STATIC VAR

    period = find_period(periodic_ioc.(Ref(txt), collect(1:upper_period_lim)), upper_period_lim)

    p_affine = [Substitution(26) for _ in 1:period]

    for i in 1:period # Quadgramlog is SLOW
        p_affine = optimise(x -> apply(x, txt), [setindex!(copy(p_affine), Affine(a, b, 26), i) for a in coprimes for b in 1:26], quadgramlog)
    end

    invert!.(p_affine)
    return p_affine
end