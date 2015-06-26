{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE GADTs #-}

module Database.SqlServer.Types.Sequence where

import Prelude hiding (cycle)

import Database.SqlServer.Types.Properties (NamedEntity,name)
import Database.SqlServer.Types.Identifiers (RegularIdentifier, renderRegularIdentifier)

import Text.PrettyPrint
import Test.QuickCheck
import Data.DeriveTH
import Control.Monad


data NumericType = TinyInt | SmallInt | Int | BigInt | Decimal | Numeric

renderNumericType :: NumericType -> Doc
renderNumericType TinyInt = text "AS tinyint"
renderNumericType SmallInt = text "AS smallint"
renderNumericType Int = text "AS int"
renderNumericType BigInt = text "AS bigint"
renderNumericType Decimal = text "AS decimal"
renderNumericType Numeric = text "AS numeric"

derive makeArbitrary ''NumericType

data SequenceDefinition = SequenceDefinition
                  {
                    sequenceName :: RegularIdentifier
                  , sequenceType :: Maybe NumericType
                  , startWith    :: Maybe Integer
                  , incrementBy  :: Maybe Integer
                  , minValue     :: Maybe (Maybe Integer)
                  , maxValue     :: Maybe (Maybe Integer)
                  , cycle        :: Maybe Bool
                  , cache        :: Maybe (Maybe Integer)
                  }

instance NamedEntity SequenceDefinition where
  name = sequenceName

renderMinValue :: Maybe Integer -> Doc
renderMinValue Nothing = text "NO MINVALUE"
renderMinValue (Just n) = text "MINVALUE" <+> integer n

renderMaxValue :: Maybe Integer -> Doc
renderMaxValue Nothing = text "NO MAXVALUE"
renderMaxValue (Just n) = text "MAXVALUE" <+> integer n

renderCacheValue :: Maybe Integer -> Doc
renderCacheValue Nothing = text "NO CACHE"
renderCacheValue (Just n) = text "CACHE" <+> integer n

renderSequenceDefinition :: SequenceDefinition -> Doc
renderSequenceDefinition s = text "CREATE SEQUENCE" <+> renderRegularIdentifier (sequenceName s) $+$
                            dataType $+$ startWith' $+$ incrementBy' $+$ minValue' $+$ maxValue' $+$
                            cycle' $+$ cache'
  where
    dataType = maybe empty renderNumericType (sequenceType s)
    startWith' = maybe empty (\x -> text "START WITH" <+> integer x) (startWith s)
    incrementBy' = maybe empty (\x -> text "INCREMENT BY" <+> integer x) (incrementBy s)
    minValue' = maybe empty renderMinValue (minValue s)
    maxValue' = maybe empty renderMaxValue (maxValue s)
    cycle'    = maybe empty (\x -> if x then text "CYCLE" else text "NO CYCLE") (cycle s)
    cache'    = maybe empty renderCacheValue (cache s)



arbitraryValue :: Maybe NumericType -> Gen (Maybe Integer)
arbitraryValue Nothing = arbitraryValue (Just Int)
arbitraryValue (Just TinyInt)  = oneof [liftM Just $ choose (0,255),return Nothing]
arbitraryValue (Just SmallInt) = oneof [liftM Just $ choose (- 32768,32767),return Nothing]
arbitraryValue (Just Int)      = oneof [liftM Just $ choose (- 2147483648,214748367),return Nothing]
arbitraryValue (Just BigInt)   = oneof [liftM Just $ choose (- 9223372036854775808,9223372036854775807),return Nothing]
arbitraryValue (Just Numeric)  = oneof [liftM Just $ arbitrary,return Nothing]
arbitraryValue (Just Decimal)  = oneof [liftM Just $ arbitrary,return Nothing]
  

greaterThanMin :: Maybe Integer -> Maybe Integer -> Bool
greaterThanMin mx my = maybe True id $ liftM2 (>) mx my

lessThanMax :: Maybe Integer -> Maybe Integer -> Bool
lessThanMax mx my = maybe True id $ liftM2 (<) mx my


instance Arbitrary SequenceDefinition where
  arbitrary = do
    nm <- arbitrary
    dataType <- arbitrary
    minV <- arbitraryValue dataType
    maxV <- arbitraryValue dataType `suchThat` (greaterThanMin minV)
    start <- arbitraryValue dataType `suchThat` (greaterThanMin minV) `suchThat` (lessThanMax maxV)
    increment <- arbitraryValue dataType `suchThat` (\x -> maybe True (/= 0) x)
    cyc <- arbitrary
    hasMinValue <- elements [Just, \_ -> Nothing]
    hasMaxValue <- elements [Just, \_ -> Nothing]
    hasChcValue <- elements [Just, \_ -> Nothing]    
    chc <- arbitraryValue dataType
    return $ SequenceDefinition {
        sequenceName = nm
      , sequenceType = dataType
      , startWith = start
      , incrementBy = increment
      , minValue = hasMinValue minV
      , maxValue = hasMaxValue maxV                  
      , cycle = cyc
      , cache = hasChcValue chc
      }

