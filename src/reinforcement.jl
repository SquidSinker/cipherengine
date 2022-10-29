include("substitution.jl")
include("tuco.jl")



function normal_approx_pd(X, N, p) ::Float64
    mu = N * p
    var = 2 * mu * (1 - p) # 2 carried through to reduce operations

    return exp(- (X + 0.5 - N * p)^2 / var) / sqrt(pi * var)
end

function normalise(a::Vector) ::Vector
    return a / sum(a)
end




# Fitness function for PosProbMat, calculates Kullback-Leibler Divergence between PosProbMat and the target (certain) PosProbMat
function PosProbMat_divergence(target::Substitution, PosProbMat::Matrix) ::Float64
    s = 0

    for (i, j) in enumerate(target.mapping)
        s += log10(PosProbMat[i, j])
    end

    return s / length(target)
end








# Limiting function taking (-inf, inf) -> (-p_new, p_old), with update_delta(0) == 0
function update_delta(delta_fitness, p_old, p_new, rate) ::Float64
    if (p_old <= 1e-320) || (p_new <= 1e-320)
        return 0.0
    end

    mu = p_old + p_new # division by 2 carried out at the end
    diff = p_old - p_new # division by 2 carried out at the end

    C = atanh(diff / mu)

    return ( mu * tanh(delta_fitness * rate - C) + diff ) / 2
end


# Updates relevant PosProbMat entries based on delta_fitness, posA and posB are positions of A and B BEFORE SWAPPING
function update_PosProbMat!(PosProbMat::Matrix, tokenA::Int, tokenB::Int, posA::Int, posB::Int, delta_fitness::Float64, reinforce_rate) ::Nothing
    dA = update_delta(delta_fitness, PosProbMat[tokenA, posA], PosProbMat[tokenA, posB], reinforce_rate)
    dB = update_delta(delta_fitness, PosProbMat[tokenB, posB], PosProbMat[tokenB, posA], reinforce_rate)

    PosProbMat[tokenA, posA] -= dA
    PosProbMat[tokenA, posB] += dA

    PosProbMat[tokenB, posB] -= dB
    PosProbMat[tokenB, posA] += dB

    return nothing
end

# restricts ppM values to [0,1]
function tidy_PosProbMat!(PosProbMat::Matrix) ::Nothing
    zeros = PosProbMat .< 0.0
    ones = PosProbMat .> 1.0

    PosProbMat[zeros] .= 0.0
    PosProbMat[ones] .= 1.0
    
    return nothing
end





# initialises PosProbMat guessing the INVERSE substitution
function new_PosProbMat(txt::Txt) ::Matrix
    n = txt.character_space.size

    # uniform weighting, row-summing to 1
    PosProbMat = ones((n, n)) / n

    return PosProbMat
end

# initialises PosProbMat guessing the INVERSE substitution
function new_PosProbMat(txt::Txt, ref_freq::Vector{Float64}) ::Matrix
    L = length(txt)

    # total appearances of each token, stored as Vector
    tallies = appearances.(txt.character_space.tokens, Ref(txt))

    # init PosProbMat with Binomial guesses
    # Compare each known frequency against ALL token frequencies, find p(token_f = known_f)
    # The comparison is done this way round to predict the INVERSE substitution
    # Normalise these rows, so they sum to 1
    PosProbMat = vcat(permutedims.([normalise(normal_approx_pd.(tallies, L, i)) for i in ref_freq])...)

    return PosProbMat
end






####### DEPRECATED
function predict_substitution(PosProbMat::Matrix) # THIS DOES NOT WORK IF Pij maxes on the same j for different i (repeats in Substitution)
    return Substitution( argmax.(eachcol(PosProbMat)) )
end
##################





using StatsBase # for sample()

# Generates a batch of swaps (tokenA, tokenB, posA, posB) representing tokenA goes from posA to posB and vice versa
# takes current substitution (to prevent identity swaps)
function generate_swaps(S::Substitution, PosProbMat::Matrix, ChoiceWeights::Vector, number::Int) ::Vector{Tuple{Int64, Int64, Int64, Int64}}

    out = Vector{Tuple{Int64, Int64, Int64, Int64}}(undef, number)

    Draw_Matrix = PosProbMat .* ChoiceWeights # Broadcast multiply along FIRST (vertical) dimension

    # Stop choices of [token goes to posN] if token already exists in posN
    for i in 1:length(S)
        Draw_Matrix[S[i], i] = 0
    end


    indices = Tuple.(keys(Draw_Matrix)) # THIS IS CALLED EVERY TIME AND IS THE SAME EVERY TIME (static var)

    for i in 1:number
        (a, n) = sample(indices, Weights(vec( Draw_Matrix ))) # (which token to swap, where to move it to)

        b = S[n] # find token in target posN
        m = findfirst(==(a), S.mapping) # find original position of token a

        out[i] = (a, b, m, n)

        # Stop them being chosen again
        Draw_Matrix[a, n] = 0
        Draw_Matrix[b, m] = 0
    end


    return out
end





using Plots

# Substitution solver, where ppM supervises a single substitution lineage
function debug_linear_reinforcement(
    target::Substitution,
    txt::Txt,
    generations::Int,
    spawns::Int,
    choice_weights::Function,
    fitness::Function,
    ref_freq::Union{Vector{Float64}, Nothing} = nothing,
    reinforce_rate::Float64 = 0.5;
    lineage_habit::String = "ascent"
)



    if isnothing(ref_freq) # if not given, start with identity substitution and uniform ppM
        P = new_PosProbMat(W)

        parent_sub = Substitution(W)

    else # if given, use best guesses for ppM and substitution
        P = new_PosProbMat(txt, ref_freq)

        parent_sub = frequency_matched_substitution(txt, ref_freq) # guesses FORWARDS substitution
        invert!(parent_sub)
    end


    F = fitness(apply(parent_sub, txt))
    fitness_log = [F]
    div_log = [PosProbMat_divergence(target, P)]


    anim = @animate for gen in 1:generations
        swaps = generate_swaps(parent_sub, P, choice_weights(gen, F, txt.character_space.size), spawns)
        new_substitutions = [switch(parent_sub, m, n) for (a, b, m, n) in swaps]
        delta_F = fitness.(apply.(new_substitutions, Ref(txt))) .- F
        # generates new swaps from ppM and calculates dF


        for ((a, b, m, n), dF) in zip(swaps, delta_F) # Update P with ALL the data
            update_PosProbMat!(P, a, b, m, n, dF, reinforce_rate)
        end

        tidy_PosProbMat!(P) # corrects floating point error



        # Set new parent and fitness
        if lineage_habit == "ascent"
            parent_sub = new_substitutions[argmax(delta_F)]
            F += maximum(delta_F)

        elseif lineage_habit == "floored ascent"
            if maximum(delta_F) > 0
                parent_sub = new_substitutions[argmax(delta_F)]
                F += maximum(delta_F)
            end

        elseif lineage_habit == "random"
            parent_sub = new_substitutions[1]
            F += delta_F[1]

        elseif lineage_habit == "descent"
            parent_sub = new_substitutions[argmin(delta_F)]
            F += minimum(delta_F)

        else
            error("Invalid lineage habit kwarg")
        end




        push!(fitness_log, F)
        push!(div_log, PosProbMat_divergence(target, P))

        heatmap(P, clims = (0,1), aspect_ratio = :equal)
    end every 10


    
    gif(anim, "anim.gif")

    invert!(parent_sub) # return the "solved" FORWARDS substitution

    return P, parent_sub, fitness_log, div_log
    # Reinforced Matrix // final Substitution in lineage // Vector of fitness values vs generations // Vector of divergence vs gen
end





# Substitution solver, where ppM supervises a single substitution lineage
function linear_reinforcement(
    txt::Txt,
    generations::Int,
    spawns::Int,
    choice_weights::Function,
    fitness::Function,
    ref_freq::Union{Vector{Float64}, Nothing} = nothing,
    reinforce_rate::Float64 = 0.5;
    lineage_habit::String = "ascent"
)


    if isnothing(ref_freq) # if not given, start with identity substitution and uniform ppM
        P = new_PosProbMat(W)

        parent_sub = Substitution(W)

    else # if given, use best guesses for ppM and substitution
        P = new_PosProbMat(txt, ref_freq)

        parent_sub = frequency_matched_substitution(txt, ref_freq) # guesses FORWARDS substitution
        invert!(parent_sub)
    end


    F = fitness(apply(parent_sub, txt))

    for gen in 1:generations
        swaps = generate_swaps(parent_sub, P, choice_weights(gen, F, n), spawns)
        new_substitutions = [switch(parent_sub, m, n) for (a, b, m, n) in swaps]
        delta_F = fitness.(apply.(new_substitutions, Ref(txt))) .- F
        # generates new swaps from ppM and calculates dF


        for ((a, b, m, n), dF) in zip(swaps, delta_F) # Update P with ALL the data
            update_PosProbMat!(P, a, b, m, n, dF, reinforce_rate)
        end

        tidy_PosProbMat!(P) # corrects floating point error



        # Set new parent and fitness
        if lineage_habit == "ascent"
            parent_sub = new_substitutions[argmax(delta_F)]
            F += maximum(delta_F)

        elseif lineage_habit == "floored ascent"
            if maximum(delta_F) > 0
                parent_sub = new_substitutions[argmax(delta_F)]
                F += maximum(delta_F)
            end

        elseif lineage_habit == "random"
            parent_sub = new_substitutions[1]
            F += delta_F[1]

        elseif lineage_habit == "descent"
            parent_sub = new_substitutions[argmin(delta_F)]
            F += minimum(delta_F)

        else
            error("Invalid lineage habit kwarg")
        end

    end



    invert!(parent_sub) # return the "solved" FORWARDS substitution

    return P, parent_sub
    # Reinforced Matrix // final Substitution in lineage
end





