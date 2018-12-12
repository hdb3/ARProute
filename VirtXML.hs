module Main where
--import System.Environment(getArgs)
import Text.XML.Light
import Data.Maybe
import qualified Data.ByteString


main = do
    c <- Data.ByteString.getContents
    let g = head $ onlyElems $ parseXML c
        pDirect = ( "direct" == ) . fromJust . findAttr ( QName "type" Nothing Nothing )
        directInterfaces = filter pDirect $ findElements ( QName "interface" Nothing Nothing ) $ fromJust $ findElement ( QName "devices" Nothing Nothing ) g
        direct = head directInterfaces
        mac = fromJust . findAttr ( QName "address" Nothing Nothing ) . fromJust . findElement ( QName "mac" Nothing Nothing )
        name = fromJust . findAttr ( QName "name" Nothing Nothing ) . fromJust . findElement ( QName "alias" Nothing Nothing )
        source = fromJust . findAttr ( QName "dev" Nothing Nothing ) . fromJust . findElement ( QName "source" Nothing Nothing )
    print (mac direct , name direct , source direct)
