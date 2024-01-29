
thead(s, h) = @htl("<$h>$s") # Because you cannot interpolate html syntax (interpolated "<" will be "&lt;")

function render_row(row)
    @htl("""
<tr>$((thead(item, "td") for item in string.(values(row))))
""")
end

function render_table(df; caption=" ")
    @htl("""
    <table><caption><h3>$caption</h3></caption>
    <thead><tr>$((thead(col, "th") for col in string.(names(df))))<tbody>
    $((render_row(b) for b in eachrow(df)))</tbody></table>""")
end
