module GeoDataFrames

    import ArchGDAL; const AG = ArchGDAL
    import DataFrames, DataStreams, GeoInterface, RecipesBase

    include("geodataframe.jl")
    include("plotrecipe.jl")
end
