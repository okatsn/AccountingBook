using AccountingBook, DataFrames
using Statistics
using CSV
using Chain
using PrettyTables
using HypertextLiteral
using Markdown
using Test
using SMTPClient

sheetid = ARGS[3]

# cloudtable = @suppress readgsheet("https://docs.google.com/spreadsheets/d/$sheetid/edit?usp=sharing")



url = "https://docs.google.com/spreadsheets/d/$sheetid/edit?usp=sharing"
df0 = readgsheet(url)
