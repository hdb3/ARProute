{-# LANGUAGE RecordWildCards, OverloadedStrings #-}
module LibvirtIP where
import Data.IP
import Data.Aeson
import Data.Aeson.IP

data AddressRecord = AddressRecord { ipAddress :: IPv4
--data AddressRecord = AddressRecord { ipAddress :: String
                                   , macAddress :: String
                                   , expiryTime :: Int
                                   } deriving Show

{-
instance FromJSON AddressRecord where
  parseJSON = withObject "AddressRecord" $ \o -> do
    --ipAddress <- read $ unpack $ o .: "ip-address"
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
