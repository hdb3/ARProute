module Main where
import VirtXML

main = do
    c <- getContents
    putStrLn $ getNetworkInterfaceMAC c
