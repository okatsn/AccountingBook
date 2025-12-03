using AccountingBook, DataFrames
using Statistics
using CSV
using Chain
using PrettyTables
using HypertextLiteral
using Markdown
using Test
using Dates

sheetid = ARGS[1]

url = "https://docs.google.com/spreadsheets/d/$sheetid/edit?usp=sharing"
df0 = readgsheet(url)

df = preparesheet(df0)
