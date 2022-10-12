include("charspace.jl")
include("substitution.jl")


function binomial_pd(X, N, p)
    return binomial(N, X) * p^X * (1-p)^(N-X)
end

function normalise(a::Vector)
    return a / sum(a)
end

# Limiting function taking (-inf, inf) -> (-p_old, p_new)
function update_delta(delta_fitness, p_old, p_new; rate = 1)
    mu = (p_new + p_old) / 2
    diff = (p_new - p_old) / 2

    C = atanh(diff / mu)

    return mu * tanh(delta_fitness * rate - C) + diff
end


# Updates relevant PosProbMat entries based on delta_fitness
function update_probs!(PosProbMat::Matrix, tokenA::Int, tokenB::Int, posA::Int, posB::Int, delta_fitness::Float64; reinforce_rate = 1)
    dA = update_delta(delta_fitness, PosProbMat[tokenA, posA], PosProbMat[tokenA, posB]; reinforce_rate)
    dB = update_delta(delta_fitness, PosProbMat[tokenB, posB], PosProbMat[tokenB, posA]; reinforce_rate)

    PosProbMat[tokenA, posA] -= dA
    PosProbMat[tokenA, posB] += dA

    PosProbMat[tokenB, posB] -= dB
    PosProbMat[tokenB, posA] += dB
end


function newPosProbMat(vect::Vector{Int}, W::CSpace; known_freq::Vector = nothing)
    L = length(vect)
    n = length(W.tokenisation)

    if known_freq != nothing # if expected freq given, init PosProbMat as binomial guesses
        Tallies = [count(x -> isequal(x, i), vect) for i in 1:n]

        PosProbMat = hcat([normalise.(binomial_pd.(i, L, known_freq)) for i in Tallies]...)
    else # else do uniform weighting
        PosProbMat = ones((n, n)) / n
    end

    return PosProbMat
end



function predict_Sub(PosProbMat::Matrix) # THIS DOES NOT WORK IF Pij maxes on the same j for different i (repeats in Substitution)
    return Substitution( argmax.(eachcol(PosProbMat)) )
end

using StatsBase # for sample()


function linear_reinforcement(vect::Vector{Int}, W::CSpace, generations::Int, ChoiceWeights::Function, fitness::Function; known_freq::Vector = nothing, reinforce_rate = 1)
    P = newPosProbMat(vect, W; known_freq)

    S = predict_Sub(P)
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

        update_probs!(P, a, b, m, n, dF; reinforce_rate)

        old_fitness = new_fitness
    end

    return P
end






