
# Currently untokenise() method has no reinsertion of frozen chars

struct CSpace
    tokenisation::Vector{Char}
    frozen::Vector{Char}
    case_sensitive::Bool

    function CSpace(tokens::Vector{Char}; frozen::Vector{Char} = Vector{Char}(), case_sensitive = false)

        if !case_sensitive
            tokens = unique(lowercase.(tokens))
            frozen = unique(lowercase.(frozen))
        end

        new(filter(x -> !(x in frozen), tokens), frozen, case_sensitive)
    end

end

CSpace(text::String; frozen::Vector{Char} = Vector{Char}(), case_sensitive = false) = CSpace(unique(text); frozen, case_sensitive)


function show(io::IO, W::CSpace)
    println("Character Space, case sensitive = ", W.case_sensitive)
    println("Tokens: ", W.tokenisation)
    println("Frozen: ", W.frozen)
end

function tokenise(text::String, W::CSpace)
    text = filter(x -> lowercase(x) in W.tokenisation, text)

    if W.case_sensitive
        return [findfirst(x -> isequal(x, i), W.tokenisation) for i in text]
    else
        return ([findfirst(x -> isequal(x, lowercase(i)), W.tokenisation) for i in text], [isuppercase(i) for i in text])
    end
end

function untokenise(vect::Vector{Int}, W::CSpace; cases::Vector{Bool})
    out = ""

    if W.case_sensitive
        for i in vect
            out *= W.tokenisation[i]
        end
    else
        for (i, upper) in zip(vect, cases)

            if upper
                out *= uppercase(W.tokenisation[i])
            else
                out *= W.tokenisation[i]
            end

        end
    end

    return out
end

Alphabet(case = false) = CSpace("ABCDEFGHIJKLMNOPQRSTUVWXYZ"; case_sensitive = case)