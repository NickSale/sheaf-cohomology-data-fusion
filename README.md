# sheaf-cohomology
Short Haskell script to compute cohomology of database joins

## Example 1:

Say we want to know a basis for global sections (i.e. globally consistent data) in the following straightforward database inner join:

db1 . select(Name, Age, PaysTax?) . innerJoin( db2 . select(Age, PaysTax?, National Insurance Number), on=(Age, PaysTax?) )

We might do:
```haskell
:load sheaf_cohomology.lhs
let schemaA = ["String","Number","Boolean"]
let schemaB = ["Number","Boolean","Number"]
let schemaAB = ["String","Number","Boolean","Number"]
let dbFormat = [[(schemaA,[]), (schemaB,[])], [(schemaAB,[(0, restrictionMap schemaA schemaAB [(0,0),(1,1),(2,2)]), (1, restrictionMap schemaB schemaAB [(0,1),(1,2),(2,3)])])], []]

cohomology dbFormat 0
```
Which outputs (minus the interpretation):
```
[[0,0,1,0, 0,1,0,0],   (i.e. PaysTax? == True in both )
 [0,0,0,1, 0,0,1,0],   (i.e. PaysTax> == False in both)
 [0,1,0,0, 1,0,0,0]]   (i.e. Age is the same in both)
```
Indicating the trivial observation that we can only be sure the join is correct for data which consists of only equal Age and PaysTax? variables, and no other data.

## Example 2:
<todo> add example with non-trivial 1st cohomology </todo>
