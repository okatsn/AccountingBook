using AccountingBook, DataFrames
using CSV
using Chain

# Read secrets from environment variables instead of command-line arguments for security
const sheetid = ENV["GSHEET_KEY"]
const sheetid2 = ENV["GSHEET2_KEY"] # The key to the book of transferring.

const this_week = now() |> week
const this_year = now() |> year

t0_week = floor(now(), Week) + Day(1) + Hour(8) # we are at UTC+8
t1_week = t0_week + Week(1)

t0_year = floor(now(), Year) + Hour(8) # we are at UTC+8
t1_year = t0_year + Year(1)



url = "https://docs.google.com/spreadsheets/d/$sheetid/edit?usp=sharing"
url2 = "https://docs.google.com/spreadsheets/d/$sheetid2/edit?usp=sharing"
df0 = readgsheet(url)
df0a = readgsheet(url2)


df = preparesheet(df0)
df2 = preparesheet2(df0a)


mkpath(dir_data("transfer"))
mkpath(dir_data("expense"))
CSV.write(dir_data("expense", "book.csv"), df)
CSV.write(dir_data("transfer", "book.csv"), df2)

net_expense = @chain df begin
    select(Not([:inout, :amount]), [:inout, :amount] => ByRow((s, v) -> numinout(s) * v) => :flows)
    groupby(:whosaccount)
    combine(:flows => sum => :netflow_expense)
    select(:whosaccount => ByRow(getaccountname), :netflow_expense; renamecols=false)
end

CSV.write(dir_data("expense", "summary_overall.csv"), net_expense)

net_transfer_by_item = @chain df2 begin
    transform(Cols(:inout, :amount) => ByRow((s, v) -> numinout(s) * v) => :svalue)
    groupby([:whosaccount, :item, :assettype, :unit]) # For one's summary (net flow) by item by unit.
    combine(:svalue => sum => :svalue)
    # describe
    sort([:whosaccount, :assettype, :item, :unit])
end

CSV.write(dir_data("transfer", "summary_by_item.csv"), net_transfer_by_item)


net_cashflow = @chain net_transfer_by_item begin
    subset(:assettype => ByRow(x -> x == "現金"))
    groupby([:whosaccount, :unit])
    combine(:svalue => sum => :cashflow)
end
