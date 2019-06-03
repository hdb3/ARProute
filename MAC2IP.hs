module Main where
import qualified Data.ByteString.Lazy as L
import System.Environment(getArgs)
import Data.Aeson(eitherDecode)
import System.Exit(die)
import LibvirtIP


main :: IO()
main = do
   --f <- L.getContents
   f <- L.readFile "/var/lib/libvirt/dnsmasq/virbr0.status"
   either (\s -> die $ "failed to parse input : " ++ s)
          processAddressRecords
          ( eitherDecode f) 

processAddressRecords :: [AddressRecord] -> IO ()
processAddressRecords recs = do
    args <- getArgs
    if null args then
        putStrLn $ unlines $ map show recs
    else do
        let mac = head args
            match = filter ( (mac ==) . macAddress) recs
        if null match then
            die $ "no match"
        else if 1 == length match then
            putStrLn $ show $ ipAddress $ head match
        else
            die $ "multiple matches found: " ++ unwords ( map show $ map ipAddress match )
