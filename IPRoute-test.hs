module Main where
import IPRoute

main = do 
    numberedInterfaces <- getNumberedInterfaces
    print ("numberedInterfaces",numberedInterfaces)
    interfaces <- getAllInterfaces
    print ("interfaces",interfaces)
    physicalInterfaces <- getPhysicalInterfaces
    print ("physicalInterfaces",physicalInterfaces)
    unnumberedInterfaces <- getUnnumberedInterfaces
    print ("unnumberedInterfaces",unnumberedInterfaces)
