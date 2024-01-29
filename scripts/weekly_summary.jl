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

sheetid = ARGS[3]
sender = ARGS[1]

url = "https://docs.google.com/spreadsheets/d/$sheetid/edit?usp=sharing"
df0 = readgsheet(url)


t1 = now() + Hour(8) # we are at UTC+8
t0 = t1 - Week(1)

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
    transform(:inout => ByRow(numinout); renamecols=false)
    select(Not([:inout, :amount]), [:inout, :amount] => ByRow((s, v) -> s * v) => :flows)
    groupby(:whosaccount)
    combine(:flows => sum => :netflow)
    select(:whosaccount => ByRow(s -> getmatch(r"[\u4e00-\u9fff]+", s)) => "Account", :netflow => "Net Flow")
end

htmlsummary = render_table(summary)

htmltb = @chain df begin
    filter(:time => (dt -> t1 > dt ≥ t0), _)
    render_table
end

recipients = unique(df0[!, "電子郵件地址"])
# uniquewhos = unique(df[!, :whosaccount])


# """
# Convert "A" or "B" to readable nicknames.
# """
# convertfromAB(str) = Dict(getmatch.(r"[AB]", uniquewhos) .=> getmatch.(r"[\u4e00-\u9fff]+", uniquewhos))[str]





# Send Email
opt = SendOptions(
    isSSL=true,
    username=sender,
    passwd=ARGS[2],
)

url = "smtps://smtp.gmail.com:465"

subject = "兩豬家記帳本週摘要"
from = "<$sender>"

msg0 = @htl("""
<p><strong>$subject</strong>：<br>

Weekly summary:

<p>$htmltb</p>

Overall Summary:

<p>$htmlsummary</p>

</p>

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
