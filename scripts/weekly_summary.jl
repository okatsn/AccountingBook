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
    select(:whosaccount => ByRow(getaccountname) => "Account", :netflow => "Net Flow")
end


dfthis = @chain df begin
    filter(:time => (dt -> t1 > dt ≥ t0), _)
    transform(:memo => ByRow(x -> ifelse(ismissing(x), "", x)), [:inout, :amount] => ByRow((s, v) -> numinout(s) * v) => :difference; renamecols=false)
    select(Not(:inout, :amount))
    transform(:whosaccount => ByRow(getaccountname); renamecols=false)
end

dfthis_sum = @chain dfthis begin
    groupby(:whosaccount)
    combine(:difference => sum => "Net Difference")
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

subject = arg4.subject
from = "<$sender>"

msg0 = @htl("""
<p><strong>$subject</strong>：<br>

<p>$(render_table(dfthis))</p>

Summary of this $(arg4.interval):

<p>$(render_table(dfthis_sum))</p>

Overall Summary:

<p>$(render_table(summary))</p>

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
