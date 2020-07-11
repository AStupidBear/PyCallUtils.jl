# Extensions to PyCall.jl

[![Build Status](https://travis-ci.com/AStupidBear/PyCallUtils.jl.svg?branch=master)](https://travis-ci.com/AStupidBear/PyCallUtils.jl)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/AStupidBear/PyCallUtils.jl?svg=true)](https://ci.appveyor.com/project/AStupidBear/PyCallUtils-jl)
[![Coverage](https://codecov.io/gh/AStupidBear/PyCallUtils.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/AStupidBear/PyCallUtils.jl)

## Installation

```julia
using Pkg
pkg"add PyCallUtils"
```

## Usage

```julia
using PyCall, PyCallUtils
```

### Import modules and functions from python elegantly

```julia
@imports numpy as np
@from datetime imports datetime
```

### Transfer SparseMatrixCSC to/from scipy

```julia
using SparseArrays
x = sprand(100, 100, 0.5)
@assert convert(SparseMatrixCSC, PyObject(x)) == x
```

### Serialize/Deserialize python object to [BSON.jl](https://github.com/MikeInnes/BSON.jl)

```julia
using BSON
BSON.@save "test.bson" x = np.sin
```

### Make getindex/setindex! behave exactly like in python

```julia
@imports pandas as pd
df = pd.DataFrame(Dict(:name => ["a", "b"], :age => [27, 30]))
@assert df.loc[1, "age"] == 30
sr = pd.Series([3, 5], index = [:a, :b])
@assert all(sr.iloc[0:1] == sr)
@assert all(sr.iloc[:] == sr)
```