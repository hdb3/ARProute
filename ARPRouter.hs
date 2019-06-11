module Main where
import IPRoute
import Control.Monad(mapM_,unless,when)
import Control.Concurrent
import Data.List((\\))
import qualified Data.IP
import System.IO(hFlush,stdout)
import System.Environment(getArgs)

seconds :: Int
seconds = 1000000

main :: IO ()
main = do

    args <- getArgs
    if "--help" `elem` args then do
        putStrLn "arprouter: options:"
        putStrLn "                   --lb : createLoopbackAddress"
        putStrLn "                   --uu : useUnnumberedInterfaces"
        putStrLn "                   --v  : verbose"
    else do
        let createLoopbackAddress = "--lb" `elem` args
            useUnnumberedInterfaces = "--uu" `elem` args
            verbose =  "--v" `elem` args

        putStrLn "arprouter starting"
        arpAccept
        hFlush stdout
        loopbackAddresses <- if createLoopbackAddress then makeLoopbackAddress else return []
        run useUnnumberedInterfaces createLoopbackAddress verbose loopbackAddresses []

        where
            makeLoopbackAddress = ( read . ("172.31.100." ++) . reverse . takeWhile ('.' /=) . reverse . show ) <$> getLocalAddress

run :: Bool -> Bool -> Bool -> [ Data.IP.IPv4 ] -> [ String ] -> IO()
run useUnnumberedInterfaces createLoopbackAddress verbose loopbackAddresses interfaces = do

    -- first get the current list of (active) nonLoopbackInterfaces
    currentInterfaces <- if useUnnumberedInterfaces then getUnnumberedInterfaces
                         else filter ( "lo" /= ) <$> getAllInterfaces
    when useUnnumberedInterfaces
         ( mapM_ interfaceUp currentInterfaces)

    let newInterfaces = currentInterfaces \\ interfaces

    unless (null newInterfaces)
        (putStrLn $ "added interfaces: " ++ unwords ( map show newInterfaces ))

    let removedInterfaces = interfaces \\ currentInterfaces
    unless (null removedInterfaces)
        (putStrLn $ "removed interfaces: " ++ unwords ( map show removedInterfaces ))

    -- now get the current list of addresses to advertise
    currentLoopbackAddresses <- if createLoopbackAddress then return loopbackAddresses else getLoopbackAddresses
    let newLoopbackAddresses = currentLoopbackAddresses \\ loopbackAddresses

    unless (null newLoopbackAddresses)
         (putStrLn $ "added loopback addresses: " ++ unwords ( map show newLoopbackAddresses ))

    let removedLoopbackAddresses = loopbackAddresses \\ currentLoopbackAddresses
    unless (null removedLoopbackAddresses)
         (putStrLn $ "removed loopback addresses: " ++ unwords ( map show removedLoopbackAddresses ))
    hFlush stdout

    -- now do the work
    sendARPs verbose interfaces currentLoopbackAddresses
    mapM_ (processDevice verbose) currentInterfaces
    hFlush stdout

    -- and pause before starting again
    threadDelay (10 * seconds)
    run useUnnumberedInterfaces createLoopbackAddress verbose currentLoopbackAddresses currentInterfaces

    where

    sendARPs :: Bool -> [ String ] -> [ Data.IP.IPv4 ] -> IO ()
    sendARPs verbose addresses devices = mapM_ (`sad` devices) addresses
        where
        sad device = mapM_ (unsolicitedARP' device)
        -- unsolicitedARP :: String -> IPv4 -> IO()
        unsolicitedARP' dev address = do
            when verbose ( putStrLn $ "send ARP on " ++ dev ++ " for " ++ show address )
            unsolicitedARP dev address

    -- note/TODO: does not remove addresses which have disappeared from ARP table, which is a problem....
    --            as, unlike ARP, these routes are persistent
    --            The solution is to either mark ou routes (who else is making /32s?), or record
    --            the routes we create and remove them when they go, which involves more state than we have here...
    --            solution is to make a thread for each device and pass state within
    processDevice :: Bool -> String -> IO ()
    processDevice verbose dev = do
        routes <- getDevARPTable dev
        devRoutes <- getDevRoutes dev
        -- exclude 'normal' ARP entries which lie within routable ranges of interface routes
        -- i.e. all of the 'normal' arp entries
        let isRoutable addr = any (Data.IP.isMatchedTo addr) devRoutes
            missingRoutes = filter (not . isRoutable ) routes
        --let missingRoutes = routes \\ devRoutes
        --putStrLn $ "processDevice: device " ++ show dev
        when verbose ( do
             putStrLn $ "processDevice: device \"" ++ dev ++ "\" ARP table [" ++ unwords (map show routes) ++ "]"
             putStrLn $ "processDevice: device \"" ++ dev ++ "\" route table [" ++ unwords (map show devRoutes) ++ "]"
             putStrLn $ "processDevice: device \"" ++ dev ++ "\" missing routes [" ++ unwords (map show missingRoutes) ++ "]")

        unless (null missingRoutes)
               ( do putStrLn $ "processDevice: " ++ show dev ++ " adding routes " ++ unwords (map show missingRoutes)
                    mapM_ (addHostRoute dev) missingRoutes)

{-
 -    Copyright 2019 Nicholas Hart
 -
 -       Licensed under the Apache License, Version 2.0
-}
