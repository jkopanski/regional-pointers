{-# LANGUAGE NoImplicitPrelude #-}

-------------------------------------------------------------------------------
-- |
-- Module      :  Foreign.Ptr.Region.Unsfe
-- Copyright   :  (c) 2010 Bas van Dijk
-- License     :  BSD3 (see the file LICENSE)
-- Maintainer  :  Bas van Dijk <v.dijk.bas@gmail.com>
--
-- /Unsafe/ functions for retrieving the actual @Ptr@ from a regional pointer
-- and for lifting operations on @Ptrs@ to @RegionalPtrs@.
--
-- These operations are unsafe because they allow you to @free@ the regional
-- pointer before exiting their region. So they enable you to perform @IO@ with
-- already freed pointers.
--
-------------------------------------------------------------------------------

module Foreign.Ptr.Region.Unsafe
    ( unsafePtr
    , unsafeWrap, unsafeWrap2, unsafeWrap3
    ) where

import Foreign.Ptr.Region.Internal ( unsafePtr
                                   , unsafeWrap, unsafeWrap2, unsafeWrap3
                                   )
