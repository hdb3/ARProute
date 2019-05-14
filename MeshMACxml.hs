module Main where
{-
  This preserves more complex code which utilises the domain XML
  and explict interface NAC addresses.  In the context of this application
  (simple virtual topology build and destroy), the XML capability is redundant.
  This source file is reatined in case the need for it emerges in future.
-}
import VirtMesh
import System.Environment(getArgs)
import Control.Monad(mapM)
import Data.List(zip,repeat)
--import Data.Maybe(fromJust)

main = do
    hx <- getArgs
    hostMacs <- gethostMacs' hx 
    print hostMacs
    let makeMesh l = [(i,j) | i<-l, j<-l, i<j]
    let -- mesh = [(i,j) | i<-hx, j<-hx, i<j]
        links = map (\(i,j) -> link i j) (makeMesh hx)
        -- hostMacs = zip hx (map (\(Just (x,_,_)) -> x) interfaces)
        --unlinks = map (\(i,j) -> unlink (i,"mac1") (j,"mac2")) mesh
        unlinks = map (\(i,j) -> unlink i j) (makeMesh hostMacs)
    putStrLn $ unlines links
    putStrLn $ unlines unlinks

gethostMacs' hx = do
    return $ zip hx (repeat "")

gethostMacs hx = do
    interfaces <- mapM getDomainDirectInterfaceData hx
    let macs = map (\(Just (x,_,_)) -> x) interfaces
    return $ zip hx macs
