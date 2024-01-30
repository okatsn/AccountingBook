using AccountingBook, DataFrames
using Statistics
using CSV
using Chain
using PrettyTables
using HypertextLiteral
using Markdown
using Test
using SMTPClient
using Dates

arg4 = Dict(
    "Weekly" => Arg4(subject="兩豬家記帳本週摘要", interval=Dates.Week),
    "Yearly" => Arg4(subject="兩豬家記帳本年摘要", interval=Dates.Year),
)[ARGS[4]]

sheetid = ARGS[3]
sender = ARGS[1]

url = "https://docs.google.com/spreadsheets/d/$sheetid/edit?usp=sharing"
df0 = readgsheet(url)


t1 = now() + Hour(8) # we are at UTC+8
t0 = t1 - arg4.interval(1)

df = @chain df0 begin
    select("時間戳記" => ByRow(convertdatetime) => :time,
        "電子郵件地址" => :email,
        "項目" => :item,
        "支出或收入" => :inout,
        "從誰的口袋" => :whosaccount,
        "金額" => :amount,
        "備註" => :memo,)
end

summary = @chain df begin
    select(Not([:inout, :amount]), [:inout, :amount] => ByRow((s, v) -> numinout(s) * v) => :flows)
    groupby(:whosaccount)
    combine(:flows => sum => :netflow)
    select(:whosaccount => ByRow(getaccountname), :netflow; renamecols=false)
end


dfthis = @chain df begin
    filter(:time => (dt -> t1 > dt ≥ t0), _)
    transform(:memo => ByRow(x -> ifelse(ismissing(x), "", x)), [:inout, :amount] => ByRow((s, v) -> numinout(s) * v) => :flows; renamecols=false)
    select(Not(:inout, :amount))
    transform(:whosaccount => ByRow(getaccountname); renamecols=false)
end

dfthis_sum = @chain dfthis begin
    groupby(:whosaccount)
    combine(:flows => sum => :netflow)
end


recipients = unique(df0[!, "電子郵件地址"])
# uniquewhos = unique(df[!, :whosaccount])


# """
# Convert "A" or "B" to readable nicknames.
# """
# convertfromAB(str) = Dict(getmatch.(r"[AB]", uniquewhos) .=> getmatch.(r"[\u4e00-\u9fff]+", uniquewhos))[str]


function render_table2(df)
    d = Dict(:whosaccount => "帳戶", :item => "品項", :memo => "備註", :flows => "入/出", :netflow => "淨入/出")
    renamer(col) = get(d, Symbol(col), col) # rename seems to convert a column name (`col`) to string before sending it to the function (i.e., renamer)
    @chain df begin
        rename(renamer, _)
        render_table
    end
end


# Send Email
opt = SendOptions(
    isSSL=true,
    username=sender,
    passwd=ARGS[2],
)

url = "smtps://smtp.gmail.com:465"

subject = arg4.subject
from = "<$sender>"

msg0 = @htl("""
<html>

    <head>
        <style>
        h1 {
            font-size: 24px;
            font-weight: bold;
        }

        h2 {
            font-size: 18px;
            font-weight: bold;
        }

        table {
            border-collapse: collapse;
            width: 100%;
        }

        table, th, td {
            border: 1px solid black;
        }
        </style>
    </head>

    <body>

        <p>
            <p><h1>$subject</h1></p>

            <p>$(render_table2(select(dfthis, Not(:email))))</p>

            <p><h2>Summary of this $(arg4.interval):</h2></p>

            <p>$(render_table2(dfthis_sum))</p>

            <p><h2>Overall Summary:</h2></p>

            <p>$(render_table2(summary))</p>

        </p>

    </body>
</html>
""")

for r in recipients
    # r = recipients[1]
    rcpt = to = ["<$r>"]
    io = IOBuffer()
    print(io, msg0)

    message = get_mime_msg(HTML(String(take!(io)))) # do this if message is HTML
    body = get_body(to, from, subject, message) # cc, replyto)
    # Preview the body: String(take!(body)

    # rcpt = vcat(to, cc, bcc)
    resp = send(url, rcpt, from, body, opt)
end
