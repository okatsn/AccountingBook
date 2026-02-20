function timespanfilter(df, timepoint::DateTime; withshift=Day(5) + Hour(8), interval=Week(1))
    t1_week = floor(timepoint, Week) + withshift # we are at UTC+8
    t0_week = t1_week - interval

    # t0_year = floor(timepoint, Year) + Hour(8) # we are at UTC+8
    # t1_year = t0_year + Year(1)
    filter(:time => (dt -> t1_week > dt ≥ t0_week), df)
end


timespanfilter(timepoint; kwargs...) = df -> timespanfilter(df, timepoint; kwargs...)
