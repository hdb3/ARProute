module IPRoute where
import System.Process
--import Control.Monad(mapM_)
import Data.List(isPrefixOf)

getNumberedInterfaces :: IO [String]
getNumberedInterfaces = fmap (map  ( head . words ) . lines ) $ readProcess "ip" ["-4" , "-br" , "addr"] "" 

getAllInterfaces :: IO [String]
getAllInterfaces = fmap (map  ( head . words ) . lines ) $ readProcess "ip" ["-br" , "link"] "" 

getPhysicalInterfaces :: IO [String]
getPhysicalInterfaces = do
    let sections = (map words)  . breakOn '\\'
    interfaceDetails <- fmap ( map sections . lines) $ readProcess "ip" ["-d" , "-o" , "link"] ""
    let simpleInterfaces = filter ( (3 > ) . length ) interfaceDetails
        physicalInterfaces = filter (( isPrefixOf "link/ether" ) . head . ( !! 1 ) ) simpleInterfaces
    -- print simpleInterfaces
    -- return $ fmap (( !! 1) . head ) physicalInterfaces
    return $ fmap (  ( !! 1) . head ) $ filter (( isPrefixOf "link/ether" ) . head . ( !! 1 ) ) $ filter ( (3 > ) . length ) interfaceDetails
    -- return []

breakOn c s = breakOn' (c ==) s where
    breakOn' _ [] = []
    breakOn' p a | p (head a) = breakOn' p (tail a)
                 | otherwise = (takeWhile (not . p) a) : breakOn' p (dropWhile (not . p) a)
