# Returns elemnt of input Vector that maximises x -> fitness(f(x)), with a floor item that is returned if no item has higher fitness
function optimisefloor_silent(f::Function, floor, inputs::AbstractVector, fitness::Function)
    floorscore = fitness(f(floor))
    scores = [fitness(f(i)) for i in inputs]

    p = inputs[argmax(scores)] # find item with highest fitness
    dF = maximum(scores) - floorscore # find the item's fitness
    return dF > 0 ? p : floor
end

# Mutates parent, spawning 'spawns' no. of mutated children, over 'generations' generations.
function evolve_silent(f::Function, mutate::Function, parent, spawns::Int, generations::Int, fitness::Function)
    scores = Float64[]

    for i in 1:generations
        parent = optimisefloor_silent(f, parent, [mutate(parent) for i in 1:spawns], fitness)
        append!(scores, fitness(f(parent)))
    end

    return parent, scores # genetically evolved item // vector of scores over generations
end

# evolve_silent() but it stops if fitness exceeds the fitness_threshold
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