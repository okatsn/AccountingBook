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
