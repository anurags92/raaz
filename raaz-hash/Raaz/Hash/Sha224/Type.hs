{-|

This module exposes the `SHA224` hash constructor. You would hardly
need to import the module directly as you would want to treat the
`SHA224` type as an opaque type for type safety. This module is
exported only for special uses like writing a test case or defining a
binary instance etc.

-}
{-# LANGUAGE DeriveDataTypeable         #-}
{-# LANGUAGE TypeFamilies               #-}
{-# LANGUAGE FlexibleInstances          #-}

module Raaz.Hash.Sha224.Type
       ( SHA224(..)
       , IV(SHA224IV)
       ) where

import Control.Applicative ((<$>), (<*>))
import Data.Bits(xor, (.|.))
import Data.Default
import Data.Typeable(Typeable)
import Foreign.Storable(Storable(..))

import Raaz.Primitives
import Raaz.Types
import Raaz.Util.Ptr(loadFromIndex, storeAtIndex)

import Raaz.Hash.Sha.Util
import Raaz.Hash.Sha256.Type(SHA256(..))

----------------------------- SHA224 -------------------------------------------

-- | Sha224 hash value which consist of 7 32bit words.
data SHA224 = SHA224 {-# UNPACK #-} !Word32BE
                     {-# UNPACK #-} !Word32BE
                     {-# UNPACK #-} !Word32BE
                     {-# UNPACK #-} !Word32BE
                     {-# UNPACK #-} !Word32BE
                     {-# UNPACK #-} !Word32BE
                     {-# UNPACK #-} !Word32BE deriving (Show, Typeable)

-- | Timing independent equality testing for sha224
instance Eq SHA224 where
  (==) (SHA224 g0 g1 g2 g3 g4 g5 g6) (SHA224 h0 h1 h2 h3 h4 h5 h6)
      =   xor g0 h0
      .|. xor g1 h1
      .|. xor g2 h2
      .|. xor g3 h3
      .|. xor g4 h4
      .|. xor g5 h5
      .|. xor g6 h6
      == 0


instance Storable SHA224 where
  sizeOf    _ = 7 * sizeOf (undefined :: Word32BE)
  alignment _ = alignment  (undefined :: Word32BE)
  peekByteOff ptr pos = SHA224 <$> peekByteOff ptr pos0
                               <*> peekByteOff ptr pos1
                               <*> peekByteOff ptr pos2
                               <*> peekByteOff ptr pos3
                               <*> peekByteOff ptr pos4
                               <*> peekByteOff ptr pos5
                               <*> peekByteOff ptr pos6
    where pos0   = pos
          pos1   = pos0 + offset
          pos2   = pos1 + offset
          pos3   = pos2 + offset
          pos4   = pos3 + offset
          pos5   = pos4 + offset
          pos6   = pos5 + offset
          offset = sizeOf (undefined:: Word32BE)

  pokeByteOff ptr pos (SHA224 h0 h1 h2 h3 h4 h5 h6)
      =  pokeByteOff ptr pos0 h0
      >> pokeByteOff ptr pos1 h1
      >> pokeByteOff ptr pos2 h2
      >> pokeByteOff ptr pos3 h3
      >> pokeByteOff ptr pos4 h4
      >> pokeByteOff ptr pos5 h5
      >> pokeByteOff ptr pos6 h6
    where pos0   = pos
          pos1   = pos0 + offset
          pos2   = pos1 + offset
          pos3   = pos2 + offset
          pos4   = pos3 + offset
          pos5   = pos4 + offset
          pos6   = pos5 + offset
          offset = sizeOf (undefined:: Word32BE)

instance CryptoStore SHA224 where
  load cptr = SHA224 <$> load cptr
                     <*> loadFromIndex cptr 1
                     <*> loadFromIndex cptr 2
                     <*> loadFromIndex cptr 3
                     <*> loadFromIndex cptr 4
                     <*> loadFromIndex cptr 5
                     <*> loadFromIndex cptr 6

  store cptr (SHA224 h0 h1 h2 h3 h4 h5 h6) =  store cptr h0
                                           >> storeAtIndex cptr 1 h1
                                           >> storeAtIndex cptr 2 h2
                                           >> storeAtIndex cptr 3 h3
                                           >> storeAtIndex cptr 4 h4
                                           >> storeAtIndex cptr 5 h5
                                           >> storeAtIndex cptr 6 h6

instance Primitive SHA224 where
  blockSize _ = cryptoCoerce $ BITS (512 :: Int)
  {-# INLINE blockSize #-}
  newtype IV SHA224 = SHA224IV SHA256

instance SafePrimitive SHA224

instance HasPadding SHA224 where
  maxAdditionalBlocks _ = 1
  padLength = padLength64
  padding   = padding64

instance Default (IV SHA224) where
  def = SHA224IV $ SHA256 0xc1059ed8
                          0x367cd507
                          0x3070dd17
                          0xf70e5939
                          0xffc00b31
                          0x68581511
                          0x64f98fa7
                          0xbefa4fa4
