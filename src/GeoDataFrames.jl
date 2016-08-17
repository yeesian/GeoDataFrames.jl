module GeoDataFrames
    
    isdefined(Base, :__precompile__) && __precompile__()

    import ArchGDAL; const AG = ArchGDAL
    using DataFrames, Plots, SQLQuery

    type Geometry
        ptr::AG.Geometry

        function Geometry(ptr::AG.Geometry)
            geom = new(AG.unsafe_clone(ptr))
            finalizer(geom, g -> AG.destroy(g.ptr))
            geom
        end
    end
    Base.show(io::IO, geom::Geometry) = print(io, "$(geom.ptr)")

    function shape(poly::Geometry) # only for Polygons
        ring = AG.getgeom(poly.ptr, 0) # get outermost ring
        npoints = AG.npoint(ring)
        Shape([(AG.getx(ring, i-1), AG.gety(ring, i-1)) for i in 1:npoints])
    end

    function plot(df::DataFrame; plt = Plots.plot(bg = :black),
                  geom::Symbol=:none, label::Symbol=:none, kwargs...)
        geometries = (geom == :none) ? df[:geometry0] : df[geom]
        for (i,geom) in enumerate(geometries)
            DataFrames.isna(geom) && continue
            if label != :none
                plot!(plt, shape(geom); label=df[i,label], kwargs...)
            else
                plot!(plt, shape(geom); kwargs...)
            end
        end
        plt
    end

    function geodataframe(layer::AG.FeatureLayer)
        layergeomtype = AG.getgeomtype(layer)
        featuredefn = AG.getlayerdefn(layer)
        ngeom = AG.ngeomfield(featuredefn); nfld = AG.nfield(featuredefn)
        nfeat = AG.nfeature(layer, true)
        colnames = Symbol[
                    Symbol[Symbol("geometry$(i-1)") for i in 1:ngeom];
                    Symbol[Symbol(AG.getname(AG.getfielddefn(featuredefn, j-1)))
                           for j in 1:nfld]
                   ]
        df = DataFrame(vcat(fill(Geometry,ngeom),fill(Any,nfld)),colnames,nfeat)
        for (i,f) in enumerate(layer)
            for j in 1:ngeom
                g = AG.getgeomfield(f, j-1)
                df[i,j] = (g == C_NULL) ? NA : Geometry(g)
            end
            for j in 1:nfld
                value = AG.getfield(f, j-1)
                df[i,j+ngeom] = (value == nothing) ? NA : value
            end
        end
        df
    end

    function read(filename::AbstractString; layer::Int=0)
        AG.registerdrivers() do
            AG.read(filename) do dataset
                geodataframe(AG.getlayer(dataset, layer))
            end
        end
    end

    function read(filename::AbstractString, query::AbstractString; layer::Int=0)
        AG.registerdrivers() do
            AG.read(filename) do dataset
                AG.executesql(dataset, query, dialect="SQLite") do results
                    geodataframe(results)
                end
            end
        end
    end

    macro query(args...)
        AG.registerdrivers() do
            filename = string(args[1].args[2])
            AG.read(filename) do dataset
                args[1].args[2] = Symbol(AG.getname(AG.getlayer(dataset, 0)))
                sqlcommand = SQLQuery.translatesql(SQLQuery._sqlquery(args))
                AG.executesql(dataset, sqlcommand, dialect="SQLite") do results
                    geodataframe(results)
                end
            end
       end
   end
end
