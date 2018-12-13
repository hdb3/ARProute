module VirtMesh where
import System.Process
-- import System.Environment
import VirtXML

link h1 h2 = let h1h2 = h1 ++ "-" ++ h2
                 h2h1 = h2 ++ "-" ++ h1
                 cmdVeth   = "ip link add dev " ++ h1h2 ++ " type veth peer name " ++ h2h1
                 cmdVirsh h veth = "virsh attach-interface " ++ h ++ " direct " ++ veth ++ " --target=macvtap --model virtio" 
             in unlines $ [cmdVeth, cmdVirsh h1 h1h2, cmdVirsh h2 h2h1]

unlink (h1,mac1) (h2,mac2) =
     let cmdVeth = "ip link del dev " ++ h1 ++ "-" ++ h2
         cmdVirsh h mac = "virsh detach-interface " ++ h ++ " direct " ++ mac
     in unlines $ [cmdVirsh h1 mac1,cmdVirsh h2 mac2,cmdVeth]

getDomainXML domain = readProcess "virsh" ["dumpxml" , domain] ""

getDomainDirectInterfaceData :: String -> IO (Maybe (String, String, String))
getDomainDirectInterfaceData domain = do
    xml <- getDomainXML domain
    return $ getDirectInterfaceData xml
