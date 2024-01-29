using AccountingBook
using Documenter
# using DocumenterCitations
# # 1. Uncomment this line and the CitationBibliography line
# # 2. add docs/src/refs.bib
# # 3. Cite something in refs.bib and add ```@bibliography ``` (in index.md, for example)
# # Please refer https://juliadocs.org/DocumenterCitations.jl/stable/


DocMeta.setdocmeta!(AccountingBook, :DocTestSetup, :(using AccountingBook); recursive=true)

makedocs(;
    modules=[AccountingBook],
    authors="okatsn <okatsn@gmail.com> and contributors",
    repo="https://github.com/okatsn/AccountingBook/blob/{commit}{path}#{line}",
    sitename="AccountingBook",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://okatsn.github.io/AccountingBook",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
    # plugins=[
    #     CitationBibliography(joinpath(@__DIR__, "src", "refs.bib")),
    # ],
)

deploydocs(;
    repo="github.com/okatsn/AccountingBook",
    devbranch="main",
)
