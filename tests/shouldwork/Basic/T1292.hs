module T1292 where

import Clash.Prelude
import Clash.Explicit.Testbench

topEntity :: Maybe (Index 16, Unsigned 4) -> Index 16
topEntity (Just (a,_)) = a
{-# NOINLINE topEntity #-}

testBench :: Signal System Bool
testBench = done
  where
    testInput      = stimuliGenerator clk rst (Just (2,0):>Nil)
    expectedOutput = outputVerifier' clk rst (2:>Nil)
    done           = expectedOutput (fmap topEntity testInput)
    clk            = tbSystemClockGen (not <$> done)
    rst            = systemResetGen
