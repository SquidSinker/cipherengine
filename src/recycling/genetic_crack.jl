include("../tuco.jl")
include("../charspace.jl")
include("../substitution.jl")
include("../genetics.jl")



# For analysis only
function crack_track(vtoken::Vector{Int}, spawns::Int, stop)
    start = eng_frequency_matched_substitution(vtoken)

    return evolve_until(x -> x(vtoken), mutate, start, spawns, stop - 0.5, 350, quadgramlog)
end