include("charspace.jl")
include("substitution.jl")
include("tuco.jl")



function normal_approx_pd(X, N, p)
    mu = N * p
    var = 2 * mu * (1 - p) # 2 carried through to reduce operations

    return exp(- (X + 0.5 - N * p)^2 / var) / sqrt(pi * var)
end

function normalise(a::Vector)
    return a / sum(a)
end





# Limiting function taking (-inf, inf) -> (-p_old, p_new)
function update_delta(delta_fitness, p_old, p_new, rate)
    if (p_old <= 1e-320) || (p_new <= 1e-320)
        return 0.0
    end

    mu = (p_new + p_old) # division by 2 carried out at the end
    diff = (p_new - p_old) # division by 2 carried out at the end

    C = atanh(diff / mu)

    return ( mu * tanh(delta_fitness * rate - C) + diff ) / 2
end


# Updates relevant PosProbMat entries based on delta_fitness, posA and posB are positions of A and B BEFORE SWAPPING
function update_PosProbMat!(PosProbMat::Matrix, tokenA::Int, tokenB::Int, posA::Int, posB::Int, delta_fitness::Float64, reinforce_rate)
    dA = update_delta(delta_fitness, PosProbMat[tokenA, posA], PosProbMat[tokenA, posB], reinforce_rate)
    dB = update_delta(delta_fitness, PosProbMat[tokenB, posB], PosProbMat[tokenB, posA], reinforce_rate)

    PosProbMat[tokenA, posA] += dA
    PosProbMat[tokenA, posB] -= dA

    PosProbMat[tokenB, posB] += dB
    PosProbMat[tokenB, posA] -= dB
end





function new_PosProbMat(W::CSpace)
    n = length(W.tokenised)

    # uniform weighting
    PosProbMat = ones((n, n)) / n

    return PosProbMat
end

function new_PosProbMat(vect::Vector{Int}, W::CSpace, known_freq::Dict)
    L = length(vect)
    n = length(W.tokenised)

    known_freq = [known_freq[i] for i in 1:length(W.tokenised)]

    # init PosProbMat as binomial guesses
    Tallies = [count(==(i), vect) for i in 1:n]

    PosProbMat = hcat([normalise(normal_approx_pd.(i, L, known_freq)) for i in Tallies]...)

    return PosProbMat
end







function predict_substitution(PosProbMat::Matrix) # THIS DOES NOT WORK IF Pij maxes on the same j for different i (repeats in Substitution)
    return Substitution( argmax.(eachcol(PosProbMat)) )
end

using StatsBase # for sample()


function generate_swaps(S::Substitution, PosProbMat::Matrix, ChoiceWeights::Vector, number::Int) ::Vector{Tuple{Int64, Int64, Int64, Int64}}

    out = Vector{Tuple{Int64, Int64, Int64, Int64}}(undef, number)

    Draw_Matrix = PosProbMat .* ChoiceWeights # Broadcast multiply along FIRST (vertical) dimension

    # Stop choices of ('a' goes to n) if S[n] already == 'a'
    for i in 1:length(S)
        Draw_Matrix[S[i], i] = 0
    end


    indices = Tuple.(keys(Draw_Matrix)) # THIS IS CALLES EVERY TIME AND IS THE SAME EVERY TIME (static var)

    for _ in 1:number
        (a, n) = sample(indices, Weights(vec( Draw_Matrix )))

        b = S[n] # 'b' is already at n
        m = findfirst(==(a), S.mapping) # m is original pos of 'a'

        out[_] = (a, b, m, n)

        # Stop them being chosen again
        Draw_Matrix[a, n] = 0
        Draw_Matrix[b, m] = 0
    end


    return out
end





using Plots

function linear_reinforcement(
    vtoken::Vector{Int},
    W::CSpace,
    generations::Int,
    spawns::Int,
    choice_weights::Function,
    fitness::Function;
    known_freq::Dict = nothing,
    reinforce_rate = 0.5
)
    apply_to_text(s) = (s)(vtoken)

    if known_freq !== nothing
        P = new_PosProbMat(vtoken, W, known_freq)

        parent_sub = frequency_matched_substitution(vtoken, W, known_freq)
        invert!(parent_sub)
    else
        P = new_PosProbMat(W)

        parent_sub = Substitution(W)
    end

    F = fitness(apply_to_text(parent_sub))
    fitness_log = [F]

    n = length(W.tokenised)


    anim = @animate for gen in 1:generations
        swaps = generate_swaps(parent_sub, P, choice_weights(gen, F, n), spawns)
        new_substitutions = [switch(parent_sub, m, n) for (a, b, m, n) in swaps]
        delta_F = fitness.(apply_to_text.(new_substitutions)) .- F

        for ((a, b, m, n), dF) in zip(swaps, delta_F) # Update P with the data
            update_PosProbMat!(P, a, b, m, n, dF, reinforce_rate)
        end

        # Set new parent and fitness
        parent_sub = new_substitutions[argmax(delta_F)]
        F += maximum(delta_F)

        push!(fitness_log, F)


        heatmap(P, clims = (0,1))
    end every 10
    
    gif(anim, "anim.gif")

    invert!(parent_sub)

    return P, parent_sub, fitness_log # Reinforced Matrix // final Substitution in lineage // Vector of fitness values vs generations
end






