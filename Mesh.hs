module Main where
import System.Environment(getArgs)
import qualified Data.List
import Control.Monad(when,unless)
import System.Process(callCommand)
import System.Exit(die)

useBrctl = True
main = do
    args <- getArgs
    let (opts,hx) = Data.List.partition (Data.List.isPrefixOf "--") args
    when ( null hx )
         (die "Mesh: generate virsh commands to build a network mesh for libvirt systems\n\
              \      provide two or more VM names as input parameters...." )

    let (link,unlink) = if useBrctl then (brLink,brUnlink) else (vethLink,vethUnlink)

    let makeMesh l = [(i,j) | i<-l, j<-l, i<j]
        links = map (uncurry link) (makeMesh hx)
        unlinks = map (uncurry unlink) (makeMesh hx)

    if "--create" `elem` opts then do
        putStrLn $ unlines links
        unless ("--dryrun" `elem` opts)
               ( callCommand $ unlines links )
    else if "--delete" `elem` opts then do
        putStrLn $ unlines unlinks
        unless ("--dryrun" `elem` opts)
               ( callCommand $ unlines unlinks )
    else do
        putStrLn "** create script **"
        putStrLn $ unlines links
        putStrLn "** delete script **"
        putStrLn $ unlines unlinks

    where
    
    brLink h1 h2 = let brName = "br" ++ h1 ++ h2
                       cmdAddBr   = "sudo brctl addbr " ++ brName
                       cmdSetUpBr   = "sudo ip link set up dev " ++ brName
                       cmdVirsh h = "sudo virsh attach-interface " ++ h ++ " bridge " ++ brName
                 in unlines [cmdAddBr , cmdSetUpBr, cmdVirsh h1 , cmdVirsh h2 ]
    
    vethLink h1 h2 = let h1h2 = h1 ++ "-" ++ h2
                         h2h1 = h2 ++ "-" ++ h1
                         cmdVeth   = "sudo ip link add dev " ++ h1h2 ++ " type veth peer name " ++ h2h1
                         cmdVirsh h veth = "sudo virsh attach-interface " ++ h ++ " direct " ++ veth ++ " --target=macvtap --model virtio"
                 in unlines [cmdVeth, cmdVirsh h1 h1h2, cmdVirsh h2 h2h1]
    
    vethUnlink h1 h2 = let cmdVeth = "sudo ip link del dev " ++ h1 ++ "-" ++ h2
                           cmdVirsh h = "sudo virsh detach-interface " ++ h ++ " direct"
         in unlines [cmdVirsh h1 ,cmdVirsh h2 ,cmdVeth]
    
    brUnlink h1 h2 = let brName = "br" ++ h1 ++ h2
                         cmdBrctl   = "sudo brctl delbr " ++ brName
                         cmdVirsh h = "sudo virsh detach-interface " ++ h ++ " bridge"
         in unlines [cmdVirsh h1 ,cmdVirsh h2 ,cmdBrctl]
