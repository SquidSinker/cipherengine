include("periodic_substitution.jl")
include("genetics.jl")

import IterTools.product

############# ALL on ALPHABETIC CharSpace (to English)

# Returns element of input Vector that maximises x -> fitness(f(x))
function optimise(f::Function, inputs::AbstractVector, fitness::Function)
    scores = [fitness(f(i)) for i in inputs]

    return inputs[argmax(scores)]
end

function optimise!(f::Function, setinput!::Function, obj, inputs::AbstractVector, fitness::Function)
    obj_copy = deepcopy(obj)

    scores = Vector{Float64}(undef, length(inputs))

    for (i, input) in enumerate(inputs)
        setinput!(obj, input)
        scores[i] = fitness(f(obj))
    end

    setinput!(obj_copy, inputs[argmax(scores)])

    return obj_copy
end

function optimise(f::Symbol, inputs::AbstractArray, fitness::Symbol)
    scores = [eval(:(  $fitness($f($i...))  )) for i in inputs]

    return inputs[argmax(scores)]
end



macro bruteforce(func_call::Expr, fitness::Symbol)
    arguments = func_call.args[2:end]
    f = func_call.args[1]

    L = length(arguments)

    isblank = isequal.(arguments, :(:))
    test_sets = Vector(undef, L)
    for arg in 1:L
        if isblank[arg]
            param_extraction_args = deepcopy(arguments)
            param_extraction_args[arg] = Colon()
            try
                test_sets[arg] = eval(:(  $f($param_extraction_args...)  ))
            catch err
                error("This function does not have parameter listing defined for this argument")
            end
        else
            test_sets[arg] = (arguments[arg],)
        end
    end


    return optimise(f, collect(product(test_sets...)), fitness)
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










function crack_Vigenere(txt::Txt; upper_period_lim::Int = 20, critical_sigma::Float64 = 0.15, pass_num::Int = 2, silent::Bool = true) ::PeriodicSubstitution
    period = find_period(txt, upper_period_lim, critical_sigma; silent = silent)

    if isnothing(period)
        error("No period / period could not be found by fw_stdev (if periodicity is certain, try increasing tolerance)")
    end

    vigenere = Vigenere(period, 26) # Blank Vigenere

    for pass in 1:pass_num
        for i in 1:period
            vigenere = optimise!(x -> apply(x::AbstractCipher, txt), (x, y) -> setindex!(x, y, i), vigenere, [Caesar(shift, 26) for shift in 1:26], quadgramlog)
        end
    end

    invert!.(vigenere)
    return vigenere
end



coprimes = collect(1:26)
filter!(x -> gcd(26, x) == 1, coprimes)
function crack_Periodic_Affine(txt::Txt; upper_period_lim::Int = 20, critical_sigma::Float64 = 0.15, pass_num::Int = 2, silent::Bool = true) ::PeriodicSubstitution
    period = find_period(txt, upper_period_lim, critical_sigma; silent = silent)
    
    if isnothing(period)
        error("No period / period could not be found by fw_stdev (if periodicity is certain, try increasing tolerance)")
    end

    p_affine = Periodic_Affine(period, 26)

    for pass in 1:pass_num
        for i in 1:period
            p_affine = optimise!(x -> apply(x::AbstractCipher, txt), (x, y) -> setindex!(x, y, i), p_affine, [Affine(b, a, 26) for a in 1:26 for b in coprimes], quadgramlog)
        end
    end

    invert!.(p_affine)
    return p_affine
end







function crack_Columnar(txt::Txt, n::Int)
    T = reshape(txt.tokenised, (:, n))
    T = permutedims(T)
    
    follow = Matrix{Float64}(undef, n, n)
    for i in 1:n
        for j in 1:n
            follow[i, j] = sum([ bigram_scores[i,j] for (i,j) in zip(T[i, :], T[j, :])])
        end
    end


    permutation = Vector{Int}(undef, n)

    permutation[1] = argmin(vec(maximum(follow; dims = 2))) # finds which column comes last
    follow[permutation[1], :] .= -Inf

    show(follow[:, 1])
    for i in 2:n
        permutation[i] = argmax(vec(follow[:, i-1]))
    end

    reverse!(permutation)
    
    return permutation
end

function crack_Columnar(txt::Txt, upperlim = 20)
    n = divisors(length(txt))

    i = 1
    while n[i] <= upperlim
    end
end