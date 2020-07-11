using PyCall
using PyCallUtils
using SparseArrays
using BSON
using Test
using PyCall: python

@imports numpy as np
@test np == pyimport("numpy")

@from datetime imports datetime
@test datetime == pyimport("datetime").datetime

x = sprand(100, 100, 0.5)
if occursin("scipy", read(`$python -m pip list`, String))
    @test convert(SparseMatrixCSC, PyObject(x)) == x
end

@test pytypename(np.sin) == "ufunc"
@test pymodulename(np.sin) == "numpy"

BSON.@save "test.bson" x = np.sin
BSON.@load "test.bson" x
@test x == np.sin
rm("test.bson")

@test (np.sin ∘ np.cos)(1f0) == np.sin(np.cos(1f0))

@imports pandas as pd

df = pd.DataFrame(Dict(:name => ["a", "b"], :age => [27, 30]))
@test df.loc[1, "age"] == 30

sr = pd.Series([3, 5], index = [:a, :b])
@test sr.a == 3
@test sr["a"] == 3
@test sr.loc["a"] == 3
@test sr.b == 5
@test sr.iloc[0] == 3
@test sr.iloc[1] == 5
@test length(sr) == 2
@test sr.sum() == 8
@test all(sr.iloc[0:1] == sr)
@test all(sr.iloc[:] == sr)