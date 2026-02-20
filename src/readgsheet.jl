function readgsheet(url)
    io = IOBuffer()
    @suppress google_download(url, io)
    data = take!(io)
    if isempty(data)
        @warn "readgsheet: received empty response" url
        return DataFrame()
    end
    rawscore = CSV.read(data, DataFrame; buffer_in_memory=true)
    return rawscore
end
