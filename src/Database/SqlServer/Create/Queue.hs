module Database.SqlServer.Create.Queue
       (
         Queue
       ) where

import Database.SqlServer.Create.Identifier hiding (unwrap)
import Database.SqlServer.Create.Procedure
import Database.SqlServer.Create.Entity

import Test.QuickCheck
import Data.Word (Word16)
import Text.PrettyPrint hiding (render)
import Data.Maybe (isJust)

-- TODO username support
data ExecuteAs = Self
               | Owner

-- Activation procedures can not have any parameters
newtype ZeroParamProc = ZeroParamProc { unwrap :: Procedure }

instance Arbitrary ZeroParamProc where
  arbitrary = do
    proc <- arbitrary :: Gen Procedure
    return $ ZeroParamProc (proc { parameters = [] })

data Activation = Activation
    {
      maxQueueReaders :: Word16
    , executeAs :: ExecuteAs
    , procedure :: ZeroParamProc
    }

data Queue = Queue
    {
      queueName :: RegularIdentifier
    , queueStatus :: Maybe Bool
    , retention :: Maybe Bool
    , activation :: Maybe Activation
    , poisonMessageHandling :: Maybe Bool
    }

instance Arbitrary ExecuteAs where
  arbitrary = elements [Self, Owner]

instance Arbitrary Queue where
  arbitrary = Queue <$>
              arbitrary <*>
              arbitrary <*>
              arbitrary <*>
              arbitrary <*>
              arbitrary

instance Arbitrary Activation where
  arbitrary = do
    r <- choose (0, 32767)
    x <- arbitrary
    y <- arbitrary
    return $ Activation r x y

anySpecified :: Queue -> Bool
anySpecified q = isJust (queueStatus q) || isJust (retention q) ||
                 isJust (activation q) || isJust (poisonMessageHandling q)

renderStatus :: Bool -> Doc
renderStatus True = text "STATUS = ON"
renderStatus False = text "STATUS = OFF"

renderRetention :: Bool -> Doc
renderRetention True = text "RETENTION = ON"
renderRetention False = text "RETENTION = OFF"

renderPoisonMessageHandling :: Bool -> Doc
renderPoisonMessageHandling True = text "POISON_MESSAGE_HANDLING(STATUS = ON)"
renderPoisonMessageHandling False = text "POISON_MESSAGE_HANDLING(STATUS = OFF)"

renderMaxQueueReaders :: Word16 -> Doc
renderMaxQueueReaders t = text "MAX_QUEUE_READERS = " <> int (fromIntegral t)

renderExecuteAs :: ExecuteAs -> Doc
renderExecuteAs Self = text "EXECUTE AS SELF"
renderExecuteAs Owner = text "EXECUTE AS OWNER"

renderProc :: Activation -> Doc
renderProc a = render (unwrap $ procedure a)

renderProcedureName :: Procedure -> Doc
renderProcedureName a = text "PROCEDURE_NAME =" <+>
                        renderRegularIdentifier (procedureName a)

renderActivation :: Activation -> Doc
renderActivation a = text "ACTIVATION(" <+>
                     hcat (punctuate comma $ filter (/= empty)
                           [ renderMaxQueueReaders (maxQueueReaders a)
                           , renderExecuteAs (executeAs a)
                           , renderProcedureName (unwrap $ procedure a)
                           ]) <+> text ")"

instance Entity Queue where
  name = queueName
  render q = maybe empty renderProc (activation q) $+$
            text "CREATE QUEUE" <+> renderRegularIdentifier (queueName q) <+>
            options $+$ text "GO\n"
    where
      options
        | not $ anySpecified q = empty
        | otherwise =
          text "WITH" <+>
          hcat (punctuate comma $ filter (/= empty)
                [ maybe empty renderStatus (queueStatus q)
                , maybe empty renderRetention (retention q)
                , maybe empty renderActivation (activation q)
                , maybe empty renderPoisonMessageHandling
                  (poisonMessageHandling q)])
