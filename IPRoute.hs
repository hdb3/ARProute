module IPRoute where
import System.Process
import Data.List(sortOn,(\\))
import Data.Ord(comparing)
import Data.IP
import qualified Data.Maybe
import Util

getARPTable :: IO [(String,[IPv4])]
getARPTable = do
    rawNeighbours <- readProcess "ip" ["neigh"] ""
    let parseNeighbours s = if "lladdr" == (parts !! 3) then Just (parts !! 2, read $ head parts :: IPv4) else Nothing where
            parts = words s
        neighbours = Data.Maybe.mapMaybe parseNeighbours ( lines rawNeighbours )
        table = aggregatePairs fst neighbours
    return table

getNumberedInterfaces :: IO [String]
getNumberedInterfaces = fmap (map  ( head . words ) . lines ) $ readProcess "ip" ["-4" , "-br" , "addr"] "" 

getAllInterfaces :: IO [String]
getAllInterfaces = fmap (map  ( head . words ) . lines ) $ readProcess "ip" ["-br" , "link"] "" 

getPhysicalInterfaces :: IO [String]
getPhysicalInterfaces = do
    let sections = map words . breakOn '\\'
    -- break up the interface details into word level nested array
    interfaceDetails <- fmap ( map sections . lines) $ readProcess "ip" ["-d" , "-o" , "link"] ""
    -- filter: 1) on number of 'lines' on an interface detail - simple interfaces don't additional lines to specify the sub-type such as bridge / macvtab / tun / etc
    --         2) to remove the loopback interface and any other odd ones other than real ethernet...
    -- then finally trim down the output to just field #2 line 1 which is the interface name (lots else available e.g. MAC, ifindex, state, but it is not needed so for simplicity just do this only)
    -- and finally finally, remove the trailing ':' from the filed name
    return $ fmap (  init . ( !! 1) . head ) $ filter (( "link/ether" == ) . head . ( !! 1 ) ) $ filter ( (3 > ) . length ) interfaceDetails

getUnnumberedInterfaces :: IO [String]
getUnnumberedInterfaces = do 
    physical <- getPhysicalInterfaces
    numbered <- getNumberedInterfaces
    return $ physical \\ numbered
