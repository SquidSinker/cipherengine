include("substitution.jl")
include("tuco.jl")
import LinearAlgebra.checksquare, Base.getindex, Base.setindex!
import StatsBase.sample, StatsBase.pweights


mutable struct PosProbMatrix
    arr::Matrix{Float64}

    size::Int
    update_rate::Float64

    indices::CartesianIndices{2, Tuple{Base.OneTo{Int64}, Base.OneTo{Int64}}}

    function PosProbMatrix(arr::Matrix{Float64}, size::Int, update_rate::Float64)
        return new(arr, size, update_rate, CartesianIndices((size, size)))
    end
end

function PosProbMatrix(n::Int, update_rate::Float64) ::PosProbMatrix
    return PosProbMatrix(fill(1 / n, (n,n)), n, update_rate)
end

function PosProbMatrix(a::Matrix{Float64}, update_rate::Float64) ::PosProbMatrix
    return PosProbMatrix(clamp.(a, 0., 1.), checksquare(a), update_rate)
end

getindex(ppm::PosProbMatrix, args...) = getindex(ppm.arr, args...)


function update!(ppm::PosProbMatrix, x1::Int, x2::Int, y1::Int, y2::Int, dF::Float64) ::PosProbMatrix
    d1 = update_delta(dF, ppm[x1, y1], ppm[x1, y2], ppm.update_rate)
    d2 = update_delta(dF, ppm[x2, y2], ppm[x2, y1], ppm.update_rate)

    if isnan(d1) || isnan(d2)
        println(ppm[x1, y1], ppm[x1, y2])
        println(ppm[x2, y2], ppm[x2, y1])        
        error("NaN error")
    end

    ppm.arr[x1, y1] -= d1
    ppm.arr[x1, y2] += d1

    ppm.arr[x2, y2] -= d2
    ppm.arr[x2, y1] += d2

    for i in (x1, x2)
        for j in (y1, y2)
            ppm.arr[i,j] = clamp(ppm.arr[i,j], 0., 1.)
        end
    end

    return ppm
end

# ZEROS ARE STUCK
# Limiting function taking (-inf, inf) -> (-p_new, p_old), with update_delta(0) == 0
function update_delta(delta_fitness::Float64, p_old::Float64, p_new::Float64, rate::Float64) ::Float64

    if p_old == 0. || p_new == 0.
        return 0.
    end

    if rate == Inf # maximum learn rate
        if delta_fitness == 0.
            return 0.0
        elseif delta_fitness > 0.
            return p_old
        else
            return (- p_new)
        end
    end


    mu = p_old + p_new # division by 2 carried out at the end
    diff = p_old - p_new # division by 2 carried out at the end

    z = coth(rate * delta_fitness)

    delta = 2 * p_old * p_new / (mu * z - diff)

    return clamp(delta, - p_new, p_old)
end


# no choice weights / bias
# current_x_to_y findfirst search may be slower than an invert for number ≈ length(current_x_to_y)
function draw(ppm::PosProbMatrix, current_x_to_y::Vector{Int}, number::Int) ::Vector{Tuple{Int, Int, Int, Int}}
    
    out = Vector{Tuple{Int64, Int64, Int64, Int64}}(undef, number)
    draw_matrix = copy(ppm.arr)

    for (x,y) in enumerate(current_x_to_y)
        draw_matrix[x,y] = 0.
    end

    samples = sample(ppm.indices, pweights( draw_matrix ), number, replace = false) # Vector{Tuple} (x1, y2)

    x1 = [i[1] for i in samples]
    y2 = [i[2] for i in samples]

    x2 = [findfirst(==(i), current_x_to_y) for i in y2]
    y1 = [current_x_to_y[i] for i in x1]


    return collect(zip(x1, x2, y1, y2))
end




###########################################################################################################

function batch_binomial_pd(X::Vector{Int}, N::Int, p::Float64) ::Vector{Float64}
    mu = N * p
    var = 2 * mu * (1 - p) # 2 carried through to reduce operations

    M = 7e2 - (maximum(X) - mu)^2 / var

    PX = [exp( M - (x - mu)^2 / var ) for x in X]

    PX = safe_normalise(PX)
    
    #PX[PX .== 0] .= 1e-300

    return PX
end

function safe_normalise(a::Vector) ::Vector
    s = sum(a)
    if s == 0 | isnan(s)
        L = length(a)
        return fill(1 / L, (L,))
    end
    return a / s
end



# batch binomial probabilities A[i,j] that token j represents i (forwards i -> j)
function bbin_probabilities(txt::Txt, ref_frequencies::Vector{Float64} = monogram_freq) ::Matrix{Float64}
    tallies = appearances(txt)
    L = length(txt)

    return permutedims(hcat([batch_binomial_pd(tallies, L, i) for i in ref_frequencies]...))
end





####################################################################################################

# Fitness function for PosProbMat, calculates Kullback-Leibler Divergence between PosProbMat and the target (certain) PosProbMat
function ppm_kldiv(ppm::PosProbMatrix, target_x_to_y::Vector{Int}) ::Float64
    s = 0

    for (x, y) in enumerate(target_x_to_y)
        s += log2(ppm[x, y])
    end

    return - s / ppm.size
end

















# Work out next parent in lineage, based on lineage_habit type
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



#################################################################################################################

using Plots

# x (token) -> y (position in sub)
# S.mapping represents y -> x, so invperm is used, which is slow
# this solves for the inverse substitution
# Substitution solver, where ppM supervises a single substitution lineage
function debug_substitution_solve(
    inv_target::Substitution,
    txt::Txt,
    generations::Int,
    spawns::Int,
    fitness::Function,
    ref_freq::Union{Vector{Float64}, Nothing} = nothing,
    reinforce_rate::Float64 = 0.5;
    lineage_habit::String = "ascent"
)

    N = inv_target.size

    if isnothing(ref_freq) # if not given, start with identity substitution and uniform ppM
        ppm = PosProbMatrix(N, reinforce_rate)

        parent_sub = Substitution(N)

    else # if given, use best guesses for ppM and substitution
        ppm = PosProbMatrix(bbin_probabilities(txt, ref_freq), reinforce_rate)

        parent_sub = frequency_matched_Substitution(txt, ref_freq) # guesses FORWARDS substitution
        invert!(parent_sub)
    end

    parent_fitness = fitness(apply(parent_sub, txt))
    fitness_log = [parent_fitness]
    div_log = [ppm_kldiv(ppm, invperm(inv_target.mapping))]

    heatmap(ppm.arr, clims = (0, 1), aspect_ratio = :equal, xlabel = "x", ylabel = "y")

    anim = @animate for gen in 1:generations
        swaps = draw(ppm, invperm(parent_sub.mapping), spawns)
        new_substitutions = [switch(parent_sub, y1, y2) for (x1, x2, y1, y2) in swaps]
        delta_F = [fitness(new_sub(txt)) for new_sub in new_substitutions] .- parent_fitness
        # generates new swaps from ppM and calculates dF


        for ((x1, x2, y1, y2), dF) in zip(swaps, delta_F) # Update P with ALL the data
            update!(ppm, x1, x2, y1, y2, dF)
        end


        parent_sub, parent_fitness = next_in_lineage(parent_sub, new_substitutions, parent_fitness, delta_F; lineage_habit = lineage_habit)
        # advance lineage


        push!(fitness_log, parent_fitness)
        push!(div_log, ppm_kldiv(ppm, invperm(inv_target.mapping)))

        heatmap!(ppm.arr)
        # scatter!([i[4] for i in swaps], [i[1] for i in swaps], color = :blue, markershape = :rect, label = false)
        # scatter!([i[3] for i in swaps], [i[2] for i in swaps], color = :blue, markershape = :rect, label = false)
        # scatter!([i[3] for i in swaps], [i[1] for i in swaps], color = :blue, markershape = :rect, label = false)
        # scatter!([i[4] for i in swaps], [i[2] for i in swaps], color = :blue, markershape = :rect, label = false)
    end

    
    gif(anim, "anim.gif")

    invert!(parent_sub) # return the "solved" FORWARDS substitution

    return ppm, parent_sub, fitness_log, div_log
    # Reinforced Matrix // final Substitution in lineage // Vector of fitness values vs generations // Vector of divergence vs gen
end


function substitution_solve(
    N::Int,
    txt::Txt,
    generations::Int,
    spawns::Int,
    fitness::Function,
    ref_freq::Union{Vector{Float64}, Nothing} = nothing,
    reinforce_rate::Float64 = 0.5;
    lineage_habit::String = "ascent"
)

    if isnothing(ref_freq) # if not given, start with identity substitution and uniform ppM
        ppm = PosProbMatrix(N, reinforce_rate)

        parent_sub = Substitution(N)

    else # if given, use best guesses for ppM and substitution
        ppm = PosProbMatrix(bbin_probabilities(txt, ref_freq), reinforce_rate)

        parent_sub = frequency_matched_Substitution(txt, ref_freq) # guesses FORWARDS substitution
        invert!(parent_sub)
    end

    parent_fitness = fitness(apply(parent_sub, txt))

    for gen in 1:generations
        swaps = draw(ppm, invperm(parent_sub.mapping), spawns)
        new_substitutions = [switch(parent_sub, y1, y2) for (x1, x2, y1, y2) in swaps]
        delta_F = [fitness(new_sub(txt)) for new_sub in new_substitutions] .- parent_fitness
        # generates new swaps from ppM and calculates dF


        for ((x1, x2, y1, y2), dF) in zip(swaps, delta_F) # Update P with ALL the data
            update!(ppm, x1, x2, y1, y2, dF)
        end


        parent_sub, parent_fitness = next_in_lineage(parent_sub, new_substitutions, parent_fitness, delta_F; lineage_habit = lineage_habit)
        # advance lineage
    end


    invert!(parent_sub) # return the "solved" FORWARDS substitution

    return ppm, parent_sub
    # Reinforced Matrix // final Substitution in lineage
end







