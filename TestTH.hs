{-# LANGUAGE TemplateHaskell #-}

import Language.Haskell.TH
import Language.Haskell.TH.Syntax

main :: IO ()
main = putStrLn str

str :: String
str = $(runIO (readFile "TestTH.hs") >>= \s -> runIO (putStr s) >> [|s|])
