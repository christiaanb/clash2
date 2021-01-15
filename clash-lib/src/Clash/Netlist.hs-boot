{-|
  Copyright   :  (C) 2015-2016, University of Twente
  License     :  BSD2 (see the file LICENSE)
  Maintainer  :  Christiaan Baaij <christiaan.baaij@gmail.com>
-}
{-# LANGUAGE CPP #-}

module Clash.Netlist
  (genComponent
  ,mkExpr
  ,mkDcApplication
  ,mkDeclarations
  ,mkDeclarations'
  ,mkNetDecl
  ,mkProjection
  ,mkSelection
  ,mkFunApp
  ) where

import Clash.Core.DataCon   (DataCon)
import Clash.Core.Term      (Alt,LetBinding,Term)
import Clash.Core.Type      (Type)
import Clash.Core.Var       (Id)
import Clash.Netlist.Types  (Expr, HWType, Identifier, NetlistMonad, Component,
                             Declaration, NetlistId, DeclarationType, IdentifierSet)

#if MIN_VERSION_ghc(9,0,0)
import GHC.Types.SrcLoc     (SrcSpan)
#else
import SrcLoc               (SrcSpan)
#endif

import GHC.Stack (HasCallStack)

genComponent :: HasCallStack
             => Id
             -> NetlistMonad ([Bool],SrcSpan,IdentifierSet,Component)

mkExpr :: HasCallStack
       => Bool
       -> DeclarationType
       -> NetlistId
       -> Term
       -> NetlistMonad (Expr,[Declaration])

mkDcApplication :: HasCallStack
                => [HWType]
                -> NetlistId
                -> DataCon
                -> [Term]
                -> NetlistMonad (Expr,[Declaration])

mkProjection
  :: Bool
  -> NetlistId
  -> Term
  -> Type
  -> Alt
  -> NetlistMonad (Expr, [Declaration])

mkSelection
  :: DeclarationType
  -> NetlistId
  -> Term
  -> Type
  -> [Alt]
  -> [Declaration]
  -> NetlistMonad [Declaration]

mkNetDecl :: LetBinding -> NetlistMonad [Declaration]

mkDeclarations :: HasCallStack => Id -> Term -> NetlistMonad [Declaration]
mkDeclarations' :: HasCallStack => DeclarationType -> Id -> Term -> NetlistMonad [Declaration]

mkFunApp
  :: HasCallStack
  => Identifier -- ^ LHS of the let-binder
  -> Id -- ^ Name of the applied function
  -> [Term] -- ^ Function arguments
  -> [Declaration] -- ^ Tick declarations
  -> NetlistMonad [Declaration]
