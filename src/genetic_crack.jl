include("tuco.jl")
include("charspace.jl")
include("genetics.jl")



# For analysis only
function crack_track(vtoken::Vector{Int}, spawns::Int, stop)
    start = eng_frequency_matched_substitution(vtoken)

    return evolve_until(x -> x(vtoken), mutate, start, spawns, stop - 0.5, 350, quadgramlog)
end

# ONLY FOR 26-TOKEN CSPACES
function crack_genetic(vtoken::Vector{Int}, spawns::Int, gen::Int) # token vector // number of mutatated subs spawned each genereation
    start = eng_frequency_matched_substitution(vtoken)

    return evolve_silent(x -> invert(x)(vtoken), mutate, start, spawns, 350, quadgramlog)
end