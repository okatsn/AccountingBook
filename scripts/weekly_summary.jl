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

url = "https://docs.google.com/spreadsheets/d/$sheetid/edit?usp=sharing"
df0 = readgsheet(url)



@chain df0 begin
    select("時間戳記" => ByRow(convertdatetime) => :timestr,
        "電子郵件地址" => :email,
        "項目" => :item,
        "支出或收入" => :inout,
        "從誰的口袋" => :whosaccount,
        "金額" => :amount,
        "備註" => :memo,)
end
recipients = unique(df0[!, "電子郵件地址"])
