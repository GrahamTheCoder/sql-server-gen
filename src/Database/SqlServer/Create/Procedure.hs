module Database.SqlServer.Create.Procedure
       (
         Procedure,
         parameters,
         procedureName
       ) where

import Database.SqlServer.Create.Identifier hiding (unwrap)
import Database.SqlServer.Create.DataType
import Database.SqlServer.Create.Entity

import Test.QuickCheck
import Text.PrettyPrint hiding (render)

data Parameter = Parameter
  {
    parameterName :: ParameterIdentifier
  , dataType :: Type
  , isOutput :: Bool
  }

instance Arbitrary Parameter where
  arbitrary = Parameter <$> arbitrary <*> arbitrary <*> arbitrary

renderOut :: Bool -> Doc
renderOut True = text "OUTPUT"
renderOut False = empty

renderParameter :: Parameter -> Doc
renderParameter p = renderParameterIdentifier (parameterName p) <+>
                    renderDataType (dataType p) <+> renderOut (isOutput p)

data Procedure = Procedure
  {
    procedureName :: RegularIdentifier
  , parameters :: [Parameter]
  }

instance Arbitrary Procedure where
  arbitrary = Procedure <$> arbitrary <*> arbitrary

-- Generating arbitrary SQL is perhaps a bit complicated.
statementBody :: String
statementBody = "select 1\n"

instance Entity Procedure where
  name = procedureName
  render p = text "CREATE PROCEDURE" <+>
             renderName p $+$
             hcat (punctuate comma (map renderParameter (parameters p))) <+>
             text "AS" $+$
             text statementBody $+$
             text "GO\n"

instance Show Procedure where
  show = show . render