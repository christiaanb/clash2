{-|
  Copyright   :  (C) 2012-2016, University of Twente,
                          2017, Google Inc.
                     2021-2024, QBayLogic B.V.
  License     :  BSD2 (see the file LICENSE)
  Maintainer  :  QBayLogic B.V. <devops@qbaylogic.com>

  Term representation in the CoreHW language: System F + LetRec + Case
-}

{-# LANGUAGE CPP #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE PatternSynonyms #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE UndecidableInstances #-}

module Clash.Core.Term
  ( Term (.., Letrec)
  , mkAbstraction
  , mkTyLams
  , mkLams
  , mkApps
  , mkTyApps
  , mkTmApps
  , mkTicks
  , TmName
  , varToId
  , Bind(..)
  , LetBinding
  , Pat (..)
  , patIds
  , patVars
  , Alt
  , TickInfo (..)
  , stripTicks
  , stripAllTicks
  , partitionTicks
  , NameMod (..)
  , PrimInfo (..)
  , PrimUnfolding (..)
  , IsMultiPrim (..)
  , MultiPrimInfo (..)
  , WorkInfo (..)
  , CoreContext (..)
  , Context
  , isLambdaBodyCtx
  , isTickCtx
  , walkTerm
  , collectArgs
  , collectArgsTicks
  , collectTicks
  , collectTermIds
  , collectBndrs
  , primArg
  ) where

-- External Modules
import Control.DeepSeq
import Data.Binary                             (Binary)
import Data.Coerce                             (coerce)
import qualified Data.DList                    as DList
import Data.Either                             (lefts, rights)
#if !MIN_VERSION_base(4,20,0)
import Data.Foldable                           (foldl')
#endif
import Data.Hashable                           (Hashable)
import Data.Maybe                              (catMaybes)
import Data.List                               (nub, partition)
import Data.Text                               (Text)
import GHC.Generics
#if MIN_VERSION_ghc(9,0,0)
import GHC.Types.SrcLoc                        (SrcSpan, leftmost_smallest)
#else
import SrcLoc                                  (SrcSpan, leftmost_smallest)
#endif

-- Internal Modules
import Clash.Core.DataCon                      (DataCon)
import Clash.Core.Literal                      (Literal)
import Clash.Core.Name                         (Name (..))
import {-# SOURCE #-} Clash.Core.Subst         () -- instance Eq/Ord Type
import {-# SOURCE #-} Clash.Core.Type          (Type)
import Clash.Core.Var                          (Var, Id, TyVar)
import Clash.Util                              (curLoc, thenCompare)

-- | Term representation in the CoreHW language: System F + LetRec + Case
data Term
  = Var     !Id                             -- ^ Variable reference
  | Data    !DataCon                        -- ^ Datatype constructor
  | Literal !Literal                        -- ^ Literal
  | Prim    !PrimInfo                       -- ^ Primitive
  | Lam     !Id Term                        -- ^ Term-abstraction
  | TyLam   !TyVar Term                     -- ^ Type-abstraction
  | App     !Term !Term                     -- ^ Application
  | TyApp   !Term !Type                     -- ^ Type-application
  | Let     !(Bind Term) Term               -- ^ Recursive let-binding
  | Case    !Term !Type [Alt]               -- ^ Case-expression: subject, type of
                                            -- alternatives, list of alternatives
  | Cast    !Term !Type !Type               -- ^ Cast a term from one type to another
  | Tick    !TickInfo !Term                 -- ^ Annotated term
  deriving (Show, Generic, NFData, Binary)

-- TODO When it is possible, remove this pattern.
pattern Letrec :: [LetBinding] -> Term -> Term
pattern Letrec bs x <- Let (bindToList -> bs) x
 where
  Letrec bs x = Let (Rec bs) x

bindToList :: Bind a -> [(Id, a)]
bindToList (NonRec i x) = [(i, x)]
bindToList (Rec xs) = xs

data TickInfo
  = SrcSpan !SrcSpan
  -- ^ Source tick, will get added by GHC by running clash with `-g`
  | NameMod !NameMod !Type
  -- ^ Modifier for naming module instantiations and registers, are added by
  -- the user by using the functions @Clash.Magic.[prefixName,suffixName,setName]@
  | DeDup
  -- ^ Deduplicate, i.e. try to share expressions between multiple branches.
  | NoDeDup
  -- ^ Do not deduplicate, i.e. /keep/, an expression inside a case-alternative;
  -- do not try to share expressions between multiple branches.
  deriving (Eq, Show, Generic, NFData, Binary)

instance Ord TickInfo where
  compare (SrcSpan s1) (SrcSpan s2) = leftmost_smallest s1 s2
  compare (NameMod m1 t1) (NameMod m2 t2) =
    compare m1 m2 `thenCompare` compare t1 t2
  compare t1 t2 = compare (getRank t1) (getRank t2)
    where
      getRank :: TickInfo -> Word
      getRank SrcSpan{} = 0
      getRank NameMod{} = 1
      getRank DeDup     = 2
      getRank NoDeDup   = 3

-- | Tag to indicate which instance/register name modifier was used
data NameMod
  = PrefixName
  -- ^ @Clash.Magic.prefixName@
  | SuffixName
  -- ^ @Clash.Magic.suffixName@
  | SuffixNameP
  -- ^ @Clash.Magic.suffixNameP@
  | SetName
  -- ^ @Clash.Magic.setName@
  deriving (Eq,Ord,Show,Generic,NFData,Hashable,Binary)

data IsMultiPrim
  = SingleResult
  | MultiResult
  deriving (Show, Generic, NFData, Eq, Hashable, Binary)

data PrimInfo = PrimInfo
  { primName :: !Text
  , primType :: !Type
  , primWorkInfo :: !WorkInfo
  , primMultiResult :: !IsMultiPrim
  -- ^ Primitive with multiple return values. Useful for primitives that cannot
  -- return their results as a single product type, due to limitation of
  -- synthesis tooling. It will be applied to its normal arguments, followed by
  -- the variables it should assign its results to.
  --
  -- See: 'Clash.Normalize.Transformations.setupMultiResultPrim'
  , primUnfolding :: !PrimUnfolding
  } deriving (Show, Generic, NFData, Binary)

data PrimUnfolding
  = NoUnfolding
  | Unfolding !Id
  deriving (Show, Generic, NFData, Eq, Hashable, Binary)

data MultiPrimInfo = MultiPrimInfo
  { mpi_primInfo :: PrimInfo
  , mpi_resultDc :: DataCon
  , mpi_resultTypes :: [Type]
  }

data WorkInfo
  = WorkConstant
  -- ^ Ignores its arguments, and outputs a constant
  | WorkNever
  -- ^ Never adds any work
  | WorkVariable
  -- ^ Does work when the arguments are variable
  | WorkAlways
  -- ^ Performs work regardless of whether the variables are constant or
  -- variable; these are things like clock or reset generators
  | WorkIdentity Int [Int]
  -- ^ A more restrictive version of 'WorkNever', where the value is the
  -- argument at the given position if all arguments for the given list of
  -- positions are also 'WorkIdentity'
  deriving (Eq,Show,Generic,NFData,Hashable,Binary)

-- | Term reference
type TmName     = Name Term
-- | Binding in a LetRec construct
type LetBinding = (Id, Term)

data Bind a
  = NonRec Id a
  | Rec [(Id, a)]
  deriving (Eq, Show, Generic, NFData, Hashable, Binary, Functor)
  -- Structural equivalence instead of alpha equivalance

-- | Patterns in the LHS of a case-decomposition
data Pat
  = DataPat !DataCon [TyVar] [Id]
  -- ^ Datatype pattern, '[TyVar]' bind existentially-quantified
  -- type-variables of a DataCon
  | LitPat  !Literal
  -- ^ Literal pattern
  | DefaultPat
  -- ^ Default pattern
  deriving (Eq, Ord, Show, Generic, NFData, Binary)

type Alt = (Pat,Term)

-- | Get the list of term-binders out of a DataType pattern
patIds :: Pat -> ([TyVar],[Id])
patIds (DataPat _  tvs ids) = (tvs,ids)
patIds _                    = ([],[])

patVars :: Pat -> [Var a]
patVars (DataPat _ tvs ids) = coerce tvs ++ coerce ids
patVars _ = []

-- | Abstract a term over a list of term and type variables
mkAbstraction :: Term -> [Either Id TyVar] -> Term
mkAbstraction = foldr (either Lam TyLam)

-- | Abstract a term over a list of type variables
mkTyLams :: Term -> [TyVar] -> Term
mkTyLams tm = mkAbstraction tm . map Right

-- | Abstract a term over a list of variables
mkLams :: Term -> [Id] -> Term
mkLams tm = mkAbstraction tm . map Left

-- | Apply a list of types and terms to a term
mkApps :: Term -> [Either Term Type] -> Term
mkApps = foldl' (\e a -> either (App e) (TyApp e) a)

-- | Apply a list of terms to a term
mkTmApps :: Term -> [Term] -> Term
mkTmApps = foldl' App

-- | Apply a list of types to a term
mkTyApps :: Term -> [Type] -> Term
mkTyApps = foldl' TyApp

mkTicks :: Term -> [TickInfo] -> Term
mkTicks tm ticks = foldl' (\e s -> Tick s e) tm (nub ticks)

-- | Context in which a term appears
data CoreContext
  = AppFun
  -- ^ Function position of an application
  | AppArg (Maybe (Text, Int, Int))
  -- ^ Argument position of an application. If this is an argument applied to
  -- a primitive, a tuple is defined containing (name of the primitive, #type
  -- args, #term args)
  | TyAppC
  -- ^ Function position of a type application
  | LetBinding Id [Id]
  -- ^ RHS of a Let-binder with the sibling LHS'
  | LetBody [LetBinding]
  -- ^ Body of a Let-binding with the bound LHS'
  | LamBody Id
  -- ^ Body of a lambda-term with the abstracted variable
  | TyLamBody TyVar
  -- ^ Body of a TyLambda-term with the abstracted type-variable
  | CaseAlt Pat
  -- ^ RHS of a case-alternative with the bound pattern on the LHS
  | CaseScrut
  -- ^ Subject of a case-decomposition
  | CastBody
  -- ^ Body of a Cast
  | TickC TickInfo
  -- ^ Body of a Tick
  deriving (Show, Generic, NFData, Binary)

-- | A list of @CoreContext@ describes the complete navigation path from the
-- top-level to a specific sub-expression.
type Context = [CoreContext]

-- [Note] Custom @Eq@ instance for @CoreContext@
--
-- We need a manual equality instance here, due to the argument of `AppArg`.
-- Specifically, it is the only piece of information kept in `CoreContext`,
-- which references information about its children, breaking the invariant
-- that contexts represent a navigation to a specific sub-expression.
--
-- One would expect equal contexts to navigate to the same place, but if
-- these navigate to an argument position that contains different children,
-- we will get inequality from the derived `Eq`.
instance Eq CoreContext where
  c == c' = case (c, c') of
    (AppFun,          AppFun)            -> True
    (AppArg _,        AppArg _)          -> True
    -- NB: we do not see inside the argument here
    (TyAppC,          TyAppC)            -> True
    (LetBinding i is, LetBinding i' is') -> i == i' && is == is'
    (LetBody is,      LetBody is')       -> map fst is == map fst is'
    (LamBody i,       LamBody i')        -> i == i'
    (TyLamBody tv,    TyLamBody tv')     -> tv == tv'
    (CaseAlt p,       CaseAlt p')        -> p == p'
    (CaseScrut,       CaseScrut)         -> True
    (CastBody,        CastBody)          -> True
    (TickC sp,        TickC sp')         -> sp == sp'
    (_,               _)                 -> False

-- | Is the Context a Lambda/Term-abstraction context?
isLambdaBodyCtx :: CoreContext -> Bool
isLambdaBodyCtx (LamBody _) = True
isLambdaBodyCtx _           = False

-- | Is the Context a Tick context?
isTickCtx :: CoreContext -> Bool
isTickCtx (TickC _) = True
isTickCtx _         = False

stripTicks :: Term -> Term
stripTicks (Tick _ e) = stripTicks e
stripTicks e = e

-- | Like 'stripTicks' but removes all ticks from subexpressions.
stripAllTicks :: Term -> Term
stripAllTicks = go
 where
  go (Lam i x) = Lam i (go x)
  go (TyLam i x) = TyLam i (go x)
  go (App f x) = App (go f) (go x)
  go (TyApp f a) = TyApp (go f) a
  go (Let bs x) = Let (goBinds bs) (go x)
  go (Case x ty alts) = Case (go x) ty (fmap go <$> alts)
  go (Cast x a b) = Cast (go x) a b
  go (Tick _ x) = go x
  go x = x

  goBinds (NonRec i x) = NonRec i (go x)
  goBinds (Rec ixs) = Rec (fmap go <$> ixs)

-- | Split a (Type)Application in the applied term and it arguments
collectArgs :: Term -> (Term, [Either Term Type])
collectArgs = go []
  where
    go args (App e1 e2) = go (Left e2:args) e1
    go args (TyApp e t) = go (Right t:args) e
    go args (Tick _ e)  = go args e
    go args e           = (e, args)

collectTicks :: Term -> (Term, [TickInfo])
collectTicks = go []
 where
  go ticks (Tick s e) = go (s:ticks) e
  go ticks e          = (e,ticks)

collectArgsTicks :: Term -> (Term, [Either Term Type], [TickInfo])
collectArgsTicks = go [] []
 where
  go args ticks (App e1 e2) = go (Left e2:args) ticks     e1
  go args ticks (TyApp e t) = go (Right t:args) ticks     e
  go args ticks (Tick s e)  = go args           (s:ticks) e
  go args ticks e           = (e, args, ticks)

-- | Split a (Type)Abstraction in the bound variables and the abstracted term
collectBndrs :: Term -> ([Either Id TyVar], Term)
collectBndrs = go []
 where
  go bs (Lam v e')    = go (Left v:bs) e'
  go bs (TyLam tv e') = go (Right tv:bs) e'
  go bs e'            = (reverse bs,e')

-- | Given a function application, find the primitive it's applied. Yields
-- Nothing if given term is not an application or if it is not a primitive.
primArg
  :: Term
  -- ^ Function application
  -> Maybe (Text, Int, Int)
  -- ^ If @Term@ was a primitive: (name of primitive, #type args, #term args)
primArg (collectArgs -> t) =
  case t of
    (Prim p, args) ->
      Just (primName p, length (rights args), length (lefts args))
    _ ->
      Nothing

-- | Partition ticks in source ticks and nameMod ticks
partitionTicks
  :: [TickInfo]
  -> ([TickInfo], [TickInfo])
  -- ^ (source ticks, nameMod ticks)
partitionTicks = partition (\case {SrcSpan {} -> True; _ -> False})

-- | Visit all terms in a term, testing it with a predicate, and returning
-- a list of predicate yields.
walkTerm :: forall a . (Term -> Maybe a) -> Term -> [a]
walkTerm f = catMaybes . DList.toList . go
 where
  go :: Term -> DList.DList (Maybe a)
  go t = DList.cons (f t) $ case t of
    Var _ -> mempty
    Data _ -> mempty
    Literal _ -> mempty
    Prim _ -> mempty
    Lam _ t1 -> go t1
    TyLam _ t1 -> go t1
    App t1 t2 -> go t1 <> go t2
    TyApp t1 _ -> go t1
    Let (NonRec _ x) t1 -> go t1 <> go x
    Let (Rec bndrs) t1 -> go t1 <> mconcat (map (go . snd) bndrs)
    Case t1 _ alts -> go t1 <> mconcat (map (go . snd) alts)
    Cast t1 _ _ -> go t1
    Tick _ t1 -> go t1

-- Collect all term ids mentioned in a term
collectTermIds :: Term -> [Id]
collectTermIds = concat . walkTerm (Just . go)
 where
  go :: Term -> [Id]
  go (Var i) = [i]
  go (Lam i _) = [i]
  go (Let (NonRec i _) _) = [i]
  go (Let (Rec bndrs) _) = fmap fst bndrs
  go (Case _ _ alts) = concatMap (pat . fst) alts
  go (Data _) = []
  go (Literal _) = []
  go (Prim _) = []
  go (TyLam _ _) = []
  go (App _ _) = []
  go (TyApp _ _) = []
  go (Cast _ _ _) = []
  go (Tick _ _) = []

  pat :: Pat -> [Id]
  pat (DataPat _ _ ids) = ids
  pat (LitPat _) = []
  pat DefaultPat = []

-- | Make a term variable out of a variable reference or ticked variable
-- reference
varToId :: Term -> Id
varToId = \case
  Var i    -> i
  Tick _ e -> varToId e
  e        -> error $ $(curLoc) ++ "varToId: not a var: " ++ show e
