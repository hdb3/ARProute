module Util where
import Data.List(sortOn,groupBy)
import Data.Ord(comparing)

breakOn :: Eq a => a -> [a] -> [[a]]
breakOn c = breakOn' (c ==) where
    breakOn' _ [] = []
    breakOn' p a | p (head a) = breakOn' p (tail a)
                 | otherwise = takeWhile (not . p) a : breakOn' p (dropWhile (not . p) a)

aggregatePairs :: Ord c => ((a,b) -> c) -> [(a,b)] -> [(a,[b])]
aggregatePairs cmp = map rollUp . aggregate cmp where
    rollUp :: [(a,b)] -> (a,[b])
    rollUp t = (fst $ head t, map snd t)

aggregate :: Ord b => (a -> b) -> [a] -> [[a]]
aggregate cmp = groupBy cmp' . sortOn cmp where cmp' a b = (EQ ==) $ ( comparing cmp ) a b
--aggregate cmp = groupBy cmp' . sortOn cmp where cmp' = (EQ ==) . comparing . cmp -- how make point free work?????
                                                                                   -- never when the function has more than one parameter??
