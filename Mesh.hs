module Main where
--import VirtMesh
import System.Environment(getArgs)
import Control.Monad(mapM)
import Data.List(zip,repeat)

main = do
    hx <- getArgs
    if (null hx) then do
        putStrLn $ "Mesh: generate visrh commands to build a network mesh for libvirt systems"
        putStrLn $ "      provide two or more VM names as input parameters...."
    else do
        let makeMesh l = [(i,j) | i<-l, j<-l, i<j]
        let 
            links = map (\(i,j) -> link i j) (makeMesh hx)
            unlinks = map (\(i,j) -> unlink i j) (makeMesh hx)
        putStrLn $ unlines links
        putStrLn $ unlines unlinks

    where
    
    
    link h1 h2 = let h1h2 = h1 ++ "-" ++ h2
                     h2h1 = h2 ++ "-" ++ h1
                     cmdVeth   = "ip link add dev " ++ h1h2 ++ " type veth peer name " ++ h2h1
                     cmdVirsh h veth = "virsh attach-interface " ++ h ++ " direct " ++ veth ++ " --target=macvtap --model virtio"
                 in unlines $ [cmdVeth, cmdVirsh h1 h1h2, cmdVirsh h2 h2h1]
    
    unlink h1 h2 =
         let cmdVeth = "ip link del dev " ++ h1 ++ "-" ++ h2
             cmdVirsh h = "virsh detach-interface " ++ h ++ " direct "
         in unlines $ [cmdVirsh h1 ,cmdVirsh h2 ,cmdVeth]
    
