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


# Updates relevant PosProbMat entries based on delta_fitness, posA and posB are positions of A and B BEFORE SWAPPING
function update_PosProbMat!(PosProbMat::Matrix, tokenA::Int, tokenB::Int, posA::Int, posB::Int, delta_fitness::Float64; reinforce_rate = 1)
    dA = update_delta(delta_fitness, PosProbMat[tokenA, posA], PosProbMat[tokenA, posB]; reinforce_rate)
    dB = update_delta(delta_fitness, PosProbMat[tokenB, posB], PosProbMat[tokenB, posA]; reinforce_rate)

    PosProbMat[tokenA, posA] -= dA
    PosProbMat[tokenA, posB] += dA

    PosProbMat[tokenB, posB] -= dB
    PosProbMat[tokenB, posA] += dB
end





function new_PosProbMat(vect::Vector{Int}, W::CSpace)
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


function generate_swaps(S::Substitution, PosProbMat::Matrix, ChoiceWeights::Vector, number::Int)

    out = Vector{Tuple{Int}}()

    Draw_Matrix = PosProbMat .* ChoiceWeights # Broadcast multiply along FIRST (vertical) dimension

    # Stop choices of ('a' goes to n) if S[n] already == 'a'
    for i in 1:length(S)
        Draw_Matrix[S[i], i] = 0
    end


    indices = Tuple.(keys(Draw_Matrix))

    for _ in 1:number
        (a, n) = sample(indices, Weights(vec( Draw_Matrix )))

        b = S[n] # 'b' is already at n
        m = findfirst(==(a), S.mapping) # m is original pos of 'a'

        push!(out, (a, b, m, n))

        # Stop them being chosen again
        Draw_Matrix[a, n] = 0
        Draw_Matrix[b, m] = 0
    end


    return out
end











function linear_reinforcement(
    vect::Vector{Int},
    W::CSpace,
    generations::Int,
    ChoiceWeights::Function,
    fitness::Function;
    known_freq::Vector = nothing,
    reinforce_rate = 1
)
    P = new_PosProbMat(vect, W, known_freq)

    apply_to_text(s) = invert(s)(vect)

    parent_sub = predict_substitution(P)
    F = fitness(apply_to_text(parent_sub))


    for gen in 1:generations
        swaps = generate_swaps(parent_sub, P, ChoiceWeights(gen, F), spawns)
        new_substitutions = [switch(parent_sub, m, n) for (a, b, m, n) in swaps]
        delta_F = [fitness(apply_to_text.(new_substitutions))] - F

        for ((a, b, m, n), dF) in zip(swaps, delta_F) # Update P with the data
            update_PosProbMat!(P, a, b, m, n, dF; reinforce_rate = reinforce_rate)
        end

        # Set new parent and fitness
        parent_sub = new_substitutions[argmax(delta_F)]
        F += maximum(delta_F)
    end
    

    return P, parent_sub # Reinforced Matrix // final Substitution in lineage
end






