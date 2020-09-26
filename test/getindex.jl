using Test
using ShortStrings

s = "∫x ∂x"

ss = ShortString15(s)

@test s[1] == ss[1]