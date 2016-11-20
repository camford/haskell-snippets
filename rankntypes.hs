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
func f (x, y) = undefined
-- func f (x, y) = (f x, f y) -- fails if uncommented

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
1/ func f (x, y) = (f x, f y)
2/ func f = \(x,y) -> (f x, f y)
3/ func = \f -> (\(x,y) -> (f x, f y))
           ^                ^    ^
           |                |    |
        (a -> a)    (a :: Int)  (a :: String)
I'm not quite sure how to explain the above line but essentially once f
is bound to a function it wants to check the type of that function will
suit it's definition. So it looks across, see's 'f x' and binds the type
a to Int (since x is an Int). However, as it continues to look across it
sees the 'f y' and tries to resolve this with 'f' being something that
takes an Int. No can do! Type error!

The correct way to do this is to 'delay' the binding of the type variable
a to a specific type. This is done as follows.
-}
func' :: (forall a . a -> a) -> (Int, String) -> (Int, String)
func' f (x, y) = (f x, f y)

{-
To do this we need to enable the 'RankNTypes' GHC extension, as done at the top
of this module.
-}
