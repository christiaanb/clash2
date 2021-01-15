{-|
  Copyright  :  (C) 2015-2016, University of Twente,
                    2017     , Myrtle Software Ltd, Google Inc.
  License    :  BSD2 (see the file LICENSE)
  Maintainer :  Christiaan Baaij <christiaan.baaij@gmail.com>
-}

{-# LANGUAGE CPP               #-}
{-# LANGUAGE OverloadedStrings #-}

module Clash.Backend where

import Data.HashSet                         (HashSet)
import Data.Semigroup.Monad                 (Mon (..))
import Data.Text                            (Text)
import qualified Data.Text.Lazy             as LT
import Control.Monad.State                  (State)
import Data.Text.Prettyprint.Doc.Extra      (Doc)

#if MIN_VERSION_ghc(9,0,0)
import GHC.Types.SrcLoc (SrcSpan)
#else
import SrcLoc (SrcSpan)
#endif

import {-# SOURCE #-} Clash.Netlist.Types
import Clash.Netlist.BlackBox.Types

import Clash.Annotations.Primitive          (HDL)

#ifdef CABAL
import qualified Paths_clash_lib
import qualified Data.Version
#else
import qualified System.FilePath
#endif

primsRoot :: IO FilePath
#ifdef CABAL
primsRoot = Paths_clash_lib.getDataFileName "prims"
#else
primsRoot = return ("clash-lib" System.FilePath.</> "prims")
#endif

clashVer :: String
#ifdef CABAL
clashVer = Data.Version.showVersion Paths_clash_lib.version
#else
clashVer = "development"
#endif

type ModName = Text

-- | Is a type used for internal or external use
data Usage
  = Internal
  -- ^ Internal use
  | External Text
  -- ^ External use, field indicates the library name

-- | Is '-fclash-aggresive-x-optimization-blackbox' set?
newtype AggressiveXOptBB = AggressiveXOptBB Bool


-- | Kind of a HDL type. Used to determine whether types need conversions in
-- order to cross top entity boundaries.
data HWKind
  = PrimitiveType
  -- ^ A type defined in an HDL spec. Usually types such as: bool, bit, ..
  | SynonymType
  -- ^ A user defined type that's simply a synonym for another type, very much
  -- like a type synonym in Haskell. As long as two synonym types refer to the
  -- same type, they can be used interchangeably. E.g., a subtype in VHDL.
  | UserType
  -- ^ User defined type that's not interchangeable with any others, even if
  -- the underlying structures are the same. Similar to an ADT in Haskell.

class HasIdentifierSet state => Backend state where
  -- | Initial state for state monad
  initBackend
    :: Int
    -> HdlSyn
    -> Bool
    -> PreserveCase
    -> Maybe (Maybe Int)
    -> AggressiveXOptBB
    -> state

  -- | What HDL is the backend generating
  hdlKind :: state -> HDL

  -- | Location for the primitive definitions
  primDirs :: state -> IO [FilePath]

  -- | Name of backend, used for directory to put output files in. Should be
  --   constant function / ignore argument.
  name :: state -> String

  -- | File extension for target langauge
  extension :: state -> String

  -- | Get the set of types out of state
  extractTypes     :: state -> HashSet HWType

  -- | Generate HDL for a Netlist component
  genHDL           :: ModName -> SrcSpan -> IdentifierSet -> Component -> Mon (State state) ((String, Doc),[(String,Doc)])
  -- | Generate a HDL package containing type definitions for the given HWTypes
  mkTyPackage      :: ModName -> [HWType] -> Mon (State state) [(String, Doc)]
  -- | Convert a Netlist HWType to a target HDL type
  hdlType          :: Usage -> HWType -> Mon (State state) Doc
  -- | Query what kind of type a given HDL type is
  hdlHWTypeKind :: HWType -> State state HWKind
  -- | Convert a Netlist HWType to an HDL error value for that type
  hdlTypeErrValue  :: HWType       -> Mon (State state) Doc
  -- | Convert a Netlist HWType to the root of a target HDL type
  hdlTypeMark      :: HWType       -> Mon (State state) Doc
  -- | Create a record selector
  hdlRecSel        :: HWType -> Int -> Mon (State state) Doc
  -- | Create a signal declaration from an identifier (Text) and Netlist HWType
  hdlSig           :: LT.Text -> HWType -> Mon (State state) Doc
  -- | Create a generative block statement marker
  genStmt          :: Bool -> State state Doc
  -- | Turn a Netlist Declaration to a HDL concurrent block
  inst             :: Declaration  -> Mon (State state) (Maybe Doc)
  -- | Turn a Netlist expression into a HDL expression
  expr             :: Bool -- ^ Enclose in parentheses?
                   -> Expr -- ^ Expr to convert
                   -> Mon (State state) Doc
  -- | Bit-width of Int,Word,Integer
  iwWidth          :: State state Int
  -- | Convert to a bit-vector
  toBV             :: HWType -> LT.Text -> Mon (State state) Doc
  -- | Convert from a bit-vector
  fromBV           :: HWType -> LT.Text -> Mon (State state) Doc
  -- | Synthesis tool we're generating HDL for
  hdlSyn           :: State state HdlSyn
  -- | setModName
  setModName       :: ModName -> state -> state
  -- | setSrcSpan
  setSrcSpan       :: SrcSpan -> State state ()
  -- | getSrcSpan
  getSrcSpan       :: State state SrcSpan
  -- | Block of declarations
  blockDecl        :: Identifier -> [Declaration] -> Mon (State state) Doc
  addIncludes      :: [(String, Doc)] -> State state ()
  addLibraries     :: [LT.Text] -> State state ()
  addImports       :: [LT.Text] -> State state ()
  addAndSetData    :: FilePath -> State state String
  getDataFiles     :: State state [(String,FilePath)]
  addMemoryDataFile  :: (String,String) -> State state ()
  getMemoryDataFiles :: State state [(String,String)]
  ifThenElseExpr :: state -> Bool
  -- | Whether -fclash-aggressive-x-optimization-blackboxes was set
  aggressiveXOptBB :: State state AggressiveXOptBB
