module IPRoute where
import System.Process

getAllInterfaces :: IO [String]
-- getAllInterfaces = fmap (head . words . lines ) $ readProcess "ip" ["-br" , "link"] "" 
getAllInterfaces = do
    rawOutput <- readProcess "ip" ["-br" , "link"] "" 
    let l = lines rawOutput
        wx = map words l
        w1 = map head wx
    -- print l
    -- print wx
    -- print w1
    return w1
