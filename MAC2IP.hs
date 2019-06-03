module Main where
import System.Environment(getArgs)
import System.Exit(die)
import LibvirtIP

main :: IO()
main = do
    args <- getArgs
    if null args then
        die "please provide a MAC address to search on"
    else do
        res <- mac2AddressRecords $ head args
        if null res then
            die "no match"
        else if 1 == length res then
            print (ipAddress $ head res)
        else
            die $ "multiple matches found: " ++ unwords ( map (show . ipAddress) res )
