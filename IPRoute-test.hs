module Main where
import IPRoute

main = do 
    interfaces <- getAllInterfaces
    print interfaces
    putStr $ unlines interfaces
