module Main where
import System.Environment
import Read

main :: IO Int
main = do
    args <- getArgs
    readArgs args
    