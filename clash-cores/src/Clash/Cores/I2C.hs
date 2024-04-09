{-# LANGUAGE CPP #-}

module Clash.Cores.I2C where

import Clash.Prelude

import Clash.Cores.I2C.BitMaster
import Clash.Cores.I2C.ByteMaster
import Clash.Cores.I2C.Types

{-# ANN i2c
  (Synthesize
    { t_name     = "i2c"
    , t_inputs   = [ PortName "clk"
                   , PortName "arst"
                   , PortName "rst"
                   , PortName "ena"
                   , PortName "clkCnt"
                   , PortName "start"
                   , PortName "stop"
                   , PortName "read"
                   , PortName "write"
                   , PortName "ackIn"
                   , PortName "din"
                   , PortName "i2cI"]
    , t_output   = PortProduct ""
                     [ PortName "dout"
                     , PortName "hostAck"
                     , PortName "busy"
                     , PortName "al"
                     , PortName "ackOut"
                     , PortProduct "" [PortName "i2cO_clk"]
                     ]
    }) #-}
i2c clk arst rst ena clkCnt start stop read write ackIn din i2cI = (dout,hostAck,busy,al,ackOut,i2cO)
  where
    (hostAck,ackOut,dout,bitCtrl) = byteMaster clk arst enableGen (rst,start,stop,read,write,ackIn,din,bitResp)
    (bitResp,busy,i2cO)           = bitMaster  clk arst enableGen (rst,ena,clkCnt,bitCtrl,i2cI)
    (cmdAck,al,dbout)             = unbundle bitResp
-- See: https://github.com/clash-lang/clash-compiler/pull/2511
{-# CLASH_OPAQUE i2c #-}
