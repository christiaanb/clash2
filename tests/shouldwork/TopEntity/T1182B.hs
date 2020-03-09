{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeFamilies #-}

module PortNames where

import qualified Prelude as P

import Clash.Prelude
import Clash.Netlist.Types
import Clash.Annotations.TH

import Clash.Class.HasDomain

import Test.Tasty.Clash
import Test.Tasty.Clash.NetlistTest

import qualified Data.Text as T

data SevenSegment dom (n :: Nat) = SevenSegment
    { anodes :: "AN" ::: Signal dom (Vec n Bool)
    , segments :: "SEG" ::: Signal dom (Vec 7 Bool)
    , dp :: "DP" ::: Signal dom Bool
    }

type instance TryDomain t (SevenSegment dom n) = Found dom

topEntity
    :: "CLK" ::: Clock System
    -> "SS" ::: SevenSegment System 8
topEntity clk = withClockResetEnable clk resetGen enableGen $
    SevenSegment{ anodes = pure $ repeat False, segments = pure $ repeat False, dp = pure False }
makeTopEntity 'topEntity

testPath :: FilePath
testPath = "tests/shouldwork/TopEntity/T1182B.hs"

assertInputs :: Component -> IO ()
assertInputs (Component _ [(clk,Clock _)]
  [ (Wire,(ssan,Vector 8 Bool),Nothing)
  , (Wire,(ssseg,Vector 7 Bool),Nothing)
  , (Wire,(ssdp,Bool),Nothing)
  ] ds)
  | clk == T.pack "CLK"
  && ssan == T.pack "SS_AN"
  && ssseg == T.pack "SS_SEG"
  && ssdp == T.pack "SS_DP"
  = pure ()
assertInputs c = error $ "Component mismatch: " P.++ show c

getComponent :: (a, b, c, d) -> d
getComponent (_, _, _, x) = x

mainVHDL :: IO ()
mainVHDL = do
  netlist <- runToNetlistStage SVHDL id testPath
  mapM_ (assertInputs . getComponent) netlist

mainVerilog :: IO ()
mainVerilog = do
  netlist <- runToNetlistStage SVerilog id testPath
  mapM_ (assertInputs . getComponent) netlist

mainSystemVerilog :: IO ()
mainSystemVerilog = do
  netlist <- runToNetlistStage SSystemVerilog id testPath
  mapM_ (assertInputs . getComponent) netlist

