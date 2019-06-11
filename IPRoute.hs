{-# LANGUAGE OverloadedStrings #-}
module IPRoute where
import System.Process
import Data.List(intersect,(\\))
import Text.Read(readMaybe)
import Data.IP
import Data.Maybe(mapMaybe)
import Control.Monad(when,void)
import System.Exit
import Util

addHostRoute :: String -> IPv4 -> IO()
addHostRoute dev ip = do
    let route = show ip ++ "/32"
    putStrLn $ "ip route replace " ++ route ++ " dev " ++ dev
    void $ readProcess "ip" ["route" , "replace" , route , "dev" , dev ] ""


getARPTable :: IO [(String,IPv4)]
getARPTable = do
    rawNeighbours <- readProcess "ip" ["-4" , "neigh"] ""
    let parseNeighbours s = if "lladdr" == (parts !! 3) then Just (parts !! 2, read $ head parts :: IPv4) else Nothing where
            parts = words s
    return $ mapMaybe parseNeighbours ( lines rawNeighbours )

getDevRoutes :: String -> IO [AddrRange IPv4]
getDevRoutes dev = (mapMaybe ( readIPRouteRoute . head . words ) . lines ) <$> readProcess "ip" ["-4" , "-br" , "route", "show", "dev", dev] "" 
    where

    readIPRouteRoute :: String -> Maybe (AddrRange IPv4)
    readIPRouteRoute "default" = Just "0.0.0.0/0"
    readIPRouteRoute s | '/' `elem` s = fmap  (`makeAddrRange` 32)( readMaybe s )
                       | otherwise = readMaybe s

getDevARPTable :: String -> IO [IPv4]
getDevARPTable dev = do
    neighbours <- getARPTable
    return $ map snd $ filter ( (dev ==) . fst) neighbours

getARPTable_ :: IO [(String,[IPv4])]
getARPTable_ = do
    neighbours <- getARPTable
    return $ aggregatePairs fst neighbours

unsolicitedARP :: String -> IPv4 -> IO()
unsolicitedARP dev ip = void $ readProcess "arping" ["-A" , "-c" , "1" , "-I" , dev , "-s" , show ip , "0.0.0.0"] ""

interfaceUp :: String -> IO()
interfaceUp dev = void $ readProcess "ip" ["link" , "set" , "up" , "dev" , dev ] ""

arpAccept :: IO()
arpAccept = callCommand "echo -n 1 > /proc/sys/net/ipv4/conf/all/arp_accept"

getLocalAddress :: IO IPv4
getLocalAddress = do
    interfaces <- getPhysicalNumberedInterfaces
    getFirstAddress (head interfaces)

getFirstAddress :: String -> IO IPv4
getFirstAddress dev = do
    raw <- readProcess "ip" ["-4" , "-br" , "address" , "show" , "dev" , dev] ""
    return $ read $ takeWhile ('/' /=) $ words raw !! 2

setLoopbackAddress :: IPv4 -> IO ()
setLoopbackAddress ip = do
    (ec,out,err) <- readProcessWithExitCode "ip" ["-4" , "address" , "add" , show ip , "dev" , "lo"] ""
    when (ExitSuccess /= ec) (putStrLn $ "setLoopbackAddress - warning: " ++ show (ec,out,err))

getLoopbackAddress :: IO (Maybe IPv4)
getLoopbackAddress = do
    raw <- readProcess "ip" ["-4" , "-br" , "address" , "show" , "dev" , "lo"] ""
    let raw' = words raw
    return $ if 3 > length raw' then Nothing else Just (read $ takeWhile ('/' /=) $ raw' !! 3)  


getLoopbackAddresses :: IO [ IPv4 ]
getLoopbackAddresses = do
    -- first word is the interface name, second word is the interface state
    -- all others should be valid addresses with subnet length
    raw <- readProcess "ip" ["-4" , "-br" , "address" , "show" , "dev" , "lo"] ""
    return $ map ( fst . addrRangePair) $ filter slash32 $ map read $ drop 2 $ words raw
    where
    slash32 :: Addr a => AddrRange a -> Bool
    slash32 ar = (32 ==) $ snd $ addrRangePair ar

getNumberedInterfaces :: IO [String]
getNumberedInterfaces = (map  ( head . words ) . lines ) <$> readProcess "ip" ["-4" , "-br" , "addr"] "" 

-- NOTE: we assume that only 'UP' interfaces are wanted, which might not always be true...
getAllInterfaces :: IO [String]
getAllInterfaces = map ( takeWhile ('@' /=) . head . words ) . lines <$> readProcess "ip" ["-br" , "link", "show" , "up"] "" 

getPhysicalInterfaces :: Bool -> IO [String]
getPhysicalInterfaces up = do
    let sections = map words . breakOn '\\'
        ipLinkOptions = if up then ["-d" , "-o" , "link", "show" , "up"] else  ["-d" , "-o" , "link", "show"]
    -- break up the interface details into word level nested array
    interfaceDetails <- ( map sections . lines) <$> readProcess "ip" ipLinkOptions ""
    -- filter: 1) on number of 'lines' on an interface detail - simple interfaces don't additional lines to specify the sub-type such as bridge / macvtab / tun / etc
    --         2) to remove the loopback interface and any other odd ones other than real ethernet...
    -- then finally trim down the output to just field #2 line 1 which is the interface name (lots else available e.g. MAC, ifindex, state, but it is not needed so for simplicity just do this only)
    -- and finally finally, remove the trailing ':' from the filed name
    return $ fmap (  init . ( !! 1) . head ) $ filter (( "link/ether" == ) . head . ( !! 1 ) ) $ filter ( (3 > ) . length ) interfaceDetails

getUnnumberedInterfaces :: IO [String]
getUnnumberedInterfaces = do 
    physical <- getPhysicalInterfaces False -- include interfaces which are down
    numbered <- getNumberedInterfaces
    return $ physical \\ numbered

getPhysicalNumberedInterfaces :: IO [String]
getPhysicalNumberedInterfaces = do 
    physical <- getPhysicalInterfaces True -- only get interfaces which are 'UP'
    numbered <- getNumberedInterfaces
    return $ physical `intersect` numbered
