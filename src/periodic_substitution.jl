include("substitution.jl")
import Base.setindex!



############ MULTI Substitutions FRAMEWORK ################################################

mutable struct PeriodicSubstitution <: AbstractCipher
    subs::Vector{Substitution}
    length::Int

    function PeriodicSubstitution(substitutions::Vector{Substitution})
        size_one = substitutions[1].size
        if any([i.size != size_one for i in substitutions])
            error("All Substitutions must be of the same size")
        end

        new(substitutions, length(substitutions))
    end
end
PeriodicSubstitution(substitutions::Substitution...) = PeriodicSubstitution(substitutions)

length(S::PeriodicSubstitution) = S.length
getindex(S::PeriodicSubstitution, inds) = getindex(S.subs, inds)
iterate(S::PeriodicSubstitution) = iterate(S.subs)
iterate(S::PeriodicSubstitution, i::Integer) = iterate(S.subs, i)
setindex!(S::PeriodicSubstitution, val::Substitution, ind::Int) = setindex!(S.subs, val, ind)

==(A::PeriodicSubstitution, B::PeriodicSubstitution) = ==(A.subs, B.subs)

# Applies MultiSubstitution to Integer Vectors
function apply(S::PeriodicSubstitution, vector::Vector{Int}; safety_checks::Txt) ::Vector{Int}
    vect = Vector{Int}(undef, length(vector))

    for (i, j) in enumerate(S)
        vect[i:S.length:end] .= apply(j, vector[i:S.length:end]; safety_checks = safety_checks)
    end

    return vect
end

invert!(S::PeriodicSubstitution) = invert!.(S)

function show(io::IO, S::PeriodicSubstitution)
    if S.length > 8
        for i in 1:8
            show(io, S[i])
            print("\n")
        end

        for _ in 1:3
            print(".\n")
        end

    else
        for sub in S.subs
            show(io, sub)
            print("\n")
        end

    end
end

function show(io::IO, ::MIME"text/plain", S::PeriodicSubstitution)
    println(io, "$(S[1].size)-element $(S.length)-Periodic Substitution:")
    if S.length > 8
        for i in 1:8
            show(io, S[i])
            print("\n")
        end

        for _ in 1:3
            print(".\n")
        end

    else
        for sub in S.subs
            show(io, sub)
            print("\n")
        end
        
    end
end






# Presets
function Vigenere(vect::Vector{Int}, size::Union{Int, CSpace}) ::PeriodicSubstitution
    return PeriodicSubstitution([Caesar(i, size) for i in vect])
end
Vigenere(num::Int, size::Union{Int, CSpace}) = Vigenere(zeros(Int, num), size)
Vigenere(vect::Vector{String}, W::CSpace) ::PeriodicSubstitution = Vigenere(tokenise.(vect, Ref(W)) .- 1, W) # Subtracting one to standardise for 0-based indexing
Vigenere(vect::Vector{Char}, W::CSpace) ::PeriodicSubstitution = Vigenere(string.(vect), W)
Vigenere(string::String, W::CSpace) ::PeriodicSubstitution = W.n == 1 ? Vigenere(collect(string), W) : error("Character Space must be 1-gram for String argument to be tokenised")


function Periodic_Affine(vect::Vector{Tuple{Int, Int}}, size::Union{Int, CSpace}) ::PeriodicSubstitution
    return PeriodicSubstitution([Affine(a, b, size) for (a, b) in vect])
end
Periodic_Affine(vecta::Vector{Int}, vectb::Vector{Int}, size::Union{Int, CSpace}) ::PeriodicSubstitution = length(vecta) == length(vectb) ? Periodic_Affine(collect(zip(vecta, vectb)), size) : error("Parameter vectors must have same length")
Periodic_Affine(num::Int, size::Union{Int, CSpace}) = Periodic_Affine(ones(Int, num), zeros(Int, num), size)