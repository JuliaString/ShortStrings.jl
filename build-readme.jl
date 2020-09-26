# Weave readme
using Pkg
cd("c:/git/ShortStrings/")
Pkg.activate("c:/git/ShortStrings/readme-env")

using Weave

weave("README.jmd", out_path = :pwd, doctype = "github")

if false
    tangle("README.jmd")
end
