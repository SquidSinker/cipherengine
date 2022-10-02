include("substitution.jl")
include("charspace.jl")
include("tuco.jl")

text = uppercase("This book is about testing, experimenting, and playing with language. It is a handbook of tools and techniques for taking words apart and putting them back together again in ways that I hope are meaningful and legitimate (or even illegitimate). This book is about peeling back layers in search of the language-making energy of the human spirit. It is about the gaps in meaning that we urgently need to notice and name—the places where our dreams and ideals are no longer fulfilled by a society that has become fast-paced and hyper-commercialized.

Language is meant to be a playful, ever-shifting creation but we have been taught, and most of us continue to believe, that language must obediently follow precisely prescribed rules that govern clear sentence structures, specific word orders, correct spellings, and proper pronunciations. If you make a mistake or step out of bounds there are countless, self-appointed language experts who will promptly push you back into safe terrain and scold you for your errors. And in case you need reminding, there are hundreds of dictionaries and grammar books to ensure that you remember the “right” way to use English.

With this backdrop and training in mind it might come as a bit of a shock to discover that this “ideology of language”, with its preening emphasis on “correctness, authority, prestige, and legitimacy”, represents only one small blip in the long and rich history of the English language. And, for better or worse, we live in a moment in history when a tightly controlled language, economy, and political system work together to create a culture of lies that best serves a powerful elite, allowing them to continue funneling power and money (i.e. influence) to themselves at great cost to human communities and natural ecosystems.

In its heart and soul, language can also be a revolutionary force and it can be used to call forth lies; but you cannot have a revolution if you use the language of the conquerors. So one goal of this book is to awaken language and explore the capacity that all of us possess to be alive in our language. Being awake and being alive is in itself a revolutionary act—something which Noah Webster, Thomas Jefferson, and many other important early American thinkers were keenly aware of.

In our busy modern lives we have largely forgotten that language is meant to be inventive and playful, that hidden beneath the veneer of modernity the English language is potent with ancient magic-making power. Throughout this book I will refer repeatedly to “play” but I’m not speaking about play as something trivial, I’m speaking of play as something profoundly creative and freeing. And underneath everything, this playful exploration of language is about dissent, about rising up and crying out in support of that which is alive and vital. This book is about imagination, about truth-telling and contemplation; it is an undertaking that is fierce, creative, and honest.")

W = Alphabet(false)
(v, cases) = tokenise(text, W)

stop = quadgramlog(v)

S = Substitution("ABKLMNOPQCRSVZHIJDEFGWXYUT")
c = S(v)

print("Beginning benchmark...")

include("genetic_crack.jl")

fitnesses = []
lengths = []

for i in 1:50
    ## RUN
    best, fitness = crack_track(c, 18, stop)

    N = length(fitness)
    append!(lengths, N)

    # println(untokenise(best(c), W; cases))
    ## STOP and PROCESS

    while length(fitness) <= 355
        append!(fitness, fitness[end])
    end

    append!(fitnesses, [fitness])

    print(i)
end

fitnesses = permutedims(hcat(fitnesses...))

avg = sum(fitnesses, dims = 1) / 51
avgL = sum(lengths) / 50

using Plots
plot(avg)