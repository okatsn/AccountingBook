abstract type TableSource end
struct GoogleFormTimeTagTW end

function convertdatetime(dtstr::AbstractString, ::GoogleFormTimeTagTW)

    return @chain dtstr begin
        replace("上午" => "AM")
        replace("下午" => "PM")
        DateTime(dateformat"y/m/d p H:M:S")
    end
end

convertdatetime(dtstr) = convertdatetime(dtstr, GoogleFormTimeTagTW())
