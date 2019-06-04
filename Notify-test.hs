module Main where

import System.Environment(getArgs)
import Notify

main :: IO ()
main = do
    args <- getArgs
    if 1 /= length args then
        putStrLn "please specify a (single) file to watch"
    else do
        let s = head args
        watch <- setWatchModify s
        loop watch s
        where
        loop w s = do
            putStrLn "waiting..."
            flag <- getWatch w 10
            if flag then putStrLn $ s ++ " was modified"
                    else putStrLn "timer expired"
            loop w s
