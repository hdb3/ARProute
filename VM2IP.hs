{-# LANGUAGE OverloadedStrings #-}
module Main where
import System.Process
import System.Environment(getArgs)
import System.Exit
import VirtXML
import LibvirtIP

main :: IO()
main = do
    args <- getArgs
    if 1 /= length args then
        die "please ask just one question!"
    else do
        xml <- readProcess "virsh" ["dumpxml" , head args] ""
        let mac = getNetworkInterfaceMAC xml
        --putStrLn $ "MAC found: " ++ mac
        recs <- mac2AddressRecords mac
        if 1 /= length recs then
            die "fail"
        else
            print (ipAddress $ head recs)
