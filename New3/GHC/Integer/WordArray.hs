{-# LANGUAGE BangPatterns #-}
module New3.GHC.Integer.WordArray where

import Control.Monad.Primitive
import Data.Primitive
import GHC.Word (Word)


newtype WordArray = WA ByteArray

newtype MutableWordArray m = MWA (MutableByteArray (PrimState m))

{-# INLINE newWordArray #-}
newWordArray :: PrimMonad m => Int -> m (MutableWordArray m)
newWordArray !len = do
    !marr <- newPinnedByteArray (len * sizeOf (0 :: Word))
    return $ MWA marr

newWordArrayCleared :: PrimMonad m => Int -> m (MutableWordArray m)
newWordArrayCleared !len = do
    !marr <- newPinnedByteArray (len * sizeOf (0 :: Word))
    setByteArray marr 0 len (0 :: Word)
    return $ MWA marr

-- | newPlaceholderWordArray : Create a place holder ByteArray for timesInteger
-- where a zero length ByteArray is needed. Memory is actually allocated, but
-- nothing is written to it os it will actually contain junk data.
newPlaceholderWordArray :: PrimMonad m => m WordArray
newPlaceholderWordArray = do
    !marr <- newPinnedByteArray (sizeOf (0 :: Word))
    unsafeFreezeWordArray (MWA marr)

cloneWordArrayExtend :: PrimMonad m => Int -> WordArray -> Int -> m (MutableWordArray m)
cloneWordArrayExtend !oldLen !(WA !arr) !newLen = do
    !marr <- newPinnedByteArray (newLen * sizeOf (0 :: Word))
    if oldLen > 0
        then copyByteArray marr 0 arr 0 ((min oldLen newLen) * sizeOf (0 :: Word))
        else return ()
    setByteArray marr oldLen (max 0 (newLen - oldLen)) (0 :: Word)
    return $ MWA marr

{-# INLINE readWordArray #-}
readWordArray :: PrimMonad m => MutableWordArray m -> Int -> m Word
readWordArray !(MWA !marr) i = readByteArray marr i

{-# INLINE unsafeFreezeWordArray #-}
unsafeFreezeWordArray :: PrimMonad m => MutableWordArray m -> m WordArray
unsafeFreezeWordArray !(MWA !marr) = do
    !arr <- unsafeFreezeByteArray marr
    return (WA arr)

{-# INLINE indexWordArray #-}
indexWordArray :: WordArray -> Int -> Word
indexWordArray !(WA !arr) = indexByteArray arr

{-# INLINE indexWordArrayM #-}
indexWordArrayM :: Monad m => WordArray -> Int -> m Word
indexWordArrayM !(WA !arr) !i = case indexByteArray arr i of x -> return x

{-# INLINE writeWordArray #-}
writeWordArray :: PrimMonad m => MutableWordArray m -> Int -> Word -> m ()
writeWordArray !(MWA !marr) = writeByteArray marr

{-# INLINE setWordArray #-}
setWordArray :: PrimMonad m => MutableWordArray m -> Int -> Int -> Word -> m ()
setWordArray !(MWA !marr) !off !count !word = setByteArray marr off count word

copyWordArray :: PrimMonad m => MutableWordArray m -> Int -> WordArray -> Int -> Int -> m ()
copyWordArray !(MWA !marr) !doff !(WA !arr) !soff !wrds =
    let !wordsize = sizeOf (0 :: Word)
    in copyByteArray marr (doff * wordsize) arr (soff * wordsize) (wrds * wordsize)
