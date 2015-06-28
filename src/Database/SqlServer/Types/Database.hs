module Database.SqlServer.Types.Database where

import Database.SqlServer.Types.Identifiers (RegularIdentifier,renderRegularIdentifier)
import Database.SqlServer.Types.Table (TableDefinition,renderTableDefinition)
import Database.SqlServer.Types.Properties (validIdentifiers,NamedEntity,name)
import Database.SqlServer.Types.Sequence (SequenceDefinition,renderSequenceDefinition)
import Database.SqlServer.Types.Procedure

import Test.QuickCheck
import Control.Monad
import qualified Data.Set as S

import Text.PrettyPrint

newtype TableDefinitions = TableDefinitions [TableDefinition]

newtype SequenceDefinitions = SequenceDefinitions [SequenceDefinition]

newtype ProcedureDefinitions = ProcedureDefinitions [ProcedureDefinition]

data DatabaseDefinition = DatabaseDefinition
                          {
                            databaseName :: RegularIdentifier
                          , tableDefinitions :: TableDefinitions
                          , sequenceDefinitions :: SequenceDefinitions
                          , procedureDefinitions :: ProcedureDefinitions
                          }

tableNames :: TableDefinitions -> S.Set RegularIdentifier
tableNames (TableDefinitions xs) = names xs

sequenceNames :: SequenceDefinitions -> S.Set RegularIdentifier
sequenceNames (SequenceDefinitions xs) = names xs

names :: NamedEntity a => [a] -> S.Set RegularIdentifier
names xs = S.fromList (map name xs)

renderTableDefinitions :: TableDefinitions -> Doc
renderTableDefinitions (TableDefinitions xs) = vcat (map renderTableDefinition xs)

renderSequenceDefinitions :: SequenceDefinitions -> Doc
renderSequenceDefinitions (SequenceDefinitions xs) = vcat (map renderSequenceDefinition xs)

renderProcedureDefinitions :: ProcedureDefinitions -> Doc
renderProcedureDefinitions (ProcedureDefinitions xs) = vcat (map renderProcedureDefinition xs)

renderDatabaseDefinition :: DatabaseDefinition -> Doc
renderDatabaseDefinition  dd = text "USE master" $+$
                               text "GO" $+$
                               text "CREATE DATABASE" <+> dbName $+$
                               text "GO" $+$
                               text "USE" <+> dbName $+$
                               renderTableDefinitions (tableDefinitions dd) $+$
                               renderSequenceDefinitions (sequenceDefinitions dd) $+$
                               renderProcedureDefinitions (procedureDefinitions dd)
  where
    dbName = renderRegularIdentifier (databaseName dd)

instance Arbitrary TableDefinitions where
  arbitrary = liftM TableDefinitions $ (listOf1 arbitrary `suchThat` validIdentifiers)

usesUnreservedNames :: NamedEntity a => S.Set RegularIdentifier -> [a] -> Bool
usesUnreservedNames reserved = \x -> not $ any (\a -> (name a) `S.member` reserved) x

makeArbitraryProcs :: S.Set RegularIdentifier -> Gen [ProcedureDefinition]
makeArbitraryProcs reserved = listOf arbitrary `suchThat` (usesUnreservedNames reserved) `suchThat` validIdentifiers

makeArbitrarySeqs :: S.Set RegularIdentifier -> Gen [SequenceDefinition]
makeArbitrarySeqs reserved = listOf arbitrary `suchThat` (usesUnreservedNames reserved) `suchThat` validIdentifiers

instance Arbitrary DatabaseDefinition where
  arbitrary = do
    dbName <- arbitrary
    tables <- arbitrary
    sequences <- liftM SequenceDefinitions $ makeArbitrarySeqs (tableNames tables)
    procs <- liftM ProcedureDefinitions $ makeArbitraryProcs ((tableNames tables) `S.union` (sequenceNames sequences))
    return $ DatabaseDefinition dbName tables sequences procs
   
-- Note, for example, this doesn't guarantee unique database names
dumpExamples :: Int -> FilePath -> IO ()
dumpExamples m p = do
  x <- generate (sequence [resize n (arbitrary :: Gen DatabaseDefinition) | n <- [0..m] ])
  writeFile p (unlines $ map (render . renderDatabaseDefinition) x)
