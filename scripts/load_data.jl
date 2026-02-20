using AccountingBook, DataFrames
using CSV
using Chain
using Dates

# Read secrets from environment variables instead of command-line arguments for security
const sheetid = ENV["GSHEET_KEY"]
const sheetid2 = ENV["GSHEET2_KEY"] # The key to the book of transferring.

const this_week = now() |> week
const this_year = now() |> year
const default_unit = "NTD"
const default_memo = ""





url = "https://docs.google.com/spreadsheets/d/$sheetid/edit?usp=sharing"
url2 = "https://docs.google.com/spreadsheets/d/$sheetid2/edit?usp=sharing"
df0 = readgsheet(url)
df0a = readgsheet(url2)


df = preparesheet(df0)
df2 = preparesheet2(df0a)

for dfi in [df, df2]
    transform!(dfi,
        :unit => ByRow(x -> ifelse(ismissing(x), default_unit, x)),
        :memo => ByRow(x -> ifelse(ismissing(x), default_memo, x))
        ; renamecols=false)
end

mkpath(dir_data("transfer"))
mkpath(dir_data("expense"))
mkpath(dir_data("combined"))
CSV.write(dir_data("expense", "book.csv"), df)
CSV.write(dir_data("transfer", "book.csv"), df2)


net_transfer_by_item = summary_transfer_all(df2)
net_cashflow = subset_transfer_cash(net_transfer_by_item)
net_transfer_by_item_thisweek = summary_transfer_all(df2 |> timespanfilter(now()))
net_cashflow_thisweek = subset_transfer_cash(net_transfer_by_item_thisweek)
dfthisweek = df |> timespanfilter(now())
net_expense_thisweek = summary_expense(dfthisweek)
net_expense = summary_expense(df)


overallsummary(net_expense, net_cashflow) = @chain reduce(vcat, [net_expense, net_cashflow]) begin
    groupby([:whosaccount, :unit])
    combine(:netflow => sum; renamecols=false)
end

net_overall = overallsummary(net_expense, net_cashflow)
net_overall_thisweek = overallsummary(net_expense_thisweek, net_cashflow_thisweek)

CSV.write(dir_data("combined", "summary_overall.csv"), net_overall)
CSV.write(dir_data("combined", "summary_thisweek.csv"), net_overall_thisweek)
CSV.write(dir_data("transfer", "summary_by_item_thisweek.csv"), net_transfer_by_item_thisweek)
CSV.write(dir_data("expense", "book_thisweek.csv"), dfthisweek |> book_svalue)
CSV.write(dir_data("expense", "summary_thisweek.csv"), net_expense_thisweek)
CSV.write(dir_data("expense", "summary_overall.csv"), net_expense)
