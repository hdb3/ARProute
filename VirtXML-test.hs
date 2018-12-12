module Main where
import Text.XML.Light
import Data.Maybe
import qualified Data.ByteString
import VirtXML

main = do
    c <- getContents
    -- c <- Data.ByteString.getContents
    print $ getDirectInterfaceData c
