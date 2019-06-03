module Main where
import System.Environment(getArgs)

main = do
    hx <- getArgs
    if null hx then do
        putStrLn "Mesh: generate virsh commands to build a network mesh for libvirt systems"
        putStrLn "      provide two or more VM names as input parameters...."
    else do
        let makeMesh l = [(i,j) | i<-l, j<-l, i<j]
        let 
            links = map (uncurry unlink) (makeMesh hx)
            unlinks = map (uncurry unlink) (makeMesh hx)
        putStrLn $ unlines links
        putStrLn $ unlines unlinks

    where
    
    
    link h1 h2 = let h1h2 = h1 ++ "-" ++ h2
                     h2h1 = h2 ++ "-" ++ h1
                     cmdVeth   = "ip link add dev " ++ h1h2 ++ " type veth peer name " ++ h2h1
                     cmdVirsh h veth = "virsh attach-interface " ++ h ++ " direct " ++ veth ++ " --target=macvtap --model virtio"
                 in unlines [cmdVeth, cmdVirsh h1 h1h2, cmdVirsh h2 h2h1]
    
    unlink h1 h2 =
         let cmdVeth = "ip link del dev " ++ h1 ++ "-" ++ h2
             cmdVirsh h = "virsh detach-interface " ++ h ++ " direct "
         in unlines [cmdVirsh h1 ,cmdVirsh h2 ,cmdVeth]
    
