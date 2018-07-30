We will do everything in terms of rationals to avoid loss of accuracy

> import Data.Ratio

> import Data.List (find)
> import Data.List (findIndex)
> import Data.List (transpose)
> import Data.Maybe (fromJust)

-----------------------------------
Some basic linear algebra definitions and operations

> multVec :: [[Rational]] -> [Rational] -> [Rational]
> multVec m v = [sum (zipWith (*) v r) | r <- m]

> multMat :: [[Rational]] -> [[Rational]] -> [[Rational]]
> multMat m1 m2 = [[sum (zipWith (*) r c) | c <- (transpose m2)] | r <- m1]

> isZero :: [Rational] -> Bool
> isZero = foldr ((&&).(==0)) True

> dotp v u = sum (zipWith (*) v u)

> subV = zipWith (-)

> scaleV a = map (*a)

> scaleMat = map.scaleV

> identity :: Int -> [[Rational]]
> identity n = [[if r == c then 1 else 0 | c <- [1..n]] | r <- [1..n]]

> zeroMat :: Int -> Int -> [[Rational]]
> zeroMat rs cs = [[0 | c <- [1..cs]] | r <- [1..rs]]

removes any component of v in the direction of u:

> removeComponent :: [Rational] -> [Rational] -> [Rational]
> removeComponent u v = subV v (scaleV ((dotp u v) / (dotp u u)) u)

-----------------------------------
Row-reduction is the powerhouse algorithm for computing bases for the kernel and image of
the linear transformation T(v) = Av associated with a matrix A
(based off code from rosettacode.org, altered to use an augmented matrix):

> rref :: [[Rational]] -> [[Rational]]
> rref = fst.rrefWithId

> rrefWithId :: [[Rational]] -> ([[Rational]],[[Rational]])
> rrefWithId m = f (m,identity rows) 0 [0 .. rows - 1]
>   where rows = length m
>         cols = length (head m)

We pass about both the matrix and the identity as they get transformed:

>         f (m,idm) _ [] = (m,idm)
>         f (m,idm) lead (r : rs)
>             | indices == Nothing = (m,idm)
>             | otherwise          = f (m',idm') (lead' + 1) rs

Find the leading coefficient:

>           where
>             indices = find p l
>             p (col, row) = m !! row !! col /= 0
>             l = [(col, row) |
>                  col <- [lead .. cols - 1],
>                  row <- [r .. rows - 1]
>                 ]
>             Just (lead', i) = indices

We divide the row of the matrix and the row of the identity by the same leading coeff:

>             newRow = map (/ m !! i !! lead') (m !! i)
>             newIdRow = map (/ m !! i !! lead') (idm !! i)

We subtract the row from each other row to make the rest of the column of the leading coeff zeros:

>             (m',idm') = unzip (zipWith g [0..] (zip (replace r newRow (replace i (m !! r) m ))
>                               (replace r newIdRow (replace i (idm !! r) idm)) ) )
>             g n (row,idRow)
>                 | n == r    = (row,idRow)
>                 | otherwise = (zipWith h newRow row, zipWith h newIdRow idRow)
>               where h = subtract . (* row !! lead')

Replaces an element of a list l with a new value v at the given index i:

>             replace i v l = a ++ v : b
>               where (a, _ : b) = splitAt i l

-----------------------------------
We may now compute more useful information

Compute a basis for the image of the linear transformation associated with a matrix:

> image :: [[Rational]] -> [[Rational]]
> image m = leadCols (rref m)
>   where
>     tm = transpose m
>     leadCols [] = []
>     leadCols (r:rs)
>        | l == Nothing	= leadCols rs
>        | otherwise	= (tm !! (fromJust l)) : leadCols rs
>      where
>        l = findIndex (/= 0) r

Compute a basis for the kernel of the linear transformation associated with a matrix:

> kernel :: [[Rational]] -> [[Rational]]
> kernel = zeroRows.rrefWithId.transpose
>   where
>     zeroRows ([],[]) = []
>     zeroRows ((r:rs),(ir:irs))
>         | isZero r	= ir : zeroRows (rs,irs)
>         | otherwise	= zeroRows (rs,irs)

Find a basis for a space from a spanning set:

> removeDependentVs :: [[Rational]] -> [[Rational]]
> removeDependentVs vs = leadCols $ rref $ transpose vs
>   where
>     leadCols [] = []
>     leadCols (u:us)
>         | lead == Nothing	= leadCols us
>         | otherwise		= (vs !! (fromJust lead)) : leadCols us
>       where
>         lead = findIndex (/=0) u

Find a basis for the quotient of the space spanned by vs by the space spanned by us
(essentially finds the orthogonal complement of span{us} within span{vs}):

> quotient :: [[Rational]] -> [[Rational]] -> [[Rational]]
> quotient vs us = removeDependentVs $ map (foldr ((.).removeComponent) id us) vs

-----------------------------------
Block matrix composition

> vertCompose :: [[Rational]] -> [[Rational]] -> [[Rational]]
> vertCompose = (++)

> horizCompose :: [[Rational]] -> [[Rational]] -> [[Rational]]
> horizCompose = zipWith (++)

> composeBlockMat :: [[[[Rational]]]] -> [[Rational]]
> composeBlockMat = concat.(map (foldr1 horizCompose))

-----------------------------------
Instances of types in the databases are represented by vector spaces of varying dimensions
To aid in simplifying functions all the types used have been numbered according to the following

> typeName :: Int -> [Char]
> typeName 0 = "Number"
> typeName 1 = "Boolean"
> typeName 2 = "String"
> typeName n = error ("Type " ++ show n ++ " hasn't been implemented.")

> typeNum :: [Char] -> Int
> typeNum "Number" = 0
> typeNum "Boolean" = 1
> typeNum "String" = 2
> typeNum x = error ("Type " ++ x ++ " hasn't been implemented.")

Categoric variable values are stored (and hence ordered) explicitly to give meaning to the dimensions
of the vector spaces used to represent those types

> booleans = ["False", "True"]
> strings = ["Hello", "Alice", "Bob", "Charlie"]

typeDim gives the dimension of the vector space used to represent a single instance of a given type

> typeDim :: Int -> Int
> typeDim 0 = 1
> typeDim 1 = length booleans
> typeDim 2 = length strings
> typeDim n = error ("Type " ++ show n ++ " hasn't been implemented.")

restrictionMap takes an order list of type names for a section and the section its being
restricted to and then a list of pairs indicating when a dimension of the first section should be
represented by a dimension of the second (these must be of the same type)

> restrictionMap :: [[Char]] -> [[Char]] -> [(Int,Int)] -> [[Rational]]
> restrictionMap ts1 ts2 ps = composeBlockMat [[mapping (ts1!!i1) (ts2!!i2) ((i1,i2) `elem` ps) | i1 <- [0..n1-1]] | i2 <- [0..n2-1]]
>   where
>     n1 = length ts1
>     n2 = length ts2
>     mapping t1 t2 p
>         | p 		= identity d1
>         | otherwise 	= zeroMat d2 d1
>       where
>         d1 = typeDim $ typeNum t1
>         d2 = typeDim $ typeNum t2

coboundary takes a list containing our database layout and returns a function which, given a dimension, returns the
corresponding coboundary map. The database layout list has the following format:

[[(table schema, [])], [(table schema, [(source, restriction map)])], [(table schema, [(source, restriction map)])], ..., []]
|____0-simplices____|  |_______________1-simplices_________________|  |_______________2-simplices_________________|       end

where for a k-simplex, the sources are the (k+1) elements of the previous list that form the boundary of the simplex.

> type DatabaseLayout = [ [( [[Char]] , [( Int , [[Rational]] )] )] ]

> schemaDim :: [[Char]] -> Int
> schemaDim = sum.(map (typeDim.typeNum))

> coboundary :: DatabaseLayout -> Int -> [[Rational]]
> coboundary _ (-1) = [[]]
> coboundary dataLayout n = (formCoboundaries (zip dataLayout [0..]) ++ repeat []) !! n
>   where
>     formCoboundaries [] = [[]]
>     formCoboundaries (([],k):[]) = [zeroMat dm1 dm1]
>       where
>         dm1 = sum $ map (schemaDim.fst) $ dataLayout !! (k-1)
>     formCoboundaries ((kSs,k):rest)
>         | k == 0	= formCoboundaries rest
>         | otherwise	= composeBlockMat [[mapping (zip (snd (kSs !! r)) [0..])
>                                           c
>                                           (schemaDim (fst (km1Ss !! c)))
>                                           (schemaDim (fst (kSs !! r)))
>                                          | c <- [0..nKm1 - 1]] | r <- [0..nK - 1]] : formCoboundaries rest
>       where
>         km1Ss = dataLayout !! (k-1)
>         nKm1 = length km1Ss
>         nK = length kSs
>         mapping [] _ dKm1 dK = zeroMat dK dKm1
>         mapping (((source,map),i) : srcs) src dKm1 dK
>             | source == src 	= scaleMat ((-1)^i) map
>             | otherwise		= mapping srcs src dKm1 dK

Finally, we can do cohomology, rounding our basis vectors to be made up of integers

> cohomology :: DatabaseLayout -> Int -> [[Int]]
> cohomology dl k = map (map round) $ quotient (kernel (coBound k)) (image (coBound (k-1)))
>   where
>     coBound = coboundary dl