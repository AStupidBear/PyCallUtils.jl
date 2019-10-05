# Utility functions for [PyCall.jl](https://github.com/JuliaPy/PyCall.jl)

## Installation

```julia
julia>]
pkg> add https://github.com/AStupidBear/PyCallUtils.jl.git
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

```
using SparseArrays
x = sprand(100, 100, 0.5)
@assert convert(SparseMatrixCSC, PyObject(x)) == x
```

### Serialize/Deserialize python object to [BSON.jl](https://github.com/MikeInnes/BSON.jl)
```
using BSON
BSON.@save "test.bson" x = np.sin
```

### Make getindex/setindex! behave exactly like in python
```
@imports pandas as pd
df = pd.DataFrame(Dict(:name => ["a", "b"], :age => [27, 30]))
@assert df.loc[1, "age"] == 30
sr = pd.Series([3, 5], index = [:a, :b])
@assert all(sr.iloc[0:1] == sr)
@assert all(sr.iloc[:] == sr)
```