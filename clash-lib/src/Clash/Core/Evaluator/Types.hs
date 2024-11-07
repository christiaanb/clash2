{-# LANGUAGE CPP #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}

{-|
  Copyright     : (C) 2020-2024, QBayLogic B.V.
  License       : BSD2 (see the file LICENSE)
  Maintainer    : QBayLogic B.V. <devops@qbaylogic.com>

  Types for the Partial Evaluator
-}
module Clash.Core.Evaluator.Types where

import Control.Concurrent.Supply (Supply)
import Data.IntMap.Strict (IntMap)
import qualified Data.IntMap.Strict as IntMap (insert, lookup)
#if !MIN_VERSION_base(4,20,0)
import Data.List (foldl')
#endif
import Data.Maybe (fromMaybe, isJust)

#if MIN_VERSION_prettyprinter(1,7,0)
import Prettyprinter (hsep)
#else
import Data.Text.Prettyprint.Doc (hsep)
#endif

import Clash.Core.DataCon (DataCon, dcType)
import Clash.Core.HasType
import Clash.Core.Literal (Literal(CharLiteral))
import Clash.Core.Pretty (fromPpr, ppr, showPpr)
import Clash.Core.Term (Term(..), PrimInfo(..), TickInfo, Alt, mkApps)
import Clash.Core.TyCon (TyConMap)
import Clash.Core.Type (Type (..), mkFunTy)
import Clash.Core.Var (Id, IdScope(..), TyVar)
import Clash.Core.VarEnv
import Clash.Driver.Types (BindingMap, bindingTerm)
import Clash.Pretty (ClashPretty(..), fromPretty, showDoc)

whnf'
  :: Evaluator
  -> BindingMap
  -> VarEnv Term
  -> TyConMap
  -> PrimHeap
  -> Supply
  -> InScopeSet
  -> Bool
  -> Term
  -> (PrimHeap, PureHeap, Term)
whnf' eval bm lh tcm ph ids is isSubj e =
  toResult $ whnf eval tcm isSubj m
 where
  toResult x = (mHeapPrim x, mHeapLocal x, mTerm x)

  m  = Machine ph gh lh [] ids is e
  gh = mapVarEnv bindingTerm bm

-- | Evaluate to WHNF given an existing Heap and Stack
whnf
  :: Evaluator
  -> TyConMap
  -> Bool
  -> Machine
  -> Machine
whnf eval tcm isSubj m
  | isSubj =
      -- See [Note: empty case expressions]
      let ty = inferCoreTypeOf tcm (mTerm m)
       in go (stackPush (Scrutinise ty []) m)
  | otherwise = go m
  where
    go :: Machine -> Machine
    go s = case step eval s tcm of
      Just s' -> go s'
      Nothing -> fromMaybe (error . showDoc . ppr $ mTerm m) (unwindStack s)


-- | An evaluator is a collection of basic building blocks which are used to
-- define partial evaluation. In this implementation, it consists of two types
-- of function:
--
--   * steps, which applies the reduction realtion to the current term
--   * unwindings, which pop the stack and evaluate the stack frame
--
-- Variants of these functions also exist for evalauting primitive operations.
-- This is because there may be multiple frontends to the compiler which can
-- reuse a common step and unwind, but have different primitives.
--
data Evaluator = Evaluator
  { step        :: Step
  , unwind      :: Unwind
  , primStep    :: PrimStep
  , primUnwind  :: PrimUnwind
  }

-- | Completely unwind the stack to get back the complete term
unwindStack :: Machine -> Maybe Machine
unwindStack m
  | stackNull m = Just m
  | otherwise = do
      (m', kf) <- stackPop m

      case kf of
        PrimApply p tys vs tms ->
          let term = foldl' App
                       (foldl' App
                         (foldl' TyApp (Prim p) tys)
                         (fmap valToTerm vs))
                       (mTerm m' : tms)
           in unwindStack (setTerm term m')

        Instantiate ty ->
          let term = TyApp (getTerm m') ty
           in unwindStack (setTerm term m')

        Apply n ->
          case heapLookup LocalId n m' of
            Just e ->
              let term = App (getTerm m') e
               in unwindStack (setTerm term m')

            Nothing -> error $ unlines $
              [ "Clash.Core.Evaluator.unwindStack:"
              , "Stack:"
              ] <>
              [ "  " <> showDoc (clashPretty frame) | frame <- mStack m] <>
              [ ""
              , "Expression:"
              , showPpr (mTerm m)
              , ""
              , "Heap:"
              , showDoc (clashPretty $ mHeapLocal m)
              ]

        Scrutinise _ [] ->
          unwindStack m'

        Scrutinise ty alts ->
          let term = Case (getTerm m') ty alts
           in unwindStack (setTerm term m')

        Update LocalId x ->
          unwindStack (heapInsert LocalId x (mTerm m') m')

        Update GlobalId _ ->
          unwindStack m'

        Tickish sp ->
          let term = Tick sp (getTerm m')
           in unwindStack (setTerm term m')

-- | A single step in the partial evaluator. The result is the new heap and
-- stack, and the next expression to be reduced.
--
type Step = Machine -> TyConMap -> Maybe Machine

type Unwind = Value -> Step

type PrimStep
  =  TyConMap
  -> Bool
  -> PrimInfo
  -> [Type]
  -> [Value]
  -> Machine
  -> Maybe Machine

type PrimUnwind
  =  TyConMap
  -> PrimInfo
  -> [Type]
  -> [Value]
  -> Value
  -> [Term]
  -> Machine
  -> Maybe Machine

-- | A machine represents the current state of the abstract machine used to
-- evaluate terms. A machine has a term under evaluation, a stack, and three
-- heaps:
--
--  * a primitive heap to store IO values from primitives (like ByteArrays)
--  * a global heap to store top-level bindings in scope
--  * a local heap to store local bindings in scope
--
-- Machines also include a unique supply and InScopeSet. These are needed when
-- new heap bindings are created, and are just an implementation detail.
--
data Machine = Machine
  { mHeapPrim   :: PrimHeap
  , mHeapGlobal :: PureHeap
  , mHeapLocal  :: PureHeap
  , mStack      :: Stack
  , mSupply     :: Supply
  , mScopeNames :: InScopeSet
  , mTerm       :: Term
  }

instance Show Machine where
  show (Machine ph gh lh s _ _ x) =
    unlines
      [ "Machine:"
      , ""
      , "Heap (Prim):"
      , show ph
      , ""
      , "Heap (Globals):"
      , show gh
      , ""
      , "Heap (Locals):"
      , show lh
      , ""
      , "Stack:"
      , show (fmap clashPretty s)
      , ""
      , "Term:"
      , show x
      ]

type PrimHeap = (IntMap Term, Int)
type PureHeap = VarEnv Term

type Stack = [StackFrame]

data StackFrame
  = Update IdScope Id
  | Apply  Id
  | Instantiate Type
  | PrimApply  PrimInfo [Type] [Value] [Term]
  | Scrutinise Type [Alt]
  | Tickish TickInfo
  deriving Show

instance ClashPretty StackFrame where
  clashPretty (Update GlobalId i) = hsep ["Update(Global)", fromPpr i]
  clashPretty (Update LocalId i)  = hsep ["Update(Local)", fromPpr i]
  clashPretty (Apply i) = hsep ["Apply", fromPpr i]
  clashPretty (Instantiate t) = hsep ["Instantiate", fromPpr t]
  clashPretty (PrimApply p tys vs ts) =
    hsep ["PrimApply", fromPretty (primName p), "::", fromPpr (coreTypeOf p),
          "; type args=", fromPpr tys,
          "; val args=", fromPpr (map valToTerm vs),
          "term args=", fromPpr ts]
  clashPretty (Scrutinise a b) =
    hsep ["Scrutinise ", fromPpr a,
          fromPpr (Case (Literal (CharLiteral '_')) a b)]
  clashPretty (Tickish sp) =
    hsep ["Tick", fromPpr sp]

-- Values
data Value
  = Lambda Id Term
  -- ^ Functions
  | TyLambda TyVar Term
  -- ^ Type abstractions
  | DC DataCon [Either Term Type]
  -- ^ Data constructors
  | Lit Literal
  -- ^ Literals
  | PrimVal  PrimInfo [Type] [Value]
  -- ^ Clash's number types are represented by their "fromInteger#" primitive
  -- function. So some primitives are values.
  | Suspend Term
  -- ^ Used by lazy primitives
  | TickValue TickInfo Value
  -- ^ Preserve ticks from Terms in Values
  | CastValue Value Type Type
  -- ^ Preserve casts from Terms in Values
  deriving Show

instance InferType Value where
  inferCoreTypeOf tcm = go
   where
    go = \case
      Lambda i t -> mkFunTy (coreTypeOf i) (inferCoreTypeOf tcm t)
      TyLambda v t -> ForAllTy v (inferCoreTypeOf tcm t)
      DC dc args -> applyTypeToArgs (mkApps (Data dc) args) tcm (dcType dc) args
      Lit l -> coreTypeOf l
      PrimVal p tys vals ->
        let args = map Right tys ++ map (Left . valToTerm) vals
         in applyTypeToArgs
              (mkApps (Prim p) args)
              tcm
              (primType p)
              args
      Suspend t -> inferCoreTypeOf tcm t
      TickValue _ v -> go v
      CastValue _ _ t -> t

valToTerm :: Value -> Term
valToTerm v = case v of
  Lambda x e           -> Lam x e
  TyLambda x e         -> TyLam x e
  DC dc pxs            -> foldl' (\e a -> either (App e) (TyApp e) a)
                                 (Data dc) pxs
  Lit l                -> Literal l
  PrimVal ty tys vs    -> foldl' App (foldl' TyApp (Prim ty) tys)
                                 (map valToTerm vs)
  Suspend e            -> e
  TickValue t x        -> Tick t (valToTerm x)
  CastValue x t1 t2    -> Cast (valToTerm x) t1 t2

-- Collect all the ticks from a value, exposing the ticked value.
--
collectValueTicks
  :: Value
  -> (Value, [TickInfo])
collectValueTicks = go []
 where
  go ticks (TickValue t v) = go (t:ticks) v
  go ticks v = (v, ticks)

-- | Are we in a context where special primitives must be forced.
--
-- See [Note: forcing special primitives]
forcePrims :: Machine -> Bool
forcePrims = go . mStack
 where
  -- When do we need to force the compile-time evaluation of a primitive?
  --
  -- 1. When they are the subject of a case-expression
  go (Scrutinise{}:_) = True
  -- 2. When they are in the argument position of another primitive:
  --    primitives are assumed to be strict in their arguments
  go (PrimApply{}:_)  = True
  -- We look through ticks
  go (Tickish{}:xs)   = go xs
  -- We are in a context where we dereferenced a heap-binding, hence the
  -- update fram on the stack. So now we need to check whether that variable
  -- reference was in a position where the result must be evaluated to WHNF
  go (Update{}:xs)    = go xs
  go _                = False

primCount :: Machine -> Int
primCount = snd . mHeapPrim

primLookup :: Int -> Machine -> Maybe Term
primLookup i = IntMap.lookup i . fst . mHeapPrim

primInsert :: Int -> Term -> Machine -> Machine
primInsert i x m =
  let (gh, c) = mHeapPrim m
   in m { mHeapPrim = (IntMap.insert i x gh, c + 1) }

primUpdate :: Int -> Term -> Machine -> Machine
primUpdate i x m =
  let (gh, c) = mHeapPrim m
   in m { mHeapPrim = (IntMap.insert i x gh, c) }

heapLookup :: IdScope -> Id -> Machine -> Maybe Term
heapLookup GlobalId i m =
  lookupVarEnv i $ mHeapGlobal m
heapLookup LocalId i m =
  lookupVarEnv i $ mHeapLocal m

heapContains :: IdScope -> Id -> Machine -> Bool
heapContains scope i = isJust . heapLookup scope i

heapInsert :: IdScope -> Id -> Term -> Machine -> Machine
heapInsert GlobalId i x m =
  m { mHeapGlobal = extendVarEnv i x (mHeapGlobal m) }
heapInsert LocalId i x m =
  m { mHeapLocal = extendVarEnv i x (mHeapLocal m) }

heapDelete :: IdScope -> Id -> Machine -> Machine
heapDelete GlobalId i m =
  m { mHeapGlobal = delVarEnv (mHeapGlobal m) i }
heapDelete LocalId i m =
  m { mHeapLocal = delVarEnv (mHeapLocal m) i }

stackPush :: StackFrame -> Machine -> Machine
stackPush f m = m { mStack = f : mStack m }

stackPop :: Machine -> Maybe (Machine, StackFrame)
stackPop m = case mStack m of
  [] -> Nothing
  (x:xs) -> Just (m { mStack = xs }, x)

stackClear :: Machine -> Machine
stackClear m = m { mStack = [] }

stackNull :: Machine -> Bool
stackNull = null . mStack

getTerm :: Machine -> Term
getTerm = mTerm

setTerm :: Term -> Machine -> Machine
setTerm x m = m { mTerm = x }
