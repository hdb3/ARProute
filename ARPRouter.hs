module Main where
import IPRoute
import Control.Monad(mapM_,when,unless)
import Control.Concurrent
import Data.List((\\),intersect)
import qualified Data.IP

seconds = 1000000 :: Int

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
    run [] nonLoopbackInterfaces
    --loopbackAddresses <- getLoopbackAddresses
    --putStrLn $ "advertising " ++ show loopbackAddresses ++ " on " ++ show nonLoopbackInterfaces
    --mapM_ ( processInterface loopbackAddresses) nonLoopbackInterfaces
    --stall

    --where
    --stall = threadDelay (1000 * seconds) >> stall

run :: [ Data.IP.IPv4 ] -> [ String ] -> IO()
run loopbackAddresses interfaces = do

    -- first get the current list of addresses to advertise
    currentLoopbackAddresses <- getLoopbackAddresses
    let newLoopbackAddresses = currentLoopbackAddresses \\ newLoopbackAddresses
    unless (null newLoopbackAddresses)
         (putStrLn $ "added loopback addresses: " ++ unwords ( map show newLoopbackAddresses ))
    let removedLoopbackAddresses = currentLoopbackAddresses \\ loopbackAddresses
    unless (null removedLoopbackAddresses)
         (putStrLn $ "removed loopback addresses: " ++ unwords ( map show removedLoopbackAddresses ))

    -- now do the work
    sendARPs interfaces currentLoopbackAddresses
    mapM_ processDevice interfaces

    -- and pause before starting again
    threadDelay (10 * seconds)
    run currentLoopbackAddresses interfaces

    where

    sendARPs :: [ String ] -> [ Data.IP.IPv4 ] -> IO ()
    sendARPs addresses devices = mapM_ (`sad` devices) addresses
        where
        sad device = mapM_ (unsolicitedARP device)

    -- note/TODO: does not remove addresses which have disappeared from ARP table, which is a problem....
    --            as, unlike ARP, these routes are persistent
    --            The solution is to either mark ou routes (who else is making /32s?), or record
    --            the routes we create and remove them when they go, which involves more state than we have here...
    --            solution is to make a thread for each device and pass state within
    processDevice :: String -> IO ()    
    processDevice dev = do
        routes <- getDevARPTable dev
        devRoutes <- getDevRoutes dev
        let missingRoutes = routes \\ devRoutes
            matchingRoutes = routes `intersect` devRoutes
        unless (null missingRoutes)
               ( do putStrLn $ "processDevice: " ++ show dev ++ " adding routes " ++ unwords (map show missingRoutes)
                    mapM_ (addHostRoute dev) missingRoutes)

processInterface :: [ Data.IP.IPv4 ] -> String -> IO ThreadId
processInterface addrs dev = do
    putStrLn $ "processInterface - loopback address advertised: " ++ show addrs
    interfaceUp dev
    forkIO (arpDaemon addrs dev)
    forkIO (processInterface' dev)

    where

    arpDaemon :: [ Data.IP.IPv4 ] -> String -> IO ()
    arpDaemon addrs dev = do
        mapM_ (unsolicitedARP dev) addrs
        threadDelay (10 * seconds)
        arpDaemon addrs dev

processInterface' :: String -> IO ()    
processInterface' dev = do
    routes <- getDevARPTable dev
    devRoutes <- getDevRoutes dev
    let missingRoutes = routes \\ devRoutes
        matchingRoutes = routes `intersect` devRoutes
    putStrLn $ "processInterface: " ++ show dev ++ " - " ++ show routes
    mapM_ (addHostRoute dev) missingRoutes
    if null matchingRoutes then do
        putStrLn $ "no ARP routes installed on dev " ++ dev ++ " - retrying in 10 seconds"
        threadDelay (10 * seconds)
        processInterface' dev
    else putStrLn $ "ARP routes installed on dev " ++ dev ++ " : " ++ show matchingRoutes
