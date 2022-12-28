include("substitution.jl")
include("tuco.jl")



function normal_approx_pd(X::Int, N::Int, p::Float64) ::Float64
    mu = N * p
    var = 2 * mu * (1 - p) # 2 carried through to reduce operations

    P = exp(- (X + 0.5 - N * p)^2 / var) / sqrt(pi * var)
    if P == 0.0
        return 1e-200
    end

    return P
end

function batch_binomial_pd(X::Vector{Int}, N::Int, p::Float64) ::Vector{Float64}
    mu = N * p
    var = 2 * mu * (1 - p) # 2 carried through to reduce operations

    M = 7e2 - (maximum(X) - mu)^2 / var

    PX = [exp( M - (x - mu)^2 / var ) for x in X]

    PX = normalise(PX)
    
    PX[PX .== 0] .= 1e-300

    return PX
end



function normalise(a::Vector) ::Vector
    s = sum(a)
    if s == 0 | isnan(s)
        a = ones(length(a))
        return a / length(a)
    end
    return a / s
end




# Fitness function for PosProbMat, calculates Kullback-Leibler Divergence between PosProbMat and the target (certain) PosProbMat
# target is the FORWARDS substitution
function PosProbMat_divergence(target::Substitution, PosProbMat::Matrix) ::Float64
    s = 0

    for (i, j) in enumerate(target.mapping)
        s += log2(PosProbMat[i, j])
    end

    return - s / length(target)
end





function uniform_choice_weights(gen, fitness, n) ::Vector{Float64}
    return ones(n) / n
end


















# Limiting function taking (-inf, inf) -> (-p_new, p_old), with update_delta(0) == 0
function update_delta(delta_fitness::Float64, p_old::Float64, p_new::Float64, rate::Float64) ::Float64

    if (p_old <= 1e-320) || (p_new <= 1e-320)
        return 0.0
    end


    if rate == Inf # maximum learn rate
        if delta_fitness == 0
            return 0.0
        elseif delta_fitness > 0
            return p_old
        else
            return - p_new
        end
    end


    mu = p_old + p_new # division by 2 carried out at the end
    diff = p_old - p_new # division by 2 carried out at the end

    C = atanh(diff / mu)

    return ( mu * tanh(delta_fitness * rate - C) + diff ) / 2
end


# Updates relevant PosProbMat entries based on delta_fitness, posA and posB are positions of A and B BEFORE SWAPPING
function update_PosProbMat!(PosProbMat::Matrix, tokenA::Int, tokenB::Int, posA::Int, posB::Int, delta_fitness::Float64, reinforce_rate) ::Matrix
    dA = update_delta(delta_fitness, PosProbMat[tokenA, posA], PosProbMat[tokenA, posB], reinforce_rate)
    dB = update_delta(delta_fitness, PosProbMat[tokenB, posB], PosProbMat[tokenB, posA], reinforce_rate)

    PosProbMat[tokenA, posA] -= dA
    PosProbMat[tokenA, posB] += dA

    PosProbMat[tokenB, posB] -= dB
    PosProbMat[tokenB, posA] += dB

    return PosProbMat
end



# restricts ppM values to [0,1]
function tidy_PosProbMat!(PosProbMat::Matrix{Float64}) ::Matrix{Float64}
    zeros = PosProbMat .< 0.0
    ones = PosProbMat .> 1.0

    PosProbMat[zeros] .= 0.0
    PosProbMat[ones] .= 1.0
    
    return PosProbMat
end





# initialises PosProbMat guessing the INVERSE substitution
function new_PosProbMat(n::Int) ::Matrix

    # uniform weighting, row-summing to 1
    PosProbMat = ones((n, n)) / n

    return PosProbMat
end
new_PosProbMat(txt::Txt) ::Matrix = new_PosProbMat(txt.character_space.size)
new_PosProbMat(S::Substitution) ::Matrix = new_PosProbMat(S.size)


# initialises PosProbMat guessing the INVERSE substitution
function new_PosProbMat(txt::Txt, ref_freq::Vector{Float64}) ::Matrix
    L = length(txt)

    # total appearances of each token, stored as Vector
    tallies = appearances.(txt.character_space.tokens, Ref(txt))

    # init PosProbMat with Binomial guesses
    # Compare each known frequency against ALL token frequencies, find p(token_f = known_f)
    # The comparison is done this way round to predict the INVERSE substitution
    # Normalise these rows, so they sum to 1
    PosProbMat = vcat(permutedims.([batch_binomial_pd(tallies, L, i) for i in ref_freq])...)

    return PosProbMat
end






####### DEPRECATED
# function predict_substitution(PosProbMat::Matrix) # THIS DOES NOT WORK IF Pij maxes on the same j for different i (repeats in Substitution)
#     return Substitution( argmax.(eachcol(PosProbMat)) )
# end
##################





import StatsBase.sample, StatsBase.pweights # for sample()

# Generates a batch of swaps (tokenA, tokenB, posA, posB) representing tokenA goes from posA to posB and vice versa
# takes current substitution (to prevent identity swaps)
function generate_swaps(indices::CartesianIndices{2, Tuple{Base.OneTo{Int64}, Base.OneTo{Int64}}}, S::Substitution, PosProbMat::Matrix, ChoiceWeights::Vector, number::Int) ::Vector{Tuple{Int64, Int64, Int64, Int64}}

    out = Vector{Tuple{Int64, Int64, Int64, Int64}}(undef, number)

    Draw_Matrix = PosProbMat .* ChoiceWeights # Broadcast multiply along FIRST (vertical) dimension

    # Stop choices of [token goes to posN] if token already exists in posN
    for i in 1:length(S)
        Draw_Matrix[S[i], i] = 0
    end


    samples = sample(indices, pweights( Draw_Matrix ), number, replace = false) # Tuple(which token to swap, where to move it to)
    a = [i[1] for i in samples]
    n = [i[2] for i in samples]

    b = [S[i] for i in n] # find token in target posN
    m = [findfirst(==(i), S.mapping) for i in a] # find original position of token a


    return collect(zip(a,b,m,n))
end


# Work out next parent in lineage, based on lineag_habit type
function next_in_lineage(parent::T, children::Vector{T}, parent_fitness::Float64, child_delta_fitness::Vector{Float64}; lineage_habit::String) ::Tuple{T, Float64} where {T}
    if length(children) != length(child_delta_fitness)
        error("Each child must have an associated delta fitness")
    end


    # Set new parent and fitness
    if lineage_habit == "ascent"
        parent = children[argmax(child_delta_fitness)]
        parent_fitness += maximum(child_delta_fitness)

    elseif lineage_habit == "floored ascent"
        if maximum(child_delta_fitness) > 0
            parent = children[argmax(child_delta_fitness)]
            parent_fitness += maximum(child_delta_fitness)
        end

    elseif lineage_habit == "random"
        parent = children[1]
        parent_fitness += child_delta_fitness[1]

    elseif lineage_habit == "descent"
        parent = children[argmin(child_delta_fitness)]
        parent_fitness += minimum(child_delta_fitness)

    elseif lineage_habit == "stationary"
    else
        error("Invalid lineage habit kwarg")
    end

    return parent, parent_fitness
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
        P = new_PosProbMat(txt)

        parent_sub = Substitution(txt.character_space)

    else # if given, use best guesses for ppM and substitution
        P = new_PosProbMat(txt, ref_freq)

        parent_sub = frequency_matched_Substitution(txt, ref_freq) # guesses FORWARDS substitution
        invert!(parent_sub)
    end

    indices = keys(P)

    parent_fitness = fitness(apply(parent_sub, txt))
    fitness_log = [parent_fitness]
    div_log = [PosProbMat_divergence(target, P)]


    anim = @animate for gen in 1:generations
        println(gen)
        swaps = generate_swaps(indices, parent_sub, P, choice_weights(gen, parent_fitness, txt.character_space.size), spawns)
        new_substitutions = [switch(parent_sub, m, n) for (a, b, m, n) in swaps]
        delta_F = fitness.(apply.(new_substitutions, Ref(txt))) .- parent_fitness
        # generates new swaps from ppM and calculates dF


        for ((a, b, m, n), dF) in zip(swaps, delta_F) # Update P with ALL the data
            update_PosProbMat!(P, a, b, m, n, dF, reinforce_rate)
        end

        tidy_PosProbMat!(P) # corrects floating point error



        parent_sub, parent_fitness = next_in_lineage(parent_sub, new_substitutions, parent_fitness, delta_F; lineage_habit)
        # advance lineage


        push!(fitness_log, parent_fitness)
        push!(div_log, PosProbMat_divergence(target, P))

        heatmap(P, clims = (0, 0.5), aspect_ratio = :equal)
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
        P = new_PosProbMat(txt)

        parent_sub = Substitution(txt.character_space)

    else # if given, use best guesses for ppM and substitution
        P = new_PosProbMat(txt, ref_freq)

        parent_sub = frequency_matched_Substitution(txt, ref_freq) # guesses FORWARDS substitution
        invert!(parent_sub)
    end

    indices = keys(P)

    parent_fitness = fitness(apply(parent_sub, txt))

    for gen in 1:generations
        swaps = generate_swaps(indices, parent_sub, P, choice_weights(gen, parent_fitness, txt.character_space.size), spawns)
        new_substitutions = [switch(parent_sub, m, n) for (a, b, m, n) in swaps]
        delta_F = [fitness(new_sub(txt)) for new_sub in new_substitutions] .- parent_fitness
        # generates new swaps from ppM and calculates dF


        for ((a, b, m, n), dF) in zip(swaps, delta_F) # Update P with ALL the data
            update_PosProbMat!(P, a, b, m, n, dF, reinforce_rate)
        end

        tidy_PosProbMat!(P) # corrects floating point error


        parent_sub, parent_fitness = next_in_lineage(parent_sub, new_substitutions, parent_fitness, delta_F; lineage_habit)
        # advance lineage

    end



    invert!(parent_sub) # return the "solved" FORWARDS substitution

    return P, parent_sub
    # Reinforced Matrix // final Substitution in lineage
end












# # Tailored to benchmark tests
# function benchmark_linear_reinforcement(
#     inv_target::Substitution,
#     txt::Txt,
#     generations::Int,
#     spawns::Int,
#     choice_weights::Function,
#     fitness::Function,
#     ref_freq::Union{Vector{Float64}, Nothing} = nothing,
#     reinforce_rate::Float64 = 0.5;
#     lineage_habit::String = "ascent"
# )


#     if isnothing(ref_freq) # if not given, start with identity substitution and uniform ppM
#         P = new_PosProbMat(txt)

#         parent_sub = Substitution(txt.character_space)

#     else # if given, use best guesses for ppM and substitution
#         P = new_PosProbMat(txt, ref_freq)

#         parent_sub = frequency_matched_Substitution(txt, ref_freq) # guesses FORWARDS substitution
#         invert!(parent_sub)
#     end


#     parent_fitness = fitness(apply(parent_sub, txt))

#     fitness_arr = Vector{Float64}(undef, generations + 1)
#     fitness_arr[1] = parent_fitness
#     # fitness tracking

#     check_if_solved = true
#     solved_in = generations

#     for gen in 1:generations
#         swaps = generate_swaps(parent_sub, P, choice_weights(gen, parent_fitness, txt.character_space.size), spawns)
#         new_substitutions = [switch(parent_sub, m, n) for (a, b, m, n) in swaps]
#         delta_F = fitness.(apply.(new_substitutions, Ref(txt))) .- parent_fitness
#         # generates new swaps from ppM and calculates dF


#         for ((a, b, m, n), dF) in zip(swaps, delta_F) # Update P with ALL the data
#             update_PosProbMat!(P, a, b, m, n, dF, reinforce_rate)
#         end

#         tidy_PosProbMat!(P) # corrects floating point error



#         parent_sub, parent_fitness = next_in_lineage(parent_sub, new_substitutions, parent_fitness, delta_F; lineage_habit)
#         # advance lineage

#         fitness_arr[gen + 1] = parent_fitness


#         if check_if_solved
#             if parent_sub == inv_target
#                 solved_in = gen + 1
#                 check_if_solved = false
#             end
#         end

#     end

#     return fitness_arr, solved_in
#     # fitness data // number of generations to solve
# end











# Probe at fitness(S) the convergence density, averaging over all swaps with reinforce_rate == 1 (definition)
# S is a guess of the INVERSE substitution
function probe_info_density(S::Substitution, target::Substitution, sample_txt::Txt, fitness::Function, target_fitness::Float64)
    start = new_PosProbMat(S)
    N = S.size
    S_fitness = fitness(apply(S, sample_txt))
    start_div = PosProbMat_divergence(target, start)

    avg_delta_divergence = 0

    for m in 1:N
        for n in 1:N
            P = copy(start)

            a = S[m]
            b = S[n]

            delta_f = fitness(apply(switch(S, m, n), sample_txt))
            delta_f -= S_fitness

            update_PosProbMat!(P, a, b, m, n, delta_f, 1)

            avg_delta_divergence += PosProbMat_divergence(target, P)
        end
    end

    avg_delta_divergence /= N ^ 2
    avg_delta_divergence -= start_div

    return S_fitness - target_fitness, - avg_delta_divergence
    # relative fitness level of probe // information density
end
