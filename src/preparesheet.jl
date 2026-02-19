function preparesheet(df0)
    @chain df0 begin
        select("時間戳記" => ByRow(convertdatetime) => :time,
            "電子郵件地址" => :email,
            "項目" => :item,
            "支出或收入" => :inout,
            "從誰的口袋" => :whosaccount,
            "金額" => :amount,
            "幣別" => :unit_currency,
            "備註" => :memo,)
    end
end


function emptyprefix!(df0a, expr)
    f = s -> (split(s, "_") |> last)
    rename!(f, df0a; cols=Cols(expr))
end

emptyprefix!(expr) = df -> emptyprefix!(df, expr)

function preparesheet2(df0a)
    @chain df0a begin
        # trasform(Cols(r"^(IN|OUT)_") => ByRow():in_or_out)
        rename!("時間戳記" => :timestr,
            "電子郵件地址" => :email,
            "誰" => :whosaccount,
            "資產類別" => :assettype,
            "項目" => :item,
            "數量" => :quantity,
            "單價" => :unit_price,
            "單價單位" => :unit_unit,
            "備註" => :memo,
        )
    end

    dfas = DataFrame[]
    for direction in ["IN", "OUT"]
        expr = Regex("$(direction)_")
        dftmp = select(df0a, :timestr, :email, Cols(expr)) |> emptyprefix!(expr)
        insertcols!(dftmp, :inout => direction)
        push!(dfas, dftmp)
    end

    dfa = reduce(vcat, dfas)

    select(dfa, :timestr => ByRow(convertdatetime) => :time, Not(:timestr))

end
