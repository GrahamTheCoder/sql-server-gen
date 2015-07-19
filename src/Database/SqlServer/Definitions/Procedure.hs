{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE GADTs #-}

module Database.SqlServer.Definitions.Procedure
       (
         Procedure,
         parameters,
         procedureName
       ) where

import Database.SqlServer.Definitions.Identifier hiding (unwrap)
import Database.SqlServer.Definitions.DataType
import Database.SqlServer.Definitions.Entity

import Test.QuickCheck
import Data.DeriveTH
import Text.PrettyPrint

data Parameter = Parameter
  {
    parameterName :: ParameterIdentifier
  , dataType      :: Type
  , isOutput      :: Bool
  }

derive makeArbitrary ''Parameter

renderOut :: Bool -> Doc
renderOut True = text "OUTPUT"
renderOut False = empty

renderParameter :: Parameter -> Doc
renderParameter p = renderParameterIdentifier (parameterName p) <+> renderDataType (dataType p) <+> renderOut (isOutput p)

data Procedure = Procedure
  {
    procedureName :: RegularIdentifier
  , parameters    :: [Parameter]
  }

derive makeArbitrary ''Procedure

-- Generating arbitrary SQL is perhaps a bit complicated.
statementBody :: String
statementBody = "select 1\n"

instance Entity Procedure where
  toDoc p = text "CREATE PROCEDURE" <+> renderRegularIdentifier (procedureName p) $+$
                              hcat (punctuate comma (map renderParameter (parameters p))) <+> text "AS" $+$
                              text statementBody $+$
                              text "GO"
                              
