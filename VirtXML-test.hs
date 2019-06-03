module Main where
import VirtXML

main :: IO ()
main = do
    c <- getContents
    print $ getDirectInterfaceData c
