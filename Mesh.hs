module Main where
import VirtMesh
import System.Environment(getArgs)

main = do
    hx <- getArgs
    let mesh = [(i,j) | i<-hx, j<-hx, i<j]
        links = map (\(i,j) -> link i j) mesh
        unlinks = map (\(i,j) -> unlink (i,"mac1") (j,"mac2")) mesh
    putStrLn $ unlines links
    putStrLn $ unlines unlinks
