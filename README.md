# sheaf-cohomology-data-fusion
Old project from 2016 consisting of a short Haskell script to compute cohomology of database joins for playing around with while working through http://www.drmichaelrobinson.net/sheaftutorial/.

### Example 1:

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
 [0,0,0,1, 0,0,1,0],   (i.e. PaysTax? == False in both)
 [0,1,0,0, 1,0,0,0]]   (i.e. Age is the same in both)
```
Indicating the observation that we can only be sure the join is correct for data which consists of only equal Age and PaysTax? variables, and no other data. It's worth noting that we can't take into account that some identifiers are unique, like the NIN.

### Example 2:
For a simple example of a system of sensors with non-trivial 1st cohomology, we consider some sensors which tell us the weather. Say the weather forecast tell either that it is sunny, or it's raining; a rooftop camera tells us whether or not it's sunny; a humidity sensor tells us whether or not it's raining. Suppose we infer from the fact that it's raining that it's cloudy. In this case, we will also infer this from the situation that it's raining literal cats and dogs, which is obviously impossible.

Encoding this, and calculating cohomology gives:
```haskell
:load sheaf_cohomology.lhs

let sCamera = ["Boolean"]
let sHumidity = ["Boolean"]
let sWeather = ["Boolean"]

let sRain = ["Boolean"]
let sSun = ["Boolean"]
let sCats = ["Boolean"]

let sClouds = ["Boolean"]

let dbFormat = [  [(sWeather,[]),(sHumidity,[]),(sCamera,[])],  [ (sSun,[(0, [[1,0],[0,1]]), (2, [[1,0],[0,1]])]) , (sRain,[(0, [[0,1],[1,0]]), (1, [[1,0],[0,1]])]), (sCats,[(1, [[0,0],[0,0]]), (2, [[0,0],[0,0]])]) ] , [(sClouds,[ (0,[[0,1],[1,0]]), (1,[[0,0],[0,1]]), (2,[[0,0],[0,1]]) ])]  ]

*Main> cohomology dbFormat 1
[[0,0,0,0,1,0],[0,0,0,0,0,1]]
*Main> cohomology dbFormat 0
[[1,0,0,1,1,0],[0,1,1,0,0,1]]
```

We immediately note that we have non-trivial 1st cohomology correspnding to it being either true or false that it's raining cats and dogs: it is consistent to assume that it is raining cats and dogs, but this assignment could not have come from any of the sensors.

The 0th cohomology is just telling us that it can't be raining and sunny at the same time.

