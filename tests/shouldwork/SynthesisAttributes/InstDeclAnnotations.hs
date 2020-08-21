{-# LANGUAGE OverloadedStrings #-}

module InstDeclAnnotations where

import           Clash.Annotations.Primitive     (HDL (..), Primitive (..))
import           Clash.Backend
import           Clash.Core.Var                  (Attr' (..))
import           Clash.Netlist.Id
import           Clash.Netlist.Types
import           Clash.Prelude
import           Control.Monad.State
import           GHC.Stack
import           Data.List                       (isInfixOf)
import           Data.String.Interpolate         (i)
import           Data.String.Interpolate.Util    (unindent)
import           Data.Semigroup.Monad            (getMon)
import qualified Data.Text as T
import qualified Data.Text.IO as T
import           Data.Text.Prettyprint.Doc.Extra (Doc (..))
import qualified Prelude as P
import           System.Environment              (getArgs)


myTF :: TemplateFunction
myTF = TemplateFunction used valid myTemplate
 where
  used    = []
  valid _ = True

myTemplate
  :: Backend s
  => BlackBoxContext
  -> State s Doc
myTemplate bbCtx = do
  blkName  <- mkUniqueIdentifier Basic "blkName"
  compInst <- mkUniqueIdentifier Basic "test_inst"
  let
    compName = "TEST"
    attrs =
      [ IntegerAttr' "my_int_attr"    7
      , StringAttr'  "my_string_attr" "Hello World!"
      ]
  getMon
    $ blockDecl blkName [InstDecl Comp Nothing attrs compName compInst [] [] ]


myBlackBox
  :: Signal System Int
  -> Signal System Int
myBlackBox _ = pure (errorX "not implemented")
{-# NOINLINE myBlackBox #-}
{-# ANN myBlackBox (InlinePrimitive [VHDL,Verilog,SystemVerilog] $ unindent [i|
   [ { "BlackBox" :
        { "name" : "InstDeclAnnotations.myBlackBox",
          "kind" : "Declaration",
          "format": "Haskell",
          "templateFunction": "InstDeclAnnotations.myTF"
        }
     }
   ]
   |]) #-}


topEntity
  :: SystemClockResetEnable
  => Signal System Int
  -> Signal System Int
topEntity = myBlackBox


--------------- Actual tests for generated HDL -------------------
assertIn :: String -> String -> IO ()
assertIn needle haystack
  | needle `isInfixOf` haystack = return ()
  | otherwise                   = P.error $ P.concat [ "Expected:\n\n  ", needle
                                                     , "\n\nIn:\n\n", haystack ]

-- VHDL test
mainVHDL :: IO ()
mainVHDL = do
  [topFile] <- getArgs
  content <- P.readFile topFile

  assertIn "attribute my_int_attr : integer;" content
  assertIn "attribute my_int_attr of TEST : component is 7;" content

  assertIn "attribute my_string_attr : string;" content
  assertIn "attribute my_string_attr of TEST : component is \"Hello World!\";" content

-- Verilog test
mainVerilog :: IO ()
mainVerilog = do
  [topFile] <- getArgs
  content <- P.readFile topFile

  assertIn "(* my_int_attr = 7, my_string_attr = \"Hello World!\" *)" content

-- Verilog and SystemVerilog should share annotation syntax
mainSystemVerilog = mainVerilog

