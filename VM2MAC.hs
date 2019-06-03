{-# LANGUAGE OverloadedStrings #-}
module Main where
import System.Process
import System.Environment(getArgs)
import System.Exit
import VirtXML


main :: IO()
main = do
    args <- getArgs
    if 1 /= length args then
        die "please ask just one question!"
    else do
 
    xml <- readProcess "virsh" ["dumpxml" , head args] ""
    let mac = getNetworkInterfaceMAC xml
    putStrLn $ "MAC found: " ++ mac
