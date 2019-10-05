using PyCall, PyCallUtils, SparseArrays, BSON
using Test

@imports numpy as np
@test np == pyimport("numpy")

@from datetime imports datetime
@test datetime == pyimport("datetime").datetime

x = sprand(100, 100, 0.5)
@test convert(SparseMatrixCSC, PyObject(x)) == x

@test pytypename(np.sin) == "ufunc"
@test pymodulename(np.sin) == "numpy"

BSON.@save "test.bson" x = np.sin
BSON.@load "test.bson" x
@test x == np.sin
rm("test.bson")

@test (np.sin ∘ np.cos)(1f0) == np.sin(np.cos(1f0))