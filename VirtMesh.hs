module VirtMesh where
{-
  This preserves more complex code which utilises the domain XML
  and explict interface NAC addresses.  In the context of this application
  (simple virtual topology build and destroy), the XML capability is redundant.
  This source file is reatined in case the need for it emerges in future.
-}

import System.Process
import VirtXML

link :: String -> String -> String
link h1 h2 = let h1h2 = h1 ++ "-" ++ h2
                 h2h1 = h2 ++ "-" ++ h1
                 cmdVeth   = "ip link add dev " ++ h1h2 ++ " type veth peer name " ++ h2h1
                 cmdVirsh h veth = "virsh attach-interface " ++ h ++ " direct " ++ veth ++ " --target=macvtap --model virtio" 
             in unlines [cmdVeth, cmdVirsh h1 h1h2, cmdVirsh h2 h2h1]

unlink :: (String, String) -> (String, String) -> String
unlink (h1,mac1) (h2,mac2) =
     let cmdVeth = "ip link del dev " ++ h1 ++ "-" ++ h2
         cmdVirsh h mac = "virsh detach-interface " ++ h ++ " direct " ++ mac
     in unlines [cmdVirsh h1 mac1,cmdVirsh h2 mac2,cmdVeth]

getDomainXML :: String -> IO String
getDomainXML domain = readProcess "virsh" ["dumpxml" , domain] ""

getDomainDirectInterfaceData :: String -> IO (Maybe (String, String, String))
getDomainDirectInterfaceData domain = do
    xml <- getDomainXML domain
    return $ getDirectInterfaceData xml
