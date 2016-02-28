{-# LANGUAGE BangPatterns, NoImplicitPrelude, MagicHash #-}
{-# OPTIONS_GHC -fno-warn-orphans #-}

module New1.Integer
    ( module New1.GHC.Integer
    , hexShow
    , readInteger
    ) where

import Prelude hiding (Integer)
import Data.Char (ord)
import Data.List (foldl')
import GHC.Types
import Numeric

import New1.GHC.Integer
import New1.GHC.Integer.Array
import New1.GHC.Integer.Sign
import New1.GHC.Integer.Type


instance Num Integer where
    (+) = plusInteger
    (-) = minusInteger
    (*) = timesInteger
    abs = absInteger
    signum = signumInteger
    fromInteger = readInteger . show


instance Show Integer where
    show = hexShow


hexShow :: Integer -> String
hexShow (Small _ 0) = "0x0"
hexShow (Small s a) =
    let sign = if s == Neg then '-' else '+'
    in sign : "0x" ++ showHex a ""

hexShow (Large s n arr)
    | n == 1 && indexWordArray arr 0 == 0 = "0x0"
    | otherwise =
        let sign = if s == Neg then '-' else '+'
            number = arrayShow n arr
        in if number == "0x0"
            then number
            else sign : number

readInteger :: String -> Integer
readInteger [] = 0
readInteger ('-':xs) = -1 * readInteger xs
readInteger ('+':xs) = readInteger xs
readInteger s =
    foldl' (\acc c -> acc * (smallInteger 10#) + readChar c) (smallInteger 0#) s
  where
    readChar :: Char -> Integer
    readChar c =
        let !(I# i) = ord c - 48
        in smallInteger i
