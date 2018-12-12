module VirtMesh where
import System.Process
-- import System.Environment
import VirtXML

link h1 h2 = let cmdVeth   = "ip link add dev " ++ h1 ++ " type veth peer name " ++ h2
                 cmdVirsh1 = "virsh attach-interface " ++ h1 ++ " direct " ++ h1 ++ "-" ++ h2 ++ " --target=macvtap --model virtio" 
                 cmdVirsh2 = "virsh attach-interface " ++ h2 ++ " direct " ++ h2 ++ "-" ++ h1 ++ " --target=macvtap --model virtio" 
             in unlines $ [cmdVeth,cmdVirsh1,cmdVirsh1]

unlink (h1,mac1) (h2,mac2) =
     let cmdVeth = "ip link del dev " ++ h1
         cmdVirsh h mac = "virsh detach-interface " ++ h ++ " direct " ++ mac
     in unlines $ [cmdVirsh h1 mac1,cmdVirsh h2 mac2,cmdVeth]

getDomainXML domain = readProcess "virsh" ["dumpxml" , domain] ""

getDomainDirectInterfaceData :: String -> IO (Maybe (String, String, String))
getDomainDirectInterfaceData domain = do
    xml <- getDomainXML domain
    return $ getDirectInterfaceData xml
