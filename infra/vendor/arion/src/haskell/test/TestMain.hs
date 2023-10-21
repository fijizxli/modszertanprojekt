module Main where

import           Prelude()
import           Protolude
import           Test.Hspec.Runner
import qualified Spec

main :: IO ()
main = hspecWith config Spec.spec
  where config = defaultConfig { configColorMode = ColorAlways }
