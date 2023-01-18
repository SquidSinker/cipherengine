using FFTW
include("cipher.jl")

function Conv1D_reals(a::Vector{T}, b::Vector{T}) where T <: Real
    N = length(a)
    M = length(b)

    a = [a ; zeros(M - 1)]     # N + M - 1
    b = [b ; zeros(N - 1)]     # N + M - 1

    return ifft(fft(a) .* fft(b))
end
Conv1D(a::Vector{Int}, b::Vector{Int}) = round.(Int, real.(Conv1D_reals(a, b)))


function invConv1D_reals(conv::Vector{T}, filter::Vector{T}) where T <: Real
    K = length(conv)
    M = length(filter)
    
    filter = [filter ; zeros(K - M)]

    return ifft(fft(conv) ./ fft(filter))[1 : K - M + 1]
end
invConv1D(a::Vector{Int}, b::Vector{Int}) = round.(Int, real.(invConv1D_reals(a, b)))


#######################################################################################


mutable struct Convolution <: AbstractCipher
    filter::Vector{Int}

    inverted::Bool

    function Convolution(filter::Vector{Int})
        new(filter, false)
    end
end

apply(Q::Convolution, v::Vector{Int}; safety_checks::Txt) = Q.inverted ? invConv1D(v, Q.filter) : Conv1D(v, Q.filter)

invert!(Q::Convolution) = switch_invert_tag!(Q)