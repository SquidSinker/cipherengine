include("tuco.jl")
include("charspace.jl")
include("genetics.jl")

using JLD2
@load "english_monogram_frequencies.jld2" english_frequencies


function sort_by_values(d::Dict)
    a = sort(collect(d), by=x->x[2])
    return [x[1] for x in a]
end

eng = sort_by_values(english_frequencies)

function crack_track(vect::Vector{Int}, spawns::Int, stop)
    f = sort_by_values(frequencies(vect))
    for i in 1:26
        if !(i in f)
            insert!(f, 1, i)
        end
    end

    start = Substitution([f[findfirst(x -> isequal(x,i), eng)] for i in 1:26])


    return evolve_until(x -> x(vect), mutate, start, spawns, stop - 0.5, 350, quadgramlog)
end

# ONLY FOR 26-TOKEN CSPACES
function crack_genetic(vect::Vector{Int}, spawns::Int) # token vector // number of mutatated subs spawned each genereation

    f = sort_by_values(frequencies(vect)) # vector of token indices (Ints) sorted in ascending frequencies
    for i in 1:26
        if !(i in f)
            insert!(f, 1, i)
        end
    end
    # Appends any tokens that did not appear

    start = Substitution([f[findfirst(x -> isequal(x,i), eng)] for i in 1:26]) # starts with letters arranged by frequencies against english_frequencies


    return evolve_until(x -> invert(x)(vect), mutate, start, spawns, stop - 0.5, 350, quadgramlog)
end