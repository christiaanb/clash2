{-# LANGUAGE CPP, OverloadedStrings #-}

module T1568 where

import qualified Data.List as List (find)

import Clash.Prelude

import Clash.Backend
import Clash.Core.Name
import Clash.Core.Var
import Clash.Core.VarEnv
import Clash.Driver.Types

#if __GLASGOW_HASKELL__ >= 900
import GHC.Types.Basic
#else
import BasicTypes
#endif

import Test.Tasty.Clash
import Test.Tasty.Clash.CoreTest

{-# ANN f (Synthesize
      { t_name   = "f"
      , t_inputs = [PortName "in"]
      , t_output = PortName "out"
      })
  #-}
f :: Int -> Int
f x = x `rem` 2

topEntity :: Double -> Double
topEntity = (*2)

testPath :: FilePath
testPath = "tests/shouldwork/Issues/T1568.hs"

mainCommon
  :: (Backend (TargetToState target))
  => SBuildTarget target
  -> IO ()
mainCommon hdl = do
  (bm, _, _) <- runToCoreStage hdl id testPath

  checkTE "T1568.f" bm
  checkTE "T1568.topEntity" bm
 where
  findBinding n = List.find (withName n) . eltsVarEnv
  withName n b = nameOcc (varName (bindingId b)) == n

  checkTE n bm =
    case findBinding n bm of
      Just b | bindingSpec b == NoInline -> pure ()
             | otherwise -> error ("Binding is not marked NOINLINE: " <> show (bindingSpec b))

      Nothing -> error ("Could not find top entity: " <> show n)

mainVHDL :: IO ()
mainVHDL = mainCommon SVHDL

mainVerilog :: IO ()
mainVerilog = mainCommon SVerilog

mainSystemVerilog :: IO ()
mainSystemVerilog = mainCommon SSystemVerilog
