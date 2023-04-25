{-|
  Copyright   :  (C) 2023, Google LLC
  License     :  BSD2 (see the file LICENSE)
  Maintainer  :  QBayLogic B.V. <devops@qbaylogic.com>
-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE RecordWildCards #-}

module Clash.Cores.Xilinx.Xpm.Cdc.Single
  ( xpmCdcSingle
  , XpmCdcSingleConfig(..)
  , xpmCdcSingleWith
  ) where

import GHC.Stack (HasCallStack)

import Clash.Explicit.Prelude

import Clash.Cores.Xilinx.Xpm.Cdc.Single.Internal (xpmCdcSingle#)

-- | Synchronizes an single bit from the source clock domain to the destination. For
-- more information see [PG382](https://docs.xilinx.com/r/en-US/pg382-xpm-cdc-generator/XPM_CDC_SINGLE).
--
-- __N.B.__: In order to simulate initial values, both the source and destination
--           domain need to support them. If the source and destination domain
--           disagree on this property, use of this function will fail to
--           simulate and translate to HDL. You can explicitly set it using
--           'xpmCdcSingleWith'.
xpmCdcSingle ::
  forall a src dst.
  ( KnownDomain src
  , KnownDomain dst
  , HasCallStack
  , BitPack a
  , BitSize a ~ 1
  ) =>
  Clock src ->
  Clock dst ->
  Signal src a ->
  Signal dst a
xpmCdcSingle = xpmCdcSingleWith XpmCdcSingleConfig{..}
 where
  registerInput = True
  stages = d4
  initialValues =
    case (initBehavior @src, initBehavior @dst) of
      (SDefined, SDefined) -> True
      (SUnknown, SUnknown) -> False
      _ -> clashCompileError $ "xpmCdcSingle: domains need to agree on initial value "
                            <> "behavior. To set initial value usage explicitly, "
                            <> "consider using 'xpmCdcSingleWith'."
{-# INLINE xpmCdcSingle #-}

-- | Configuration for 'xpmCdcSingleWith'
data XpmCdcSingleConfig stages = XpmCdcSingleConfig
  { -- | Number of synchronization stages. I.e., number of registers in the
    -- destination domain. Note that there is always a register in the source
    -- domain.
    stages :: SNat stages

    -- | Initialize registers used within the primitive to /0/. Note that
    -- 'xpmCdcSingle' will set this to 'True' if both domains support initial
    -- values, to 'False' if neither domain does, and will otherwise emit an
    -- error.
  , initialValues :: Bool

    -- | Register input. This makes sure the synchronization pipeline does not
    -- see glitches.
  , registerInput :: Bool
  }

-- | Like 'xpmCdcSingle', but with a configurable number of stages, initial values,
-- and registered input. Also see 'XpmCdcSingleConfig'.
xpmCdcSingleWith ::
  forall stages a src dst.
  ( 2 <= stages, stages <= 10
  , KnownDomain src
  , KnownDomain dst
  , BitPack a
  , BitSize a ~ 1
  ) =>
  XpmCdcSingleConfig stages ->
  Clock src ->
  Clock dst ->
  Signal src a ->
  Signal dst a
xpmCdcSingleWith XpmCdcSingleConfig{..} clkSrc clkDst input =
  xpmCdcSingle# registerInput initialValues stages clkSrc clkDst input
{-# INLINE xpmCdcSingleWith #-}
