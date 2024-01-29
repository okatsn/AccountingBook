# These are repo-specific functions.

numinout(str) = Dict("支出" => -1, "收入" => 1)[str]
getmatch(expr, str) = getproperty(match(expr, str), :match)
