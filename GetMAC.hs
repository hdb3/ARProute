module Main where
import VirtXML

main :: IO ()
main = do
    c <- getContents
    putStrLn $ getNetworkInterfaceMAC c
