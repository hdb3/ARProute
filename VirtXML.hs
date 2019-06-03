module VirtXML where
import Text.XML.Light
import Data.Maybe

getDirectInterfaceData :: String -> Maybe (String, String, String)
getDirectInterfaceData c = if 0 < length directInterfaces then Just (mac direct , name direct , source direct) else Nothing where
    g = head $ onlyElems $ parseXML c
    pDirect = ( "direct" == ) . fromJust . findAttr ( QName "type" Nothing Nothing )
    directInterfaces = filter pDirect $ findElements ( QName "interface" Nothing Nothing ) $ fromJust $ findElement ( QName "devices" Nothing Nothing ) g
    direct = head directInterfaces
    mac = fromJust . findAttr ( QName "address" Nothing Nothing ) . fromJust . findElement ( QName "mac" Nothing Nothing )
    name = fromJust . findAttr ( QName "name" Nothing Nothing ) . fromJust . findElement ( QName "alias" Nothing Nothing )
    source = fromJust . findAttr ( QName "dev" Nothing Nothing ) . fromJust . findElement ( QName "source" Nothing Nothing )

getNetworkInterfaceMAC :: String -> String
getNetworkInterfaceMAC c = mac network
    where
    g = head $ onlyElems $ parseXML c
    pNetwork = ( "network" == ) . fromJust . findAttr ( QName "type" Nothing Nothing )
    network = head $ filter pNetwork $ findElements ( QName "interface" Nothing Nothing ) $ fromJust $ findElement ( QName "devices" Nothing Nothing ) g
    mac = fromJust . findAttr ( QName "address" Nothing Nothing ) . fromJust . findElement ( QName "mac" Nothing Nothing )
