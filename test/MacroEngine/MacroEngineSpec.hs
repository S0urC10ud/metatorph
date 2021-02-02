module MacroEngine.MacroEngineSpec where

import MacroEngine.MacroEngine
import Parser.MetaNode
import Common.Number
import qualified Data.Map as Map

import Control.Exception (evaluate)
import Test.Hspec

ellipsis = "..."

spec :: Spec
spec = describe "MacroEngine" $ do
  describe "MacroEngine.match" $ do
    it "matches underscore" $ do
      match [] ellipsis (IdentifierAtom "blah") (IdentifierAtom "_") `shouldBe` Just emptyTree
    it "matches non-literal" $ do
      match [] ellipsis (IdentifierAtom "blah") (IdentifierAtom "pattern") `shouldBe` Just (singletonTree (IdentifierAtom "pattern") (IdentifierAtom "blah"))
    it "matches non-literal String" $ do
      match [] ellipsis (StringAtom "blah") (IdentifierAtom "pattern") `shouldBe` Just (singletonTree (IdentifierAtom "pattern") (StringAtom "blah"))
    it "does not match literal with different binding" $ do
      match ["lit"] ellipsis (IdentifierAtom "blah") (IdentifierAtom "lit") `shouldBe` Nothing
    it "matches literal with same binding" $ do
      match ["lit"] ellipsis (IdentifierAtom "lit") (IdentifierAtom "lit") `shouldBe` Just (singletonTree (IdentifierAtom "lit") (IdentifierAtom "lit"))
    it "matches number constant" $ do
      match [] ellipsis (NumberAtom (Exact (Integer 3))) (NumberAtom (Exact (Integer 3))) `shouldBe` Just emptyTree
    it "does not match number constant" $ do
      match [] ellipsis (NumberAtom (Exact (Integer 4))) (NumberAtom (Exact (Integer 3))) `shouldBe` Nothing
    it "matches string constant" $ do
      match [] ellipsis (StringAtom "mystr") (StringAtom "mystr") `shouldBe` Just emptyTree
    it "does not match string constant" $ do
      match [] ellipsis (StringAtom "mystrde") (StringAtom "mystr") `shouldBe` Nothing
    it "matches bool constant" $ do
      match [] ellipsis (BoolAtom True) (BoolAtom True) `shouldBe` Just emptyTree
    it "does not match bool constant" $ do
      match [] ellipsis (BoolAtom True) (BoolAtom False) `shouldBe` Nothing
    it "matches char constant" $ do
      match [] ellipsis (CharAtom 'd') (CharAtom 'd') `shouldBe` Just emptyTree
    it "does not match chat constant" $ do
      match [] ellipsis (CharAtom 'd') (CharAtom 'e') `shouldBe` Nothing

  describe "MacroEngine.matchList" $ do
    describe "regular list" $ do
      it "matches list of equal lenght" $ do
        let
          patterns = PairNode (IdentifierAtom "hansi") (PairNode (IdentifierAtom "a") (PairNode (IdentifierAtom "b") EmptyAtom))
          params = PairNode (IdentifierAtom "node") (PairNode (IdentifierAtom "anothernode") (PairNode (IdentifierAtom "b") EmptyAtom))
        matchList [] ellipsis params patterns  `shouldBe` Just [Value (IdentifierAtom "hansi") (IdentifierAtom "node"), Value (IdentifierAtom "a") (IdentifierAtom "anothernode"), Value (IdentifierAtom "b") (IdentifierAtom "b")]
      it "does not match longer param list" $ do
        let
          patterns = PairNode (IdentifierAtom "hansi") (PairNode (IdentifierAtom "a") EmptyAtom)
          params = PairNode (IdentifierAtom "node") (PairNode (IdentifierAtom "anothernode") (PairNode (IdentifierAtom "b") EmptyAtom))
        matchList [] ellipsis params patterns  `shouldBe` Nothing
      it "does not match longer pattern list" $ do
        let
          patterns = PairNode (IdentifierAtom "hansi") (PairNode (IdentifierAtom "a") (PairNode (IdentifierAtom "b") EmptyAtom))
          params = PairNode (IdentifierAtom "node") (PairNode (IdentifierAtom "anothernode") EmptyAtom)
        matchList [] ellipsis params patterns  `shouldBe` Nothing
    describe "ellipsis list" $ do
      it "matches ellipsis [multiple][beginning]" $ do
        let
          patterns = PairNode (IdentifierAtom "a") (PairNode (IdentifierAtom "...") (PairNode (IdentifierAtom "b") EmptyAtom))
          params = PairNode (IdentifierAtom "node") (PairNode (IdentifierAtom "anothernode") (PairNode (IdentifierAtom "b") (PairNode (IdentifierAtom "la") (PairNode (IdentifierAtom "blah") EmptyAtom))))
        matchList [] ellipsis params patterns  `shouldBe` Just [Ellipsis (IdentifierAtom "a") [EllipsisValue (IdentifierAtom "node"), EllipsisValue (IdentifierAtom "anothernode"), EllipsisValue (IdentifierAtom "b"), EllipsisValue (IdentifierAtom "la")], Value (IdentifierAtom "b") (IdentifierAtom "blah")] 
      it "matches ellipsis [one][beginning]" $ do
        let
          patterns = PairNode (IdentifierAtom "a") (PairNode (IdentifierAtom "...") (PairNode (IdentifierAtom "b") EmptyAtom))
          params = PairNode (IdentifierAtom "node") (PairNode (IdentifierAtom "la") EmptyAtom)
        matchList [] ellipsis params patterns  `shouldBe` Just [Ellipsis (IdentifierAtom "a") [EllipsisValue (IdentifierAtom "node")], Value (IdentifierAtom "b") (IdentifierAtom "la")]
      it "matches ellipsis [zero][beginning]" $ do
        let
          patterns = PairNode (IdentifierAtom "a") (PairNode (IdentifierAtom "...") (PairNode (IdentifierAtom "b") EmptyAtom))
          params = PairNode (IdentifierAtom "la") EmptyAtom
        matchList [] ellipsis params patterns  `shouldBe` Just [Ellipsis (IdentifierAtom "a") [], Value (IdentifierAtom "b") (IdentifierAtom "la")]
      it "matches ellipsis [multiple][middle]" $ do
        let
          patterns = PairNode (IdentifierAtom "a") (PairNode (IdentifierAtom "b") (PairNode (IdentifierAtom "...") (PairNode (IdentifierAtom "c") EmptyAtom)))
          params = PairNode (IdentifierAtom "node") (PairNode (IdentifierAtom "anothernode") (PairNode (IdentifierAtom "b") (PairNode (IdentifierAtom "la") (PairNode (IdentifierAtom "blah") EmptyAtom))))
        matchList [] ellipsis params patterns  `shouldBe` Just [Value (IdentifierAtom "a") (IdentifierAtom "node"), Ellipsis (IdentifierAtom "b") [EllipsisValue (IdentifierAtom "anothernode"), EllipsisValue (IdentifierAtom "b"), EllipsisValue (IdentifierAtom "la")], Value (IdentifierAtom "c") (IdentifierAtom "blah")] 
      it "matches ellipsis [one][middle]" $ do
        let
          patterns = PairNode (IdentifierAtom "a") (PairNode (IdentifierAtom "b") (PairNode (IdentifierAtom "...") (PairNode (IdentifierAtom "c") EmptyAtom)))
          params = PairNode (IdentifierAtom "node") (PairNode (IdentifierAtom "la") (PairNode (IdentifierAtom "blah") EmptyAtom))
        matchList [] ellipsis params patterns  `shouldBe` Just [Value (IdentifierAtom "a") (IdentifierAtom "node"), Ellipsis (IdentifierAtom "b") [EllipsisValue (IdentifierAtom "la")], Value (IdentifierAtom "c") (IdentifierAtom "blah")] 
      it "matches ellipsis [zero][middle]" $ do
        let
          patterns = PairNode (IdentifierAtom "a") (PairNode (IdentifierAtom "b") (PairNode (IdentifierAtom "...") (PairNode (IdentifierAtom "c") EmptyAtom)))
          params = PairNode (IdentifierAtom "la") (PairNode (IdentifierAtom "blah") EmptyAtom)
        matchList [] ellipsis params patterns  `shouldBe` Just [Value (IdentifierAtom "a") (IdentifierAtom "la"), Ellipsis (IdentifierAtom "b") [], Value (IdentifierAtom "c") (IdentifierAtom "blah")]
      it "matches ellipsis [multiple][end]" $ do
        let
          patterns = PairNode (IdentifierAtom "a") (PairNode (IdentifierAtom "b") (PairNode (IdentifierAtom "...") EmptyAtom))
          params = PairNode (IdentifierAtom "node") (PairNode (IdentifierAtom "anothernode") (PairNode (IdentifierAtom "b") (PairNode (IdentifierAtom "la") (PairNode (IdentifierAtom "blah") EmptyAtom))))
        matchList [] ellipsis params patterns  `shouldBe` Just [Value (IdentifierAtom "a") (IdentifierAtom "node"), Ellipsis (IdentifierAtom "b") [EllipsisValue (IdentifierAtom "anothernode"), EllipsisValue (IdentifierAtom "b"), EllipsisValue (IdentifierAtom "la"), EllipsisValue (IdentifierAtom "blah")]] 
      it "matches ellipsis [one][end]" $ do
        let
          patterns = PairNode (IdentifierAtom "a") (PairNode (IdentifierAtom "b") (PairNode (IdentifierAtom "...") EmptyAtom))
          params = PairNode (IdentifierAtom "node") (PairNode (IdentifierAtom "la") EmptyAtom)
        matchList [] ellipsis params patterns  `shouldBe` Just [Value (IdentifierAtom "a") (IdentifierAtom "node"), Ellipsis (IdentifierAtom "b") [EllipsisValue (IdentifierAtom "la")]]
      it "matches ellipsis [zero][end]" $ do
        let
          patterns = PairNode (IdentifierAtom "a") (PairNode (IdentifierAtom "b") (PairNode (IdentifierAtom "...") EmptyAtom))
          params = PairNode (IdentifierAtom "la") EmptyAtom
        matchList [] ellipsis params patterns  `shouldBe` Just [Value (IdentifierAtom "a") (IdentifierAtom "la"), Ellipsis (IdentifierAtom "b") []]
      it "does not match too short params with ellipsis" $ do
        let
          patterns = PairNode (IdentifierAtom "a") (PairNode (IdentifierAtom "b") (PairNode (IdentifierAtom "c") (PairNode (IdentifierAtom "...") EmptyAtom)))
          params = PairNode (IdentifierAtom "la") EmptyAtom
        matchList [] ellipsis params patterns  `shouldBe` Nothing
      it "matches subpatterns in ellipsis" $ do
        let
          patterns = PairNode (PairNode (IdentifierAtom "name") (PairNode (IdentifierAtom "value") EmptyAtom)) (PairNode (IdentifierAtom "...") EmptyAtom)
          params = PairNode (PairNode (IdentifierAtom "one") (PairNode (NumberAtom (Exact (Integer 3))) EmptyAtom)) (PairNode (PairNode (IdentifierAtom "two") (PairNode (NumberAtom (Exact (Integer 4))) EmptyAtom)) (PairNode (PairNode (IdentifierAtom "three") (PairNode (NumberAtom (Exact (Integer 2))) EmptyAtom)) EmptyAtom))
        matchList [] ellipsis params patterns  `shouldBe` Just [Ellipsis (PairNode (IdentifierAtom "name") (PairNode (IdentifierAtom "value") EmptyAtom)) [EllipsisSubPattern [Value (IdentifierAtom "name") (IdentifierAtom "one"),Value (IdentifierAtom "value") (NumberAtom (Exact (Integer 3)))],EllipsisSubPattern [Value (IdentifierAtom "name") (IdentifierAtom "two"),Value (IdentifierAtom "value") (NumberAtom (Exact (Integer 4)))],EllipsisSubPattern [Value (IdentifierAtom "name") (IdentifierAtom "three"),Value (IdentifierAtom "value") (NumberAtom (Exact (Integer 2)))]]]
    describe "sublist" $ do
      it "matches sublists" $ do
        let
          patterns = PairNode (IdentifierAtom "ta") (PairNode (PairNode (IdentifierAtom "tb") (PairNode (IdentifierAtom "tc") EmptyAtom)) EmptyAtom)
          params = PairNode (IdentifierAtom "ta") (PairNode (PairNode (IdentifierAtom "tb") (PairNode (IdentifierAtom "tc") EmptyAtom)) EmptyAtom)
        matchList [] ellipsis params patterns  `shouldBe` Just [Value (IdentifierAtom "ta") (IdentifierAtom "ta"), Value (IdentifierAtom "tb") (IdentifierAtom "tb"), Value (IdentifierAtom "tc") (IdentifierAtom "tc")]
    -- it "matches sublists with ellipsis" $ do
    --   let
    --     patterns = PairNode (IdentifierAtom "ta") (PairNode (IdentifierAtom "...") (PairNode (PairNode (IdentifierAtom "ta") (PairNode (IdentifierAtom "tb") EmptyAtom)) EmptyAtom))
    --     params = PairNode (IdentifierAtom "ta") (PairNode (PairNode (IdentifierAtom "ta") (PairNode (IdentifierAtom "tb") EmptyAtom)) EmptyAtom)
    --   matchList [] ellipsis params patterns  `shouldBe` True
    -- it "does not match wrong lenght sublists with ellipsis" $ do
    --   let
    --     patterns = PairNode (IdentifierAtom "ta") (PairNode (IdentifierAtom "...") (PairNode (PairNode (IdentifierAtom "ta") (PairNode (IdentifierAtom "tb") EmptyAtom)) EmptyAtom))
    --     params = PairNode (IdentifierAtom "node") (PairNode (IdentifierAtom "anode") (PairNode (IdentifierAtom "twonode") (PairNode (PairNode (IdentifierAtom "ta") (PairNode (IdentifierAtom "tb") (PairNode (IdentifierAtom "a") EmptyAtom))) EmptyAtom)))
    --   matchList [] ellipsis params patterns  `shouldBe` Nothing
    describe "error cases" $ do
      it "fails when ellipsis is first element of pattern list" $ do
        let
          patterns = PairNode (IdentifierAtom "...") (PairNode (IdentifierAtom "a") (PairNode (IdentifierAtom "b") EmptyAtom))
          params = PairNode (IdentifierAtom "la") EmptyAtom
        evaluate (matchList [] ellipsis params patterns) `shouldThrow` anyErrorCall
      it "fails when multiple ellipsis are in a pattern list" $ do
        let
          patterns = PairNode (IdentifierAtom "a") (PairNode (IdentifierAtom "...") (PairNode (IdentifierAtom "...") EmptyAtom))
          params = PairNode (IdentifierAtom "la") EmptyAtom
        evaluate (matchList [] ellipsis params patterns) `shouldThrow` anyErrorCalls
      -- can't be tested because error call is inside nubBy function
      -- it "fails when a pattern variable is duplicated" $ do
      --   let
      --     patterns = PairNode (IdentifierAtom "a") (PairNode (IdentifierAtom "a") (PairNode (IdentifierAtom "b") EmptyAtom))
      --     params = PairNode (IdentifierAtom "a") (PairNode (IdentifierAtom "a") (PairNode (IdentifierAtom "b") EmptyAtom))
      --   evaluate (matchList [] ellipsis params patterns) `shouldThrow` anyErrorCall