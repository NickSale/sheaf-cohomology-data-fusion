# sheaf-cohomology
Short Haskell script to compute cohomology of database joins

Usage example:
```haskell
let schemaA = ["String","Number","Boolean"]
let schemaB = ["Number","Boolean","Number"]
let schemaAB = ["String","Number","Boolean","Number"]
let dbFormat = [[(schemaA,[]), (schemaB,[])], [(schemaAB,[(0, restrictionMap schemaA schemaAB [(0,0),(1,1),(2,2)]), (1, restrictionMap schemaB schemaAB [(0,1),(1,2),(2,3)])])], []]

cohomology dbFormat 0
```
Outputs:
```
[[0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0],
 [0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0],
 [0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0]]
```
