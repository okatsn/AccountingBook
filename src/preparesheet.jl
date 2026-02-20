"""Empty expense DataFrame with the correct output schema."""
_empty_expense() = DataFrame(
    time=DateTime[], email=String[], item=String[], inout=String[],
    whosaccount=String[], amount=Float64[], unit=String[], memo=String[]
)

"""Empty transfer DataFrame with the correct output schema."""
_empty_transfer() = DataFrame(
    time=DateTime[], email=String[], whosaccount=String[], pooltype=String[],
    item=String[], amount=Float64[], unit=String[], memo=String[], inout=String[]
)

function preparesheet(df0)
    if ncol(df0) == 0 || nrow(df0) == 0
        @warn "preparesheet: input DataFrame is empty, returning empty expense table"
        return _empty_expense()
    end
    @chain df0 begin
        select("時間戳記" => ByRow(convertdatetime) => :time,
            "電子郵件地址" => :email,
            "項目" => :item,
            "支出或收入" => :inout,
            "從誰的口袋" => :whosaccount,
            "金額" => :amount,
            "幣別" => :unit,
            "備註" => :memo,)
    end
end


function emptyprefix!(df0a, expr)
    f = s -> (split(s, "_") |> last)
    rename!(f, df0a; cols=Cols(expr))
end

emptyprefix!(expr) = df -> emptyprefix!(df, expr)

function preparesheet2(df0a)
    if ncol(df0a) == 0 || nrow(df0a) == 0
        @warn "preparesheet2: input DataFrame is empty, returning empty transfer table"
        return _empty_transfer()
    end
    @chain df0a begin
        # trasform(Cols(r"^(IN|OUT)_") => ByRow():in_or_out)
        rename!("時間戳記" => :timestr,
            "電子郵件地址" => :email,
        )
    end

    dfas = DataFrame[]
    for direction in ["IN", "OUT"]
        expr = Regex("$(direction)_")
        dftmp = select(df0a, :timestr, :email, Cols(expr)) |> emptyprefix!(expr)
        rename!(dftmp,
            "誰" => :whosaccount,
            "類別" => :pooltype,
            "項目" => :item,
            "值" => :amount,
            "單位" => :unit,
            "備註" => :memo,)
        insertcols!(dftmp, :inout => direction)

        push!(dfas, dftmp)
    end

    dfa = reduce(vcat, dfas)

    select(dfa, :timestr => ByRow(convertdatetime) => :time, Not(:timestr))

end
