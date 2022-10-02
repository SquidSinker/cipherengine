function optimisefloor_silent(f::Function, floor, inputs::AbstractVector, fitness::Function)
    floorscore = fitness(f(floor))
    scores = [fitness(f(i)) for i in inputs]

    p = inputs[argmax(scores)]
    dF = maximum(scores) - floorscore
    return dF > 0 ? p : floor
end

function evolve_silent(f::Function, mutate::Function, parent, spawns::Int, generations::Int, fitness::Function)
    scores = Float64[]

    for i in 1:generations
        parent = optimisefloor_silent(f, parent, [mutate(parent) for i in 1:spawns], fitness)
        append!(scores, fitness(f(parent)))
    end

    return parent, scores
end

function evolve_until(f::Function, mutate::Function, parent, spawns::Int, fitness_threshold, max_runs, fitness::Function)
    scores = [fitness(f(parent))]

    i = 0
    while scores[end] < fitness_threshold
        i += 1
        if i > max_runs
            return parent, scores
        end

        parent = optimisefloor_silent(f, parent, [mutate(parent) for i in 1:spawns], fitness)
        append!(scores, fitness(f(parent)))
    end

    return parent, scores
end