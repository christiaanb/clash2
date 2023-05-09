{-|
  Copyright   :  (C) 2023, Google LLC
  License     :  BSD2 (see the file LICENSE)
  Maintainer  :  QBayLogic B.V. <devops@qbaylogic.com>
-}

module Clash.Cores.Xilinx.Xpm.Cdc
  ( xpmCdcArraySingle
  , xpmCdcAsyncRst
  , xpmCdcGray
  , xpmCdcHandshake
  , xpmCdcPulse
  , xpmCdcSingle
  ) where

import Clash.Cores.Xilinx.Xpm.Cdc.ArraySingle
import Clash.Cores.Xilinx.Xpm.Cdc.AsyncRst
import Clash.Cores.Xilinx.Xpm.Cdc.Gray
import Clash.Cores.Xilinx.Xpm.Cdc.Handshake
import Clash.Cores.Xilinx.Xpm.Cdc.Pulse
import Clash.Cores.Xilinx.Xpm.Cdc.Single