module PyCallUtils

using SparseArrays, Serialization, Random
using PyCall, Requires, BSON
using PyCall: jlWrapIteratorType, pyjlwrap_type!, pyincref_, pyjlwrap_iternext, pyjlwrap_new

export @imports, @from, pytypename, pymodulename, pymat

macro imports(lib, as, abbrev)
    esc(:($abbrev = pyimport($(string(lib)))))
end

macro imports(lib)
    exs = []
    if isa(lib, Expr) && lib.head == :tuple
        for arg in lib.args
            var, mdl = arg, string(arg)
            push!(exs, :($var = pyimport($mdl)))
        end
    elseif isa(lib, Expr) && lib.head == :.
        var, mdl = gensym(lib.args[2].value), string(lib)
        mdl = replace(mdl, r"[\(\)]" => "")
        push!(exs, :($var = pyimport($mdl)))
    else
        var, mdl = lib, string(lib)
        push!(exs, :($var = pyimport($mdl)))
    end
    esc(Expr(:block, exs...))
end

macro from(lib, imports, fs)
    fs = isa(fs, Expr) ? fs.args : [fs]
    mdl = replace(string(lib), r"[\(\)]" => "")
    exs = [:($f = pyimport($mdl).$(string(f))) for f in fs]
    esc(Expr(:block, exs...))
end

PyCall.PyObject(x::Colon) = pybuiltin("slice")(nothing, nothing, nothing)

Base.getindex(o::PyObject, s) = o.__getitem__(s)
Base.getindex(o::PyObject, is...) = getindex(o, is)
Base.setindex!(o::PyObject, v, s) = o.__setitem__(s, v)
Base.setindex!(o::PyObject, v, is...) = setindex!(o, v, is)

Base.getindex(o::PyObject, s::Union{Symbol, AbstractString}) = invoke(getindex, Tuple{PyObject, Any}, o, s)
Base.setindex!(o::PyObject, v, s::Union{Symbol, AbstractString}) = invoke(setindex!, Tuple{PyObject, Any, Any}, o, v, s)

Base.getindex(o::PyObject, i::Integer) = invoke(getindex, Tuple{PyObject, Any}, o, i)
Base.getindex(o::PyObject, i1::Integer, i2::Integer) = getindex(o, (i1, i2))
Base.getindex(o::PyObject, is::Integer...) = getindex(o, is)
Base.setindex!(o::PyObject, v, i::Integer) = invoke(setindex!, Tuple{PyObject, Any, Any}, o, v, i)
Base.setindex!(o::PyObject, v, i1::Integer, i2::Integer) = setindex!(o, (i1, i2), v)
Base.setindex!(o::PyObject, v, is::Integer...) = setindex!(o, is, v)

function PyCall.jlwrap_iterator(o::Any)
    if jlWrapIteratorType.tp_name == C_NULL # lazily initialize
        pyjlwrap_type!(jlWrapIteratorType, "PyCall.jlwrap_iterator") do t
            t.tp_iter = @cfunction(pyincref_, PyPtr, (PyPtr,)) # new reference to same object
            t.tp_iternext = @cfunction(pyjlwrap_iternext, PyPtr, (PyPtr,))
        end
    end
    iter_result = iterate(o)
    return pyjlwrap_new(jlWrapIteratorType, (o, Ref{Union{Nothing,typeof(iter_result)}}(iter_result)))
end

function PyCall.PyObject(S::SparseMatrixCSC)
    @from scipy.sparse imports csc_matrix
    csc_matrix((S.nzval, S.rowval .- 1, S.colptr .- 1), shape = size(S))
end

function Base.convert(::Type{SparseMatrixCSC}, o::PyObject)
    o = o.tocsc()
    SparseMatrixCSC(o.shape..., o.indptr .+ 1, o.indices .+ 1, o.data)
end

function Base.:∘(f::PyObject, g::PyObject)
    sf, sg, sh = ntuple(i -> randstring(['a':'z'; 'A':'Z'], 24), 3)
py"""
$$sf = $f; $$sg = $g; $$sh = lambda *args, **kwargs: $$sf($$sg(*args, **kwargs))
"""
    h = py"$$sh"
end

pytypename(obj) = obj.__class__.__name__
pymodulename(obj) = obj.__class__.__module__

pymat(x::AbstractArray) = PyReverseDims(reshape(x, size(x, 1), :))
pymat(x::PyObject) = pytypename(x) == "DataFrame" ? x."values" : x

function BSON.lower(x::PyObject)
    io = IOBuffer()
    serialize(io, x)
    BSON.BSONDict(:tag => "pyobject", :data => take!(io))
end

@init BSON.tags[:pyobject] = d -> deserialize(IOBuffer(d[:data]))

end # module
