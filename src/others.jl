# These are repo-specific functions.

numinout(str) = Dict("支出" => -1, "收入" => 1)[str]
getmatch(expr, str) = getproperty(match(expr, str), :match)

getaccountname(s) = getmatch(r"[\u4e00-\u9fff]+", s) # matches only chinese character

abstract type ScriptArgument end

@kwdef struct Arg4 <: ScriptArgument
    subject::String = "兩豬家記帳本摘要"
    interval
end
