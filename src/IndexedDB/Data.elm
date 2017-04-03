module IndexedDB.Data exposing
  ( Transaction
  , Operation(..)
  , KeyRange(..)
  , ErrorType
  , Error
  , Response
  )

{-| This module contains the possible data operations.

# Types

@docs Transaction, Operation, KeyRange, ErrorType,
      Error, Response
-}

import IndexedDB.Common exposing (StoreName, IndexName)
import Json.Encode exposing (Value)


{-| A database transaction
-}
type Transaction msg
  = Update UpdateList
  | Fetch UpdateList FetchOp (Value -> msg)


{-{-| A non-upgrade operation on a store

# Variants
-}
type Operation
  = Update UpdateOp
  | Fetch FetchOp
-}


type UpdateOp
  = Add Value (Maybe Value)
  | Clear
  | Delete KeyRange
  | Put Value (Maybe Value)


type FetchOperation
  = Get KeyRange
  | Count (Maybe KeyRange)
  -- TODO Index
  -- TODO OpenCursor
  -- TODO OpenKeyCursor


{-| A range of keys. Used in object store operations

In all cases, bool means exclusive greater-than or less-than (i.e. not equal
to)

In `Bound`, the first value is the lower bound and the last value is the upper
bound
-}
type KeyRange
  = UpperBound Value Bool
  | LowerBound Value Bool
  | Bound Value Value Bool Bool
  | Only Value


{-| The various errors that can be returned from indexeddb e.g.

 - You may request a version less than the current version
 ...
-}
type ErrorType
  = Abort
  | NotFoundError


{-| The error type
-}
type alias Error = ErrorType String


{-| The response to an operation.

Will be `Just val` for certain operations and `Nothing` for others TODO doc
-}
type alias Response = Maybe Value


{-|
-}
type alias UpdateList = List (String, UpdateOp)
