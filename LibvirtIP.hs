{-# LANGUAGE RecordWildCards, OverloadedStrings #-}
module LibvirtIP where
import qualified Data.ByteString.Lazy as L
import Data.IP
import Data.Aeson
import System.Exit(die)
import Data.Aeson.IP

data AddressRecord = AddressRecord { ipAddress :: IPv4
                                   , macAddress :: String
                                   , expiryTime :: Int
                                   } deriving Show

{-
instance FromJSON AddressRecord where
  parseJSON = withObject "AddressRecord" $ \o -> do
    ipAddress   <- o .: "ip-address"
    macAddress  <- o .: "mac-address"
    expiryTime  <- o .: "expiry-time"
    return AddressRecord{..}

-}

instance FromJSON AddressRecord where
    parseJSON = withObject "AddressRecord" $ \v -> AddressRecord
        <$> v .: "ip-address"
        <*> v .: "mac-address"
        <*> v .: "expiry-time"

mac2AddressRecords :: String -> IO [AddressRecord]
mac2AddressRecords mac = do
   f <- L.readFile "/var/lib/libvirt/dnsmasq/virbr0.status"
   either (\s -> die $ "failed to parse input : " ++ s)
          ( \recs -> return $ filter ( (mac ==) . macAddress) recs )
          ( eitherDecode f) 
