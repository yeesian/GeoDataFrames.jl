struct Layer{T}
    geom::T
    options::Dict{Symbol,Any}
end

Layer(geom; kwargs...) = Layer(geom, Dict{Symbol,Any}(kwargs))

function chloropleth{T}(
        geom::T,
        cvalues::Vector{<:Real},
        cgradient;
        kwargs...
    )
    options = Dict{Symbol,Any}(kwargs)
    minv = minimum(cvalues); rangev = maximum(cvalues) - minv
    options[:color] = if rangev < 1e-4
        cgradient[cvalues[1]]
    else
        [cgradient[minv + (v-minv)/rangev] for v in cvalues]
    end
    Layer{T}(geom, options)
end

function chloropleth(
        df::DataFrames.DataFrame,
        column::Symbol,
        cgradient;
        geometry::Symbol = :geometry0,
        kwargs...
    )
    chloropleth(df[geometry], df[column], cgradient; kwargs...)
end

RecipesBase.@recipe function f(layer::Layer)
    _get(opt::Any, i::Int) = opt
    _get(opt::Vector, i::Int) = opt[i]
    
    aspect_ratio --> get(layer.options, :aspect_ratio, 1)
    legend --> get(layer.options, :legend, :false)
    grid --> get(layer.options, :grid, false)
    haskey(layer.options, :framestyle) && (framestyle --> layer.options[:framestyle])
    haskey(layer.options, :ticks) && (ticks --> layer.options[:ticks])

    for (i,g) in enumerate(layer.geom)
        RecipesBase.@series begin
            gtype = GeoInterface.geotype(g)
            haskey(layer.options, :label) && (label := _get(layer.options[:label], i))
            if gtype == :Point || gtype == :MultiPoint
                seriestype := :scatter
                haskey(layer.options, :alpha) && (markeralpha := _get(layer.options[:alpha], i))
                haskey(layer.options, :color) && (markercolor := _get(layer.options[:color], i))
                haskey(layer.options, :shape) && (markershape := _get(layer.options[:shape], i))
                haskey(layer.options, :size)  && (markersize  := _get(layer.options[:size], i))
                haskey(layer.options, :strokealpha) && (markerstrokealpha  := _get(layer.options[:strokealpha],i))
                haskey(layer.options, :strokecolor) && (markerstrokecolor  := _get(layer.options[:strokecolor],i))
                haskey(layer.options, :strokestyle) && (markerstrokestyle  := _get(layer.options[:strokestyle],i))
                haskey(layer.options, :strokewidth)  && (markerstrokewidth := _get(layer.options[:strokewidth],i))
            elseif gtype == :LineString || gtype == :MultiLineString
                seriestype := :path
                haskey(layer.options, :arrow) && (arrow     := _get(layer.options[:arrow], i))
                haskey(layer.options, :alpha) && (linealpha := _get(layer.options[:alpha], i))
                haskey(layer.options, :color) && (linecolor := _get(layer.options[:color], i))
                haskey(layer.options, :style) && (linestyle := _get(layer.options[:style], i))
                haskey(layer.options, :width) && (linewidth := _get(layer.options[:width], i))
            elseif gtype == :Polygon || gtype == :MultiPolygon
                seriestype := :shape
                haskey(layer.options, :alpha) && (fillalpha := _get(layer.options[:alpha], i))
                haskey(layer.options, :color) && (fillcolor := _get(layer.options[:color], i))
            else
                warn("unknown geometry type: $gtype")
            end
            GeoInterface.shapecoords(g)
        end
    end
end
