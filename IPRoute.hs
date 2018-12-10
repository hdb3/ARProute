module IPRoute where
import System.Process

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
    return $ fmap (  ( !! 1) . head ) $ filter (( "link/ether" == ) . head . ( !! 1 ) ) $ filter ( (3 > ) . length ) interfaceDetails

breakOn :: Eq a => a -> [a] -> [[a]]
breakOn c = breakOn' (c ==) where
    breakOn' _ [] = []
    breakOn' p a | p (head a) = breakOn' p (tail a)
                 | otherwise = takeWhile (not . p) a : breakOn' p (dropWhile (not . p) a)
