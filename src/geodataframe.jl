"""
Constructs a `DataFrames.DataFrame` from `layer`.

Where each `field` is a column, and each `feature` is a row. The name of
the geometry column (if any) defaults to `geometry0`.
"""
function geodataframe(layer::AG.FeatureLayer)
    sink = DataStreams.Data.stream!(AG.Source(layer), DataFrames.DataFrame)
    DataStreams.Data.close!(sink)
end

"""
Returns the dataset in `filename` as a `DataFrames.DataFrame`.

For details, see http://www.gdal.org/ogr_sql.html.

### Arguments
* `filename`: the dataset to run the query on
* (optional) `query`: the SQL SELECT query to be run on the dataset/layer

### Keyword Arguments
* `layer::Int` (default=`0`): the layer in the dataset to retrieve
* `dialect::String` (default=`SQLite`): the SQL dialect for `query` (if any)
"""
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
