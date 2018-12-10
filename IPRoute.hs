module IPRoute where
import System.Process
import Data.List(sortOn,(\\))
import Data.IP
import qualified Data.Maybe

getARPTable :: IO [(String,[IPv4])]
getARPTable = do
    rawNeighbours <- readProcess "ip" ["neigh"] ""
    let parseNeighbours s = if "lladdr" == (parts !! 3) then Just (parts !! 2, read $ head parts :: IPv4) else Nothing where
            parts = words s
        neighbours = Data.Maybe.mapMaybe parseNeighbours ( lines rawNeighbours )
        table = aggregate neighbours
    print neighbours
    print table
    return []

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

breakOn :: Eq a => a -> [a] -> [[a]]
breakOn c = breakOn' (c ==) where
    breakOn' _ [] = []
    breakOn' p a | p (head a) = breakOn' p (tail a)
                 | otherwise = takeWhile (not . p) a : breakOn' p (dropWhile (not . p) a)

aggregate :: Eq a => [(a,b)] -> [(a,[b])]
aggregate = agg0 . Data.List.sortOn fst where
    agg0 [] = []
    agg0 ((a,b):z) = agg [(a,[b])] z
    agg a [] = a
    agg ( (a,[bx]) : c ) ((a0,b0) : z ) | a == a0   = agg ( (a,[b0:bx]) : c ) z
                                        | otherwise = agg ( (a0,[b0]) : (a,[bx]) : c ) z 
