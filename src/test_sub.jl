include("substitution.jl")
include("charspace.jl")

text = "Oh my god it's Ali-A back with a Fortnite Battle Royale Season 5 review"

W = Alphabet()

(v, cases) = tokenise(text, W)

S = Substitution("ABCDEFGHIJKLMNOPQRSVUTWXYZ")

c = S(v)

print(untokenise(c, W; cases))