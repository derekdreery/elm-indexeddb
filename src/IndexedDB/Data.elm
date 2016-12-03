module IndexedDB.Data exposing
  ( Transaction
  , Operation(..)
  , OperationType(..)
  , KeyOrRange
  , KeyRange
  , ErrorType
  , Error
  )

{-| This module contains the possible data operations.

# Types

@docs Transaction, Operation, OperationType, KeyRange, KeyOrRange, ErrorType,
      Error
-}

import IndexedDB.Common exposing (StoreName, IndexName)
import Json.Encode exposing (Value)


{-| A database transaction
-}
type alias Transaction = List Operation


{-| A non-upgrade operation on a store
-}
type Operation = Operation StoreName OperationType


{-| An operation type. It's variants are:
-}
type OperationType
  -- A value to store and a key when using out-of-object keys
  = Add Value (Maybe Value)
  -- Remove all objects
  | Clear
  -- Delete all objects in range
  | Delete KeyOrRange
  -- Get the 'first' object in range or object with key
  | Get KeyOrRange
  -- Get the 'first' key in range or returns itself if key exists
  --| GetKey KeyOrRange
  -- Get all objects, optionally filter by keyrange or limit # of records
  --| GetAll (Maybe KeyOrRange) (Maybe Int)
  -- As above, but fetching keys
  --| GetAllKeys (Maybe KeyOrRange) (Maybe Int)
  -- Update object with new value (provide a key if using out-of-
  | Put Value (Maybe Value)
  -- Count number of records
  | Count
  -- TODO Index
  -- TODO OpenCursor
  -- TODO OpenKeyCursor


{-| A range of keys. Used in object store operations
-}
type KeyRange
  = UpperBound Value Bool
  | LowerBound Value Bool
  | Bound Value Value Bool Bool
  | Only Value


{-| A key or key range
-}
type KeyOrRange
  = Key Value
  | Range KeyRange


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


