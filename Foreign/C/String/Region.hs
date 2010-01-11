{-# LANGUAGE UnicodeSyntax #-}
{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE CPP #-}

-------------------------------------------------------------------------------
-- |
-- Module      :  Foreign.C.String.Region
-- Copyright   :  (c) 2010 Bas van Dijk
-- License     :  BSD3 (see the file LICENSE)
-- Maintainer  :  Bas van Dijk <v.dijk.bas@gmail.com>
--
-------------------------------------------------------------------------------

module Foreign.C.String.Region
       ( -- * Regional C Strings
         RegionalCString,  RegionalCStringLen

         -- * Using a locale-dependent encoding
       , peekCString,      peekCStringLen
       , newCString,       newCStringLen
       , withCString,      withCStringLen

       , charIsRepresentable

         -- * Using 8-bit characters
       , FCS.castCharToCChar
       , FCS.castCCharToChar

       , peekCAString,     peekCAStringLen
       , newCAString,      newCAStringLen
       , withCAString,     withCAStringLen

         -- * C wide strings
       , RegionalCWString, RegionalCWStringLen
       , peekCWString,     peekCWStringLen
       , newCWString,      newCWStringLen
       , withCWString,     withCWStringLen
       ) where


--------------------------------------------------------------------------------
-- Imports
--------------------------------------------------------------------------------

-- from base:
import Prelude                      ( fromInteger, fromIntegral )
import Data.Function                ( ($) )
import Data.Bool                    ( Bool )
import Data.Int                     ( Int )
import Data.Char                    ( Char, String, ord )
import Data.List                    ( map, length )
import Control.Arrow                ( first )
import Control.Monad                ( return, (>>=), fail)
import Foreign.C.Types              ( CChar, CWchar )
import Foreign.Storable             ( Storable )
import qualified Foreign.C.String as FCS

#ifdef mingw32_HOST_OS
-- These are only used in the mingw32 version of 'charsToCWchars':
import Prelude                      ( (-), (+), mod, div )
import Data.List                    ( foldr )
import Data.Bool                    ( otherwise )
import Control.Monad                ( (>>) )
import Data.Ord                     ( (<) )
#endif

-- from base-unicode-symbols:
import Data.Function.Unicode        ( (∘) )

-- from transformers:
import Control.Monad.Trans          ( MonadIO, liftIO )

-- from MonadCatchIO-transformers:
import Control.Monad.CatchIO        ( MonadCatchIO )

-- from regions:
import Control.Monad.Trans.Region   ( RegionT, ParentOf )

-- from ourselves:
import Foreign.Marshal.Array.Region ( newArray0, newArray
                                    , withArray0, withArrayLen
                                    )
import Foreign.Ptr.Region           ( RegionalPtr )
import Foreign.Ptr.Region.Unsafe    ( unsafePtr, wrap )


--------------------------------------------------------------------------------
-- Regional C Strings
--------------------------------------------------------------------------------

type RegionalCString    r =  RegionalPtr CChar r
type RegionalCStringLen r = (RegionalPtr CChar r, Int)


--------------------------------------------------------------------------------
-- Using a locale-dependent encoding
--------------------------------------------------------------------------------

peekCString ∷ (pr `ParentOf` cr, MonadIO cr)
             ⇒ RegionalCString pr → cr String
peekCString = peekCAString

peekCStringLen ∷ (pr `ParentOf` cr, MonadIO cr)
               ⇒ RegionalCStringLen pr → cr String
peekCStringLen = peekCAStringLen

newCString ∷ MonadCatchIO pr
           ⇒ String → RegionT s pr (RegionalCString (RegionT s pr))
newCString = newCAString

newCStringLen ∷ MonadCatchIO pr
              ⇒ String → RegionT s pr (RegionalCStringLen (RegionT s pr))
newCStringLen = newCAStringLen

withCString ∷ MonadCatchIO pr
            ⇒ String
            → (∀ s. RegionalCString (RegionT s pr) → RegionT s pr α)
            → pr α
withCString = withCAString

withCStringLen ∷ MonadCatchIO pr
               ⇒ String
               → (∀ s. RegionalCStringLen (RegionT s pr) → RegionT s pr α)
               → pr α
withCStringLen = withCAStringLen

charIsRepresentable ∷ MonadIO m ⇒ Char → m Bool
charIsRepresentable = liftIO ∘ FCS.charIsRepresentable


--------------------------------------------------------------------------------
-- Using 8-bit characters
--------------------------------------------------------------------------------

peekCAString ∷ (pr `ParentOf` cr, MonadIO cr)
             ⇒ RegionalCString pr → cr String
peekCAString = wrap FCS.peekCAString

peekCAStringLen ∷ (pr `ParentOf` cr, MonadIO cr)
                ⇒ RegionalCStringLen pr → cr String
peekCAStringLen = liftIO ∘ FCS.peekCAStringLen ∘ first unsafePtr

newCAString ∷ MonadCatchIO pr
            ⇒ String → RegionT s pr (RegionalCString (RegionT s pr))
newCAString = newArray0 nUL ∘ charsToCChars

newCAStringLen ∷ MonadCatchIO pr
               ⇒ String → RegionT s pr (RegionalCStringLen (RegionT s pr))
newCAStringLen = newArrayLen ∘ charsToCChars

withCAString ∷ MonadCatchIO pr
             ⇒ String
             → (∀ s. RegionalCString (RegionT s pr) → RegionT s pr α)
             → pr α
withCAString = withArray0 nUL ∘ charsToCChars

withCAStringLen ∷ MonadCatchIO pr
                ⇒ String
                → (∀ s. RegionalCStringLen (RegionT s pr) → RegionT s pr α)
                → pr α
withCAStringLen str f = withArrayLen (charsToCChars str)
                      $ \len ptr → f (ptr, len)


--------------------------------------------------------------------------------
-- C wide strings
--------------------------------------------------------------------------------

type RegionalCWString    r =  RegionalPtr CWchar r
type RegionalCWStringLen r = (RegionalPtr CWchar r, Int)

peekCWString ∷ (pr `ParentOf` cr, MonadIO cr)
             ⇒ RegionalCWString pr → cr String
peekCWString = wrap FCS.peekCWString

peekCWStringLen ∷ (pr `ParentOf` cr, MonadIO cr)
                ⇒ RegionalCWStringLen pr → cr String
peekCWStringLen = liftIO ∘ FCS.peekCWStringLen ∘ first unsafePtr

newCWString ∷ MonadCatchIO pr
            ⇒ String → RegionT s pr (RegionalCWString (RegionT s pr))
newCWString = newArray0 wNUL ∘ charsToCWchars

newCWStringLen ∷ MonadCatchIO pr
               ⇒ String → RegionT s pr (RegionalCWStringLen (RegionT s pr))
newCWStringLen = newArrayLen ∘ charsToCWchars

withCWString ∷ MonadCatchIO pr
             ⇒ String
             → (∀ s. RegionalCWString (RegionT s pr) → RegionT s pr α)
             → pr α
withCWString = withArray0 wNUL ∘ charsToCWchars

withCWStringLen ∷ MonadCatchIO pr
                ⇒ String
                → (∀ s. RegionalCWStringLen (RegionT s pr) → RegionT s pr α)
                → pr α
withCWStringLen str f = withArrayLen (charsToCWchars str)
                      $ \len ptr → f (ptr, len)


--------------------------------------------------------------------------------
-- Utility functions
--------------------------------------------------------------------------------

nUL ∷ CChar
nUL = 0

wNUL ∷ CWchar
wNUL = 0

-- | allocate an array to hold the list and pair it with the number of elements.
newArrayLen ∷ (Storable α, MonadCatchIO pr)
            ⇒ [α] → RegionT s pr (RegionalPtr α (RegionT s pr), Int)
newArrayLen xs = do
  a <- newArray xs
  return (a, length xs)

charsToCChars ∷ [Char] → [CChar]
charsToCChars = map FCS.castCharToCChar

-- Note that the following is copied from 'Foreign.C.String':
charsToCWchars ∷ [Char] → [CWchar]

#ifdef mingw32_HOST_OS
-- On Windows, wchar_t is 16 bits wide and CWString uses the UTF-16 encoding.
charsToCWchars = foldr utf16Char [] ∘ map ord
 where
  utf16Char c wcs
    | c < 0x10000 = fromIntegral c : wcs
    | otherwise   = let c' = c - 0x10000 in
                    fromIntegral (c' `div` 0x400 + 0xd800) :
                    fromIntegral (c' `mod` 0x400 + 0xdc00) : wcs

#else
charsToCWchars = map castCharToCWchar

-- These conversions only make sense if __STDC_ISO_10646__ is defined
-- (meaning that wchar_t is ISO 10646, aka Unicode)

castCharToCWchar ∷ Char → CWchar
castCharToCWchar = fromIntegral ∘ ord
#endif


-- The End ---------------------------------------------------------------------
