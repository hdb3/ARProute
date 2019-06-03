module Main where
import qualified Data.ByteString.Lazy as L
import System.Environment(getArgs)
import Data.Aeson(eitherDecode)
import System.Exit(die)
import LibvirtIP

{-
mac2AddressRecords :: String -> IO [AddressRecord]
mac2AddressRecords mac = do
   f <- L.readFile "/var/lib/libvirt/dnsmasq/virbr0.status"
   either (\s -> die $ "failed to parse input : " ++ s)
          ( \recs -> return $ filter ( (mac ==) . macAddress) recs )
          ( eitherDecode f) 
-}

main :: IO()
main = do
    args <- getArgs
    if null args then
        die "please provide a MAC address to search on"
    else do
        res <- mac2AddressRecords $ head args
        if null res then
            die $ "no match"
        else if 1 == length res then
            putStrLn $ show $ ipAddress $ head res
        else
            die $ "multiple matches found: " ++ unwords ( map show $ map ipAddress res )
