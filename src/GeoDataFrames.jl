module GeoDataFrames

    import ArchGDAL; const AG = ArchGDAL
    import DataFrames, DataStreams #, SQLQuery

    function geodataframe(layer::AG.FeatureLayer)
        DataStreams.Data.stream!(AG.Source(layer), DataFrames.DataFrame)
    end

    function read(filename::AbstractString; layer::Int=0)
        AG.registerdrivers() do
            AG.read(filename) do dataset
                geodataframe(AG.getlayer(dataset, layer))
            end
        end
    end

    function read(
            filename::AbstractString,
            query::AbstractString;
            dialect::String = "SQLite",
            layer::Int=0
        )
        AG.registerdrivers() do
            AG.read(filename) do dataset
                AG.executesql(dataset, query, dialect=dialect) do results
                    geodataframe(results)
                end
            end
        end
    end
end
