isbufferpool(x) = x == "緩存區"

"""
Process table's input/output category and absolute values to signed values
"""
book_svalue(df) = @chain df begin
    calc_svalue
    select(Not(:inout, :amount))
end

"""
Process table of expense to sum by account and unit.
"""
summary_expense(df) = @chain df begin
    calc_svalue
    groupby([:whosaccount, :unit])
    combine(:svalue => sum => :netflow)
    sort([:whosaccount, :unit])
end

"""
Process the table of transfer by item and unit (and of course by account)
"""
summary_transfer_all(df2) = @chain df2 begin
    calc_svalue
    groupby([:whosaccount, :item, :pooltype, :unit]) # For one's summary (net flow) by item by unit.
    combine(:svalue => sum => :svalue)
    # describe
    sort([:whosaccount, :pooltype, :item, :unit])
end


"""
With the output of `summary_transfer_all`, get the summary for only cashflow.
"""
subset_transfer_cash(net_transfer_by_item) = @chain net_transfer_by_item begin
    subset(:pooltype => ByRow(isbufferpool))
    groupby([:whosaccount, :unit])
    combine(:svalue => sum => :netflow)
end

"""
Create a new column of `svalue`.
"""
calc_svalue(df) = transform(df, Cols(:inout, :amount) => ByRow((s, v) -> numinout(s) * v) => :svalue)
