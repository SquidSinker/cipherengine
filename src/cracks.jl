include("substitution.jl")
include("tuco.jl")
include("statistics.jl")
include("genetics.jl")


############# ALL on ALPHABETIC CSPACE (to English)

# Returns element of input Vector that maximises x -> fitness(f(x))
function optimise(f::Function, inputs::AbstractVector, fitness::Function)
    scores = [fitness(f(i)) for i in inputs]

    return inputs[argmax(scores)]
end






function crack_Caesar(txt::Txt) ::Substitution
    return invert!(optimise(x -> apply(x, txt), [Caesar(i, 26) for i in 1:26], x -> orthodot(x)))
end

function crack_Affine(txt::Txt) ::Substitution
    coprimes = collect(1:26)
    filter!(x -> gcd(26, x) == 1, coprimes)

    return invert!(optimise(x -> apply(x, txt), [Affine(a, b, 26) for a in coprimes for b in 1:26], x -> orthodot(x)))
end








function crack_Substitution_genetic(txt::Txt, spawns::Int = 10, gen::Int = 350) # token vector // number of mutatated subs spawned each generation // no of generations
    start = frequency_matched_substitution(txt, monogram_freq)
    invert!(start)

    return evolve_silent(x -> apply(x, txt), mutate, start, spawns, gen, quadgramlog)
end










function crack_Vigenere(txt::Txt, upper_period_lim::Int = 20, period_tolerance::Float64 = 0.15) ::Vector{Substitution}
    period = find_period(txt, upper_period_lim, period_tolerance)

    if isnothing(period)
        error("No period / period could not be found by fw_stdev (if periodicity is certain, try increasing tolerance)")
    end

    vigenere = [Substitution(26) for _ in 1:period]

    for i in 1:period
        vigenere = optimise(x -> apply(x, txt), [setindex!(copy(vigenere), Caesar(shift, 26), i) for shift in 1:26], quadgramlog)
    end

    invert!.(vigenere)
    return vigenere
end

function crack_Periodic_Affine(txt::Txt, upper_period_lim::Int = 20, period_tolerance::Float64 = 0.15) ::Vector{Substitution}
    coprimes = collect(1:26)
    filter!(x -> gcd(26, x) == 1, coprimes) # STATIC VAR

    period = find_period(txt, upper_period_lim, period_tolerance)
    
    if isnothing(period)
        error("No period / period could not be found by fw_stdev (if periodicity is certain, try increasing tolerance)")
    end

    p_affine = [Substitution(26) for _ in 1:period]

    for i in 1:period # Quadgramlog is SLOW
        p_affine = optimise(x -> apply(x, txt), [setindex!(copy(p_affine), Affine(a, b, 26), i) for a in coprimes for b in 1:26], quadgramlog)
    end

    invert!.(p_affine)
    return p_affine
end