include("charspace.jl")


function binomial_pd(X, N, p)
    return binomial(N, X) * p^X * (1-p)^(N-X)
end

function normalise(a::Vector)
    return a / sum(a)
end

# Limiting function taking (-inf, inf) -> (-p_old, p_new)
function update_delta(delta_fitness, p_old, p_new)
    mu = (p_new + p_old) / 2
    diff = (p_new - p_old) / 2

    return diff * tanh(delta_fitness)^2 + mu * tanh(delta_fitness)
end


# Updates relevant matrix entries based on delta_fitness
function update_probs!(matrix::Matrix, tokenA::Int, tokenB::Int, posA::Int, posB::Int, delta_fitness::Float)
    dA = update_delta(delta_fitness, matrix[tokenA, posA], matrix[tokenA, posB])
    dB = update_delta(delta_fitness, matrix[tokenB, posB], matrix[tokenB, posA])

    matrix[tokenA, posA] -= dA
    matrix[tokenA, posB] += dA

    matrix[tokenB, posB] -= dB
    matrix[tokenB, posA] += dB
end





using StatsBase # for sample()

function crack_reinforcement(vect::Vector{Int}, W::CSpace, generations::Int, ChoiceWeights::Function; known_freq::Vector = nothing)
    L = length(vect)

    if known_freq != nothing
        Tallies = [count(x -> isequal(x, i), vect) for i in 1:length(W)]

        PosProbMat = hcat([normalise.(binomial_pd.(i, L, known_freq)) for i in Tallies]...)
    else
        PosProbMat = ones((length(W), length(W))) / length(W)
    end

    indices = Tuple.(keys(PosProbMat))
    
    for t in 1:generations
        (a, n) = sample(indices, Weights(vec( PosProbMat * ChoiceWeights(t) )))

        # FIX PROBLEM OF IT CHOOSING THE ACTIVE SUBSTITUTION POSITIONS




