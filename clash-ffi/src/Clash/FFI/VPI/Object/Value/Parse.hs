{-|
Copyright:    (C) 2022 Google Inc.
License:      BSD2 (see the file LICENSE)
Maintainer:   QBayLogic B.V. <devops@qbaylogic.com>
-}

{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE OverloadedStrings #-}

module Clash.FFI.VPI.Object.Value.Parse
  ( parseBinStr
  , parseOctStr
  , parseDecStr
  , parseHexStr
  , InvalidBitString(..)
  , ImpreciseBitString(..)
  ) where

import           Control.Exception (Exception)
import qualified Control.Monad as Monad (foldM)
import qualified Control.Monad.IO.Class as IO (liftIO)
import           Data.Bits (shiftL)
import           Data.Char (toLower)
import           Data.Function (fix)
import           Data.Typeable (Typeable)
import           Foreign.C.String (CString)
import           Foreign.C.Types (CInt)
import           GHC.Stack (CallStack, HasCallStack, callStack, prettyCallStack)
import           GHC.TypeNats (KnownNat)
import           Text.Read (readMaybe)

import           Clash.Class.BitPack
import           Clash.Sized.BitVector (BitVector)
import           Clash.XException (deepErrorX)

import           Clash.FFI.View (peekCStringBound)
import           Clash.FFI.Monad (SimCont)
import qualified Clash.FFI.Monad as Sim
import           Clash.FFI.VPI.Object.Value.Format (ValueFormat(..))

-- | An exception thrown when the bit string to parse contains characters
-- which should not appear for the given format.
--
data InvalidBitString
  = InvalidBitString ValueFormat String CallStack
  deriving anyclass (Exception)

instance Show InvalidBitString where
  show (InvalidBitString f s c) =
    mconcat
      [ "Invalid bit-string for format "
      , show f
      , ": "
      , s
      , "\n"
      , prettyCallStack c
      ]

-- TODO: These parsers are all defined in terms of replaceBit, however that
-- may be a bottleneck in applications reading a lot of values / large values.

parseBinStr
  :: forall n o
   . HasCallStack
  => KnownNat n
  => CInt
  -> CString
  -> SimCont o (BitVector n)
parseBinStr bitSize bin = do
  let is = [bitSize - 1, bitSize - 2 .. 0]
  str <- IO.liftIO $ peekCStringBound (fromEnum bitSize) bin

  let go acc (i, x) =
        case x of
          '0' -> pure (replaceBit i 0 acc)
          '1' -> pure (replaceBit i 1 acc)
          'x' -> pure acc
          'z' -> pure acc
          _   -> Sim.throw (InvalidBitString BinStrFmt str callStack)

  Monad.foldM go (deepErrorX "parseBinStr: undefined") (zip is str)

-- | An exception thrown when the bit string does not preserve all information
-- about the current value of a bit vector. This can only be thrown when
-- attempting to read values as octal or hexadecimal.
--
-- Consider the following bit string:
--
-- > 9'b.0.1.1001
--
-- Attempting to read this as octal or hexadecimal results in a loss of
-- precision in the value, giving @XX1@ and @xX9@. When @\'X\'@ (or @\'Z\'@)
-- appear in the string it means some bits for a octal / hexadecimal digit are
-- defined and others are undefined, but does not specify which were defined.
--
-- This loss of precision may be undesirable for certain applications, so we
-- provide a way to recover. If this exception is caught, the catcher can
-- amend the string, and call the supplied continuation to retry the parse.
--
data ImpreciseBitString n o = ImpreciseBitString
  { sourceFormat :: ValueFormat
  , sourceString :: String
  , retryParse :: String -> SimCont o (BitVector n)
  , parseStack :: CallStack
  }
  deriving anyclass (Exception)

instance Show (ImpreciseBitString n o) where
  show (ImpreciseBitString f s _ c) =
    mconcat
      [ "Loss of precision in bit string for format: "
      , show f
      , ": "
      , s
      , "\nX or Z mean some bits are defined and others are not."
      , "\nConsider using `BinStrFmt` or `VectorFmt` which are lossless."
      , "\n"
      , prettyCallStack c
      ]

parseOctStr
  :: forall n o
   . HasCallStack
  => KnownNat n
  => Typeable o
  => CInt
  -> CString
  -> SimCont o (BitVector n)
parseOctStr bitSize oct = do
  let bound = bitSize `div` 3 + if bitSize `mod` 3 == 0 then 0 else 1
      is = [0, 3 .. bitSize - 1]
  str <- IO.liftIO $ peekCStringBound (fromEnum bound) oct

  let go acc (i, x) =
        case x of
          '0' -> pure (replaceSlice (0, 0, 0) i acc)
          '1' -> pure (replaceSlice (0, 0, 1) i acc)
          '2' -> pure (replaceSlice (0, 1, 0) i acc)
          '3' -> pure (replaceSlice (0, 1, 1) i acc)
          '4' -> pure (replaceSlice (1, 0, 0) i acc)
          '5' -> pure (replaceSlice (1, 0, 1) i acc)
          '6' -> pure (replaceSlice (1, 1, 0) i acc)
          '7' -> pure (replaceSlice (1, 1, 1) i acc)
          'x' -> pure acc
          'X' -> Sim.throw (ImpreciseBitString OctStrFmt str parse callStack)
          'z' -> pure acc
          'Z' -> Sim.throw (ImpreciseBitString OctStrFmt str parse callStack)
          _ -> Sim.throw (InvalidBitString OctStrFmt str callStack)

      parse =
        Monad.foldM go (deepErrorX "parseOctStr: undefined") . zip is . reverse

  parse str
 where
   replaceSlice ~(x, y, z) i
     | i == bitSize - 1
     = replaceBit i z

     | i == bitSize - 2
     = replaceBit (i + 1) y . replaceBit i z

     | otherwise
     = replaceBit (i + 2) x . replaceBit (i + 1) y . replaceBit i z

parseDecStr
  :: forall n o
   . HasCallStack
  => KnownNat n
  => CInt
  -> CString
  -> SimCont o (BitVector n)
parseDecStr bitSize dec = do
  let bound = fromInteger
        $ fix (\f a x -> if x < 10 then a else f (a + 1) $ div x 10) 1
        $ shiftL (1 :: Integer)
        $ fromEnum bitSize
  str <- IO.liftIO $ peekCStringBound bound dec

  -- I don't think you can have X or Z in the decimal strings, although the
  -- standard doesn't mention you can have x or z here either...
  case str of
    ""  -> pure (fromInteger 0)
    "x" -> pure (deepErrorX "parseDecStr: x")
    "z" -> pure (deepErrorX "parseDecStr: z")
    _   -> maybe
             (Sim.throw (InvalidBitString DecStrFmt str callStack))
             (pure . fromInteger)
             (readMaybe str)

parseHexStr
  :: forall n o
   . HasCallStack
  => KnownNat n
  => Typeable o
  => CInt
  -> CString
  -> SimCont o (BitVector n)
parseHexStr bitSize hex = do
  let bound = bitSize `div` 4 + if bitSize `mod` 4 == 0 then 0 else 1
      is = [0, 4 .. bitSize - 1]
  str <- IO.liftIO $ peekCStringBound (fromEnum bound) hex

  let go acc (i, x) =
        case toLower x of
          '0' -> pure (replaceSlice (0, 0, 0, 0) i acc)
          '1' -> pure (replaceSlice (0, 0, 0, 1) i acc)
          '2' -> pure (replaceSlice (0, 0, 1, 0) i acc)
          '3' -> pure (replaceSlice (0, 0, 1, 1) i acc)
          '4' -> pure (replaceSlice (0, 1, 0, 0) i acc)
          '5' -> pure (replaceSlice (0, 1, 0, 1) i acc)
          '6' -> pure (replaceSlice (0, 1, 1, 0) i acc)
          '7' -> pure (replaceSlice (0, 1, 1, 1) i acc)
          '8' -> pure (replaceSlice (1, 0, 0, 0) i acc)
          '9' -> pure (replaceSlice (1, 0, 0, 1) i acc)
          'a' -> pure (replaceSlice (1, 0, 1, 0) i acc)
          'b' -> pure (replaceSlice (1, 0, 1, 1) i acc)
          'c' -> pure (replaceSlice (1, 1, 0, 0) i acc)
          'd' -> pure (replaceSlice (1, 1, 0, 1) i acc)
          'e' -> pure (replaceSlice (1, 1, 1, 0) i acc)
          'f' -> pure (replaceSlice (1, 1, 1, 1) i acc)

          'x' | x == 'X'  -> Sim.throw (ImpreciseBitString HexStrFmt str parse callStack)
              | otherwise -> pure acc

          'z' | x == 'Z'  -> Sim.throw (ImpreciseBitString HexStrFmt str parse callStack)
              | otherwise -> pure acc

          _ -> Sim.throw (InvalidBitString HexStrFmt str callStack)

      parse =
        Monad.foldM go (deepErrorX "parseHexStr: undefined") . zip is . reverse

  parse str
 where
  replaceSlice ~(w, x, y, z) i
    | i == bitSize - 1
    = replaceBit i z

    | i == bitSize - 2
    = replaceBit (i + 1) y . replaceBit i z

    | i == bitSize - 3
    = replaceBit (i + 2) x . replaceBit (i + 1) y . replaceBit i z

    | otherwise
    = replaceBit (i + 3) w . replaceBit (i + 2) x . replaceBit (i + 1) y . replaceBit i z
