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
t0_week = floor(now(), Week) + Day(1) + Hour(8) # we are at UTC+8
t1_week = t0_week + Week(1)

t0_year = floor(now(), Year) + Hour(8) # we are at UTC+8
t1_year = t0_year + Year(1)

calc_svalue = df -> transform(df, Cols(:inout, :amount) => ByRow((s, v) -> numinout(s) * v) => :svalue)

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
CSV.write(dir_data("expense", "book.csv"), df)
CSV.write(dir_data("transfer", "book.csv"), df2)

summary_expense(df) = @chain df begin
    calc_svalue
    groupby([:whosaccount, :unit])
    combine(:svalue => sum => :netflow)
    sort([:whosaccount, :unit])
end

net_expense = summary_expense(df)

CSV.write(dir_data("expense", "summary_overall.csv"), net_expense)

summary_transfer_all(df2) = @chain df2 begin
    calc_svalue
    groupby([:whosaccount, :item, :assettype, :unit]) # For one's summary (net flow) by item by unit.
    combine(:svalue => sum => :svalue)
    # describe
    sort([:whosaccount, :assettype, :item, :unit])
end

net_transfer_by_item = summary_transfer_all(df2)

CSV.write(dir_data("transfer", "summary_by_item.csv"), net_transfer_by_item)

subset_transfer_cash(net_transfer_by_item) = @chain net_transfer_by_item begin
    subset(:assettype => ByRow(x -> x == "現金"))
    groupby([:whosaccount, :unit])
    combine(:svalue => sum => :cashflow)
end

net_cashflow = subset_transfer_cash(net_transfer_by_item)


dfthis = @chain df begin
    filter(:time => (dt -> t1_week > dt ≥ t0_week), _)
    calc_svalue
    select(Not(:inout, :amount))
    transform(:whosaccount => ByRow(getaccountname); renamecols=false)
end

CSV.write(dir_data("expense", "book_thisweek.csv"), dfthis)

dfthis_sum = @chain dfthis begin
    groupby(:whosaccount)
    combine(:svalue => sum => :netflow)
end



CSV.write(dir_data("expense", "summary_thisweek.csv"), dfthis_sum)
