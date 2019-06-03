module Main where
import IPRoute
import Control.Monad(mapM_)

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
    let unnumberedARP = map (`lookup` arpTable) unnumberedInterfaces
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

processUnnumberedInterface lb dev = do
    interfaceUp dev
    putStrLn $ "processUnnumberedInterface - loopback address advertised: " ++ show lb
    unsolicitedARP dev lb
    routes <- getDevARPTable dev
    putStrLn $ "processUnnumberedInterface: " ++ show dev ++ " - " ++ show routes
    mapM_ (addHostRoute dev) routes

makeLoopbackAddress ip = read lb where
    ip' = show ip
    host = reverse $ takeWhile ('.' /=) $ reverse ip'
    lb = "172.16.100." ++ host
