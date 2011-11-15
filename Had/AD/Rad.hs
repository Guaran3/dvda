-- Rad.hs

{-# OPTIONS_GHC -Wall #-}

module Had.AD.Rad( getSensitivities
                 , radExample
                 ) where

import Had.Expr
import Had.Expr.ExprToGraph
import Had.Simplify

getSensitivities :: Num a => Expr a -> Expr a -> [(Expr a, Expr a)]
getSensitivities primal@(Source (Sym _)) sens = [(primal, sens)]
getSensitivities (Source _) _ = []
getSensitivities (Op2 Mul x y) sens = (getSensitivities x (sens*y))++(getSensitivities y (sens*x))
getSensitivities (Op2 Add x y) sens = (getSensitivities x sens)++(getSensitivities y sens)
getSensitivities (Op2 Sub x y) sens = (getSensitivities x sens)++(getSensitivities y sens)


rad :: Num a => Expr a -> [Expr a] -> [Expr a]
rad expr args = map getXSens args
  where
    senss = getSensitivities expr 1
    getXSens x = fastSimplify $ sum $ map snd $ filter (\y -> x == fst y) senss

  
radExample :: IO ()
radExample = do
  let exampleExpr :: Expr Integer
      --      exampleExpr = abs(y*34) + 5 + x*y
      exampleExpr = z + x*y
        where
          x = sym "x"
          y = sym "y"
          z = sym "z"
  let args = map sym ["x", "y", "z"]

  print exampleExpr
  print $ rad exampleExpr args
  
  previewGraph $ exprToGraph exampleExpr
  previewGraph $ exprsToGraph (exampleExpr:(rad exampleExpr args))