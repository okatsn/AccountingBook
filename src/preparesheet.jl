function preparesheet(df0)
    @chain df0 begin
        select("時間戳記" => ByRow(convertdatetime) => :time,
            "電子郵件地址" => :email,
            "項目" => :item,
            "支出或收入" => :inout,
            "從誰的口袋" => :whosaccount,
            "金額" => :amount,
            "備註" => :memo,)
    end
end


function emptyprefix!(df0a, expr)
    f = s -> (split(s, "_") |> last)
    rename!(f, df0a; cols=Cols(expr))
end

emptyprefix!(expr) = df -> emptyprefix!(df, expr)

function preparesheet2(df0a)
    dfas = DataFrame[]
    for direction in ["IN", "OUT"]
        expr = Regex("$(direction)_")
        dftmp = select(df0a, :timestr, :email, Cols(expr)) |> emptyprefix!(expr)
        insertcols!(dftmp, :direction => direction)
        push!(dfas, dftmp)
    end

    dfa = reduce(vcat, dfas)

    select(dfa, :timestr => ByRow(convertdatetime) => :time, Not(:timestr))

end
