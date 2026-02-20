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

const sender = ENV["GMAIL_APP_ADDRESS"]
const passwd = ENV["GMAIL_APP_KEY"]

arg4 = Dict(
    "Weekly" => Arg4(subject="兩豬家記帳本週摘要", interval=Dates.Week),
    "Yearly" => Arg4(subject="兩豬家記帳本年摘要", interval=Dates.Year),
)[ARGS[1]] # "Yearly" or "Weekly" - now the first argument



df = CSV.read(dir_data("expense", "book.csv"), DataFrame)
df2 = CSV.read(dir_data("transfer", "book.csv"), DataFrame)
net_overall = CSV.read(dir_data("combined", "summary_overall.csv"), DataFrame)
net_overall_thisweek = CSV.read(dir_data("combined", "summary_thisweek.csv"), DataFrame)
net_transfer_by_item_thisweek = CSV.read(dir_data("transfer", "summary_by_item_thisweek.csv"), DataFrame)
net_expense_thisweek = CSV.read(dir_data("expense", "summary_thisweek.csv"), DataFrame)
net_expense = CSV.read(dir_data("expense", "summary_overall.csv"), DataFrame)
df2_thisweek = timespanfilter(df2, now())


df2_thisweek_display = if nrow(df2_thisweek) == 0
    DataFrame("方向" => String[], "品項" => String[])
else
    @chain df2_thisweek begin
        sort([:time])
        sort([:inout]; rev=true) # to ensure point in the correct direction
        groupby([:time]; sort=false) # set `false` to ensure the same order
        combine(
            :time => (dt -> dt |> unique |> only |> string) => "時間",
            :whosaccount => (v -> "$(first(v)) ➡️ $(last(v))") => "方向",
            Cols(:item, :amount, :unit) => ((i, a, u) -> "$(first(i)) $(first(a)) $(first(u)) ➡️ $(last(i)) $(last(a)) $(last(u))") => "品項"
        )
        select(Not(:time))
    end
end

expense_thisweek = CSV.read(dir_data("expense", "book_thisweek.csv"), DataFrame)

if nrow(expense_thisweek) > 0
    transform!(expense_thisweek,
        :memo => ByRow(x -> ifelse(ismissing(x), "", x)),
        ; renamecols=false)
end


recipients = unique(skipmissing(vcat(df.email, df2.email))) |> collect
# uniquewhos = unique(df[!, :whosaccount])


# """
# Convert "A" or "B" to readable nicknames.
# """
# convertfromAB(str) = Dict(getmatch.(r"[AB]", uniquewhos) .=> getmatch.(r"[\u4e00-\u9fff]+", uniquewhos))[str]


function render_table2(df)
    d = Dict(:whosaccount => "帳戶", :item => "品項", :memo => "備註", :svalue => "入/出", :netflow => "淨入/出", :unit => "單位")
    renamer(col) = get(d, Symbol(col), col) # rename seems to convert a column name (`col`) to string before sending it to the function (i.e., renamer)
    @chain df begin
        rename(renamer, _)
        render_table
    end
end

"""Render a DataFrame as an HTML table, or show a 'no data' message when empty."""
function render_section(df; empty_msg="No data for this period.")
    nrow(df) == 0 && return @htl("<p><em>$(empty_msg)</em></p>")
    return render_table2(df)
end


# Send Email
opt = SendOptions(
    isSSL=true,
    username=sender,
    passwd=passwd,
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

        small {
            font-size: 10px;
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

            <p><h2>Expense Detail(終端支出/收入):</h2></p>
            <p>$(render_section(select(expense_thisweek, Not(:email))))</p>

            <p><h2>Transfer Detail:</h2></p>
            <p>$(render_section(df2_thisweek_display))</p>

            <p><h2>Net Expense of This $(arg4.interval):</h2></p>
            <p>$(render_section(net_expense_thisweek))</p>

            <p><h2>Net Transfer of Everything:</h2></p>
            <p>$(render_section(net_transfer_by_item_thisweek))</p>

            <p><h2>Net Flow of This $(arg4.interval):</h2></p>
            <p><small>(Flow = Expense + Transfer)</small></p>
            <p>$(render_section(net_overall_thisweek))</p>

            <p><h2>Net Flow of All Time:</h2></p>

            <p>$(render_section(net_overall))</p>

        </p>

    </body>
</html>
""")

if isempty(recipients)
    println("\n⚠️  No recipients found. Skipping email dispatch.")
else
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
    println("\n✅ Email sent to $(length(recipients)) recipient(s).")
end
