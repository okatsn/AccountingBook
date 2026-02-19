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
const timespanfilter = :time => (dt -> t1_week > dt ≥ t0_week)



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


net_transfer_by_item = summary_transfer_all(df2)
net_cashflow = subset_transfer_cash(net_transfer_by_item)
dfthisweek = filter(timespanfilter, df)
dfthisweek_sum = summary_expense(dfthisweek)
net_expense = summary_expense(df)

CSV.write(dir_data("transfer", "summary_by_item.csv"), net_transfer_by_item)
CSV.write(dir_data("expense", "book_thisweek.csv"), dfthisweek |> book_svalue)
CSV.write(dir_data("expense", "summary_thisweek.csv"), dfthisweek_sum)
CSV.write(dir_data("expense", "summary_overall.csv"), net_expense)
