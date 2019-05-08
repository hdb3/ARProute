module Main where
import IPRoute
import Control.Monad(mapM_)
import Control.Concurrent
import Data.List((\\),intersect)
import qualified Data.IP

setLoopback = True
main = do 
    numberedInterfaces <- getNumberedInterfaces
    print ("numberedInterfaces",numberedInterfaces)
    interfaces <- getAllInterfaces
    print ("interfaces",interfaces)
    let nonLoopbackInterfaces = filter ( "lo" /= ) interfaces
    physicalInterfaces <- getPhysicalInterfaces
    print ("physicalInterfaces",physicalInterfaces)
    unnumberedInterfaces <- getUnnumberedInterfaces
    print ("unnumberedInterfaces",unnumberedInterfaces)
    arpTable <- getARPTable_
    print ("arpTable",arpTable)

    arpAccept
    loopbackAddresses <- getLoopbackAddresses
    putStrLn $ "advertising " ++ show loopbackAddresses ++ " on " ++ show nonLoopbackInterfaces
    mapM_ ( processInterface loopbackAddresses) nonLoopbackInterfaces
    stall

    where
    stall = threadDelay 1000000 >> stall

processInterface :: [ Data.IP.IPv4 ] -> String -> IO ThreadId
processInterface addrs dev = do
    putStrLn $ "processInterface - loopback address advertised: " ++ show addrs
    interfaceUp dev
    forkIO (arpDaemon addrs dev)
    forkIO (processInterface' addrs dev)

    where

    arpDaemon :: [ Data.IP.IPv4 ] -> String -> IO ()
    arpDaemon addrs dev = do
        mapM_ (unsolicitedARP dev) addrs
        threadDelay 10000000
        arpDaemon addrs dev
    
    processInterface' addrs dev = do
        routes <- getDevARPTable dev
        devRoutes <- getDevRoutes dev
        let missingRoutes = routes \\ devRoutes
            matchingRoutes = routes `intersect` devRoutes
        putStrLn $ "processInterface: " ++ show dev ++ " - " ++ show routes
        mapM_ (addHostRoute dev) missingRoutes
        if null matchingRoutes then do
            putStrLn $ "no ARP routes installed on dev " ++ dev ++ " - retrying in 10 seconds"
            threadDelay 10000000
            processInterface' addrs dev
        else putStrLn $ "ARP routes installed on dev " ++ dev ++ " : " ++ show matchingRoutes
