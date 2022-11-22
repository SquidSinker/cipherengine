include("cipher.jl")
import Base.show

const valid_continuation_modes = Set(("blank", "repeat", "autokey"))

mutable struct Keystream <: AbstractCipher
    stem::Vector{Int}
    stem_length::Int

    mode::String

    inverted::Bool

    function Keystream(vect::Vector{Int}, continuation_mode::String = "blank")
        if !(continuation_mode in valid_continuation_modes)
            error("Invalid key continuation mode argument")
        end
        new(vect, length(vect), continuation_mode, false)
    end
end
Keystream(txt::Txt, continuation_mode::String = "blank") ::Keystream = txt.is_tokenised ? Keystream(txt.tokenised, continuation_mode) : error("Txt must be tokenised to create Keystream")
Keystream(txt::Txt, continuation_mode::String = "blank") ::Keystream = Keystream(txt, continuation_mode)

Keystream(vect::Vector{String}, W::CSpace, continuation_mode::String = "blank") ::Keystream = Keystream(tokenise.(vect, Ref(W)) .- 1, continuation_mode) # Subtracting one to standardise for 0-based indexing
Keystream(vect::Vector{Char}, W::CSpace, continuation_mode::String = "blank") ::Keystream = Keystream(string.(vect), W, continuation_mode)
Keystream(string::String, W::CSpace, continuation_mode::String = "blank") ::Keystream = W.n == 1 ? Keystream(collect(string), W, continuation_mode) : error("Character Space must be 1-gram for String argument to be tokenised")



function show(io::IO, K::Keystream)
    show(io, K.stem)
end

function show(io::IO, ::MIME"text/plain", K::Keystream)
    if K.inverted
        inverse_text = "Inverse "
    else
        inverse_text = ""
    end

    println(io, "$(K.stem_length)-token ", inverse_text, "Keystream (end continuation = ", K.mode, "):")
    show(io, K.stem)
end



function invert!(K::Keystream) ::Keystream
    K.inverted = !K.inverted
    return K
end

function apply(K::Keystream, v::Vector{Int}; safety_checks::Txt) ::Vector{Int}
    new_v = copy(v)
    L = length(v)

    if K.inverted

        if K.mode == "blank"
            stopindex = min(K.stem_length, L)
            new_v[begin : stopindex] .-= K.stem[begin : stopindex]
        
        elseif K.mode == "repeat"
            num_full_cycles = floor(Int, L / K.stem_length)
            remainder = L % K.stem_length

            for i in (0:num_full_cycles - 1) * K.stem_length
                active_indices = i + 1 : i + K.stem_length
                new_v[active_indices] .-= K.stem
            end

            new_v[end - remainder + 1 : end] .-= K.stem[begin : remainder]

        elseif K.mode == "autokey"
            diff = L - K.stem_length
            if diff <= 0
                new_v .-= K.stem[begin : L]
            else
                new_v[begin:K.stem_length] .-= K.stem

                num_full_cycles = floor(Int, L / K.stem_length)
                remainder = L % K.stem_length

                for i in (1:num_full_cycles - 1) * K.stem_length
                    new_v[i + 1 : i + K.stem_length] .-= new_v[i + 1 - K.stem_length : i]
                end

                new_v[end - remainder + 1 : end] .-= new_v[end - remainder + 1 - K.stem_length : end - K.stem_length]
                
            end
        
        end



    else

        if K.mode == "blank"
            stopindex = min(K.stem_length, L)
            new_v[begin : stopindex] .+= K.stem[begin : stopindex]
        
        elseif K.mode == "repeat"
            num_full_cycles = floor(Int, L / K.stem_length)
            remainder = L % K.stem_length

            for i in (0:num_full_cycles - 1) * K.stem_length
                active_indices = i + 1 : i + K.stem_length
                new_v[active_indices] .+= K.stem
            end

            new_v[end - remainder + 1 : end] .+= K.stem[begin : remainder]

        elseif K.mode == "autokey"
            diff = L - K.stem_length
            if diff <= 0
                new_v .+= K.stem[begin : L]
            else
                new_v[begin:K.stem_length] .+= K.stem
                new_v[K.stem_length + 1 : L] .+= v[begin : diff]
            end
        
        end
    end

    new_v .-= 1
    new_v = mod.(new_v, safety_checks.character_space.size)
    new_v .+= 1

    return new_v
end











Autokey(args...) = Keystream(args..., "autokey")
