module Main where
{-
  This is the old version of ARPRouter which targets only
  unnumbered interfaces, such as is found in more complex virtualised topologies.
  The new version has some bug fixes and improvements which would be applicable here.
  The right thing to do will be to add in the features in this version which have been removed from thw new one,
  bu leave also the capability to use in more general environments
-}
import IPRoute
import Control.Monad(mapM_)
import Control.Concurrent
import Data.List((\\),intersect)

setLoopback = True
main = do 
    numberedInterfaces <- getNumberedInterfaces
    print ("numberedInterfaces",numberedInterfaces)
    interfaces <- getAllInterfaces
    print ("interfaces",interfaces)
    physicalInterfaces <- getPhysicalInterfaces
    print ("physicalInterfaces",physicalInterfaces)
    unnumberedInterfaces <- getUnnumberedInterfaces
    print ("unnumberedInterfaces",unnumberedInterfaces)
    arpTable <- getARPTable_
    print ("arpTable",arpTable)

    putStrLn "\nunnumbered interface ARP table\n  ------"
    let unnumberedARP = map (\dev -> lookup dev arpTable) unnumberedInterfaces
    print unnumberedARP
    arpAccept
    loopbackAddress <- getLoopbackAddress
    if setLoopback then do
        local <- getLocalAddress
        let lb = makeLoopbackAddress local
        putStrLn $ "using local address " ++ show local ++ "to generate loopback address"
        putStrLn $ "set loopback to " ++ show lb
        setLoopbackAddress lb
        mapM_ ( processUnnumberedInterface lb) unnumberedInterfaces
    else maybe (putStrLn "no loopback address found")
               ( \lb -> mapM_ ( processUnnumberedInterface lb) unnumberedInterfaces )
               loopbackAddress
    let stall = do threadDelay 1000000
                   stall
    stall

processUnnumberedInterface lb dev = do
    putStrLn $ "processUnnumberedInterface - loopback address advertised: " ++ show lb
    interfaceUp dev
    forkIO (arpDaemon lb dev)
    forkIO (processUnnumberedInterface' lb dev)

arpDaemon lb dev = do
    unsolicitedARP dev lb
    threadDelay 10000000
    arpDaemon lb dev

processUnnumberedInterface' lb dev = do
    routes <- getDevARPTable dev
    devRoutes <- getDevRoutes dev
    let missingRoutes = routes \\ devRoutes
        matchingRoutes = routes `intersect` devRoutes
    putStrLn $ "processUnnumberedInterface: " ++ show dev ++ " - " ++ show routes
    mapM_ (addHostRoute dev) missingRoutes
    if null matchingRoutes then do
        putStrLn $ "no ARP routes installed on dev " ++ dev ++ " - retrying in 10 seconds"
        threadDelay 10000000
        processUnnumberedInterface' lb dev
    else putStrLn $ "ARP routes installed on dev " ++ dev ++ " : " ++ show matchingRoutes

makeLoopbackAddress ip = read lb where
    ip' = show ip
    host = reverse $ takeWhile ('.' /=) $ reverse ip'
    lb = "172.16.100." ++ host
