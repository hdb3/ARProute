module Notify where

import qualified Data.ByteString.Char8 as BS

import System.INotify
import Control.Concurrent.Chan
import System.Timeout
import Data.Maybe(isJust)

setWatchModify :: String -> IO (Chan Event)
setWatchModify = setWatch [Modify]

setWatch :: [EventVariety] -> String -> IO (Chan Event)
setWatch events path = do
    inotify <- initINotify
    chan <- newChan :: IO (Chan Event) 
    _ <- addWatch inotify events ( BS.pack path ) (writeChan chan)
    return chan

getWatch :: Chan Event -> Int -> IO Bool
getWatch chan timer = do
    ev <- timeout (timer * truncate 1e6) ( readChan chan )
    return $ isJust ev
