-- This is some of the code from "RankNTypes Ain't Rank at All - λC 2016"
-- by Chris Allen : https://youtu.be/k0cZe0LVFI4
--
-- Timestamps are provided as I found some of the code hard to read from the video.
-- You can watch Chris' (great) talk or read my comments as I try to reiterate
-- his explanations.

{-# LANGUAGE RankNTypes #-}

{-
8:34 in the video

This function fails to type check (when not commented out).
The error (in GHC 8) is:

    rankntypes.hs:7:25: error:
        • Couldn't match expected type ‘a’ with actual type ‘String’
          ‘a’ is a rigid type variable bound by
            the type signature for:
              func :: forall a. (a -> a) -> (Int, String) -> (Int, String)
            at rankntypes.hs:6:9
        • In the first argument of ‘f’, namely ‘y’
          In the expression: f y
          In the expression: (f x, f y)
        • Relevant bindings include
            f :: a -> a (bound at rankntypes.hs:7:6)
            func :: (a -> a) -> (Int, String) -> (Int, String)
              (bound at rankntypes.hs:7:1)

This seems like it should work with id at least (id can take anything right?).
    id :: a -> a
-}
func :: (a -> a) -> (Int, String) -> (Int, String)
func f (i, s) = undefined
-- func f (i, s) = (f i, f s) -- fails if uncommented

{-
10:30 in the video

The problem is haskell is actually hiding some of the syntax.
This is good most of the time, saves us typing boilerplate but here's what
the signature actually looks like as Haskell sees it:

    func :: forall a . (a -> a) -> (Int, String) -> (Int, String)

What that's saying is:
 - "I take a function that takes an 'a' to an 'a'"
 - "The 'a' in that function should work *for all* types in the universe"
 - I then take a tuple and return a tuple*

* Yes I know, currying and all that but I'm skipping these details

Ok so let's apply func to id and see what a becomes.
1/ func f (i, s) = (f i, f s)
2/ func f = \(i, s) -> (f i, f s)
3/ func = \f -> (\(i, s) -> (f i, f s))
           ^                ^    ^
           |                |    |
        (a -> a)    (a :: Int)  (a :: String)
I'm not quite sure how to explain the above line but essentially once f
is bound to a function it wants to check the type of that function will
suit it's definition. So it looks across, see's 'f i' and binds the type
a to Int (since i is an Int). However, as it continues to look across it
sees the 'f s' and tries to resolve this with 'f' being something that
takes a String. No can do! Type error!

The correct way to do this is to 'delay' the binding of the type variable
a to a specific type. This is done as follows.
-}
func' :: (forall a . a -> a) -> (Int, String) -> (Int, String)
func' f (i, s) = (f i, f s)

{-
To do this we need to enable the 'RankNTypes' GHC extension, as done at the top
of this module.
-}

-- Fails again because can't bind a to both Int and Double
doStuff :: Num a => (a -> a) -> (Int, Double) -> (Int, Double)
doStuff = undefined
--doStuff f (i, d) = (f i, f d)

{-
Roughly 15:13 in the video

This type checks. But ...
Your function 'f' *does not* require the type constraint 'Num a'.
If you call this from ghci it'll look like it blows up at runtime (this is
what I thought was happening at first in the talk) but in actual fact, any
callee that doesn't passa function as general as (forall . a -> a) will fail to
type check.

So assume you call:
doStuff' (+1) (1, 1.5)

The compiler will complain (and rightly so) that:
    • No instance for (Num a1) arising from an operator section
      Possible fix:
        add (Num a1) to the context of
          a type expected by the context:
            a1 -> a1
    • In the first argument of ‘doStuff'’, namely ‘(+ 1)’
      In the expression: doStuff' (+ 1) (2, 4.5)
      In an equation for ‘it’: it = doStuff' (+ 1) (2, 4.5)

So the function (also known as a section in this case) '(+1)' only operates
on types that instance the Num typeclass but the function doStuff' requires
functions that are more general than that.
-}
doStuff' :: Num a => (forall a . a -> a) -> (Int, Double) -> (Int, Double)
doStuff' f (i, d) = (f i, f d)

doStuff'' :: (forall a . Num a => a -> a) -> (Int, Double) -> (Int, Double)
doStuff'' f (i, d) = (f i, f d)


-- 28:11 in the video

-- Rank 1
f1 :: forall a b . a -> b -> a
f1 = undefined

-- Rank 1
g1 :: forall a b . (Ord a, Eq b) => a -> b -> a
g1 = undefined

-- Rank 2
-- f2 :: (forall a . a -> a) -> Int -> Int
-- f2 = undefined

-- Rank 2
-- g2 :: (forall a . Eq a => [a] -> a -> Bool) -> Int -> Int
-- g2 = undefined

-- Rank 3
-- f3 :: ((forall a . a -> a) -> Int) -> Bool -> Bool
-- f3 = undefined
