{-|
Copyright:    (C) 2022 Google Inc.
License:      BSD2 (see the file LICENSE)
Maintainer:   QBayLogic B.V. <devops@qbaylogic.com>
-}

{-# LANGUAGE CPP #-}
{-# LANGUAGE TypeFamilies #-}

module Clash.FFI.VPI.Object.Type
  ( ObjectType(..)
  , UnknownObjectType(..)
  ) where

import           Control.Exception (Exception, throwIO)
import           Foreign.C.Types (CInt)
import           GHC.Stack (CallStack, callStack, prettyCallStack)

import           Clash.FFI.View

-- | The type of the object according to the VPI specification. This can be
-- queried using the @vpiType@ property, and the value used to identify when
-- it is safe to coerce into a type in the higher-level VPI API.
--
#if defined(VERILOG_2001)
data ObjectType
  = ObjModule
  | ObjNet
  | ObjParameter
  | ObjPort
  | ObjReg
  | ObjCallback
  deriving stock (Eq, Show)
#else
data ObjectType
  = ObjModule
  | ObjNet
  | ObjParameter
  | ObjPort
  | ObjReg
  deriving stock (Eq, Show)
#endif

type instance CRepr ObjectType = CInt

#if defined(VERILOG_2001)
instance Send ObjectType where
  send =
    pure . \case
      ObjModule -> 32
      ObjNet -> 36
      ObjParameter -> 41
      ObjPort -> 44
      ObjReg -> 48
      ObjCallback -> 107
#else
instance Send ObjectType where
  send =
    pure . \case
      ObjModule -> 32
      ObjNet -> 36
      ObjParameter -> 41
      ObjPort -> 44
      ObjReg -> 48
#endif

-- | An exception thrown when decoding an object type if an invalid value is
-- given for the C enum that specifies the constructor of 'ObjectType'. Note
-- that there are many object types in the specification not included in these
-- bindings, so an unknown type is likely a library issue to report.
--
data UnknownObjectType
  = UnknownObjectType CInt CallStack
  deriving anyclass (Exception)

instance Show UnknownObjectType where
  show = \case
    UnknownObjectType x c -> mconcat
      [ "Unknown object type: "
      , show x
      , "\n"
      , prettyCallStack c
      ]

#if defined(VERILOG_2001)
instance Receive ObjectType where
  receive = \case
    32 -> pure ObjModule
    36 -> pure ObjNet
    41 -> pure ObjParameter
    44 -> pure ObjPort
    48 -> pure ObjReg
    107 -> pure ObjCallback
    ty -> throwIO $ UnknownObjectType ty callStack
#else
instance Receive ObjectType where
  receive = \case
    32 -> pure ObjModule
    36 -> pure ObjNet
    41 -> pure ObjParameter
    44 -> pure ObjPort
    48 -> pure ObjReg
    ty -> throwIO $ UnknownObjectType ty callStack
#endif
