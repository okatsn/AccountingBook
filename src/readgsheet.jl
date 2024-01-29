function readgsheet(url)
    io = IOBuffer()
    @suppress google_download(url, io)
    rawscore = CSV.read(take!(io), DataFrame; buffer_in_memory=true)
    return rawscore
end
