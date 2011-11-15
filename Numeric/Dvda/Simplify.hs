-- Simplify.hs

{-# OPTIONS_GHC -Wall #-}

module Numeric.Dvda.Simplify( pruneZeros
                            , pruneZerosOnce
                            , fastSimplify
                            , removeTimesOne
                            ) where

import Numeric.Dvda.Expr.Expr
import Numeric.Dvda.Expr.Op2Type
import Numeric.Dvda.Expr.ElemwiseType
import Numeric.Dvda.Expr.SourceType

fastSimplify :: Num a => Expr a -> Expr a
fastSimplify = removeTimesOne . pruneZeros

-- only need to be called once
removeTimesOne :: Expr a -> Expr a
removeTimesOne (Op2 Mul (Source (I 1)) x) = removeTimesOne x
removeTimesOne (Op2 Mul x (Source (I 1))) = removeTimesOne x
removeTimesOne (Op2 asm x y) = Op2 asm (removeTimesOne x) (removeTimesOne y)
removeTimesOne (Elemwise ewo x) = Elemwise ewo (removeTimesOne x)
removeTimesOne src@(Source _) = src

pruneZeros :: (Show a, Eq a, Num a) => Expr a -> Expr a
pruneZeros x 
  | x == xPruned = x
  | otherwise    = pruneZeros xPruned
  where
    xPruned = pruneZerosOnce x

pruneZerosOnce :: (Show a, Eq a, Num a) => Expr a -> Expr a
pruneZerosOnce (Op2 op2Type x y) = op2PruneZeros op2Type x y
pruneZerosOnce (Elemwise elemwiseType x) = elemwisePruneZeros elemwiseType x
pruneZerosOnce (Source x) = (Source x)

-- elemwise prune zeros
elemwisePruneZeros :: Num a => ElemwiseType -> Expr a -> Expr a
elemwisePruneZeros Abs (Source Zero) = Source Zero
elemwisePruneZeros Signum (Source Zero) = Source Zero
elemwisePruneZeros Neg (Source Zero) = Source Zero
elemwisePruneZeros Inv (Source Zero) = error "divide by zero in elemwisePruneZeros Inv"
elemwisePruneZeros ewt x = Elemwise ewt $ pruneZeros x

-- op2 prune zeros
op2PruneZeros :: Num a => Op2Type -> Expr a -> Expr a -> Expr a
op2PruneZeros Mul (Source Zero) _ = Source Zero
op2PruneZeros Mul _ (Source Zero) = Source Zero
op2PruneZeros Mul x y = Op2 Mul (pruneZeros x) (pruneZeros y)

op2PruneZeros Add (Source Zero) (Source Zero) = Source Zero
op2PruneZeros Add (Source Zero) y = pruneZeros y
op2PruneZeros Add x (Source Zero) = pruneZeros x
op2PruneZeros Add x y = Op2 Add (pruneZeros x) (pruneZeros y)

op2PruneZeros Pow x y = Op2 Pow x y

op2PruneZeros LogBase x y = Op2 LogBase x y
