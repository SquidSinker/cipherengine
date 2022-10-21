include("charspace.jl")
include("substitution.jl")



function normal_approx_pd(X, N, p)
    mu = N * p
    var = 2 * mu * (1 - p) # 2 carried through to reduce operations

    return exp(- (X + 0.5 - N * p)^2 / var) / sqrt(pi * var)
end

function normalise(a::Vector)
    return a / sum(a)
end





# Limiting function taking (-inf, inf) -> (-p_old, p_new)
function update_delta(delta_fitness, p_old, p_new; rate = 1)
    mu = (p_new + p_old) # division by 2 carried out at the end
    diff = (p_new - p_old) # division by 2 carried out at the end

    C = atanh(diff / mu)

    return ( mu * tanh(delta_fitness * rate - C) + diff ) / 2
end


# Updates relevant PosProbMat entries based on delta_fitness
function update_PosProbMat!(PosProbMat::Matrix, tokenA::Int, tokenB::Int, posA::Int, posB::Int, delta_fitness::Float64; reinforce_rate = 1)
    dA = update_delta(delta_fitness, PosProbMat[tokenA, posA], PosProbMat[tokenA, posB]; reinforce_rate)
    dB = update_delta(delta_fitness, PosProbMat[tokenB, posB], PosProbMat[tokenB, posA]; reinforce_rate)

    PosProbMat[tokenA, posA] -= dA
    PosProbMat[tokenA, posB] += dA

    PosProbMat[tokenB, posB] -= dB
    PosProbMat[tokenB, posA] += dB
end





function new_PosProbMat(vect::Vector{Int}, W::CSpace)
    L = length(vect)
    n = length(W.tokenisation)

    # uniform weighting
    PosProbMat = ones((n, n)) / n

    return PosProbMat
end

function new_PosProbMat(vect::Vector{Int}, W::CSpace, known_freq::Vector)
    L = length(vect)
    n = length(W.tokenisation)

    # init PosProbMat as binomial guesses
    Tallies = [count(x -> isequal(x, i), vect) for i in 1:n]

    PosProbMat = hcat([normalise.(normal_approx_pd.(i, L, known_freq)) for i in Tallies]...)

    return PosProbMat
end







function predict_substitution(PosProbMat::Matrix) # THIS DOES NOT WORK IF Pij maxes on the same j for different i (repeats in Substitution)
    return Substitution( argmax.(eachcol(PosProbMat)) )
end

using StatsBase # for sample()


function linear_reinforcement(vect::Vector{Int}, W::CSpace, generations::Int, ChoiceWeights::Function, fitness::Function; known_freq::Vector = nothing, reinforce_rate = 1)
    P = new_PosProbMat(vect, W, known_freq)

    S = predict_substitution(P)
    prev_fitness = fitness(invert(S)(vect))

    indices = Tuple.(keys(PosProbMat))
    
    for t in 1:generations
        m, n = 0, 0
        while m == n # reroll until a is not in position n (swap is viable)
            (a, n) = sample(indices, Weights(vec( PosProbMat * ChoiceWeights(t, length(W.tokenisation)) )))
            
            m = findfirst(x -> isequal(a), S.mapping)
        end

        b = S.mapping[n]


        switch!(S, m, n)
        new_fitness = fitness(invert(S)(vect))

        dF = new_fitness - old_fitness

        update_PosProbMat!(P, a, b, m, n, dF; reinforce_rate)

        old_fitness = new_fitness
    end

    return P
end






