using GeoDataFrames, DataFrames, ArchGDAL
using Base.Test

const testdatadir = dirname(@__FILE__)

REPO_URL = "https://github.com/yeesian/ArchGDALDatasets/blob/master/"

remotefiles = [
    "data/point.geojson"
]

for f in remotefiles
    # create the directories if they don't exist
    currdir = dirname(f)
    isdir(currdir) || mkpath(currdir)
    # download the file
    currfile = joinpath(testdatadir, f)
    isfile(currfile) || download(REPO_URL*f*"?raw=true", currfile)
end

df = GeoDataFrames.read("data/point.geojson")
@test DataFrames.nrow(df) == 4
@test df[:pointname] == ["point-a", "point-b", "a", "b"]
@test df[:FID] == [2.0, 3.0, 0.0, 3.0]
@test ArchGDAL.toWKT.(df[:geometry0]) == [
    "POINT (100 0)",
    "POINT (100.2785 0.0893)",
    "POINT (100 0)",
    "POINT (100.2785 0.0893)"
]

for f in remotefiles
    currfile = joinpath(testdatadir, f)
    isfile(currfile) && rm(currfile)
end
