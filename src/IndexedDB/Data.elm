module IndexedDB.Data
    exposing
        ( Transaction
        , Operation(..)
        , KeyRange(..)
        , Response
        )

{-| This module contains the possible data operations.

# Types

@docs Transaction, Operation, KeyRange, Response
-}

import IndexedDB.Common exposing (StoreName, IndexName)
import Json.Encode exposing (Value)


{-| A database transaction

Either all operations succeed or all operations fail
-}
type alias Transaction =
    List ( String, Operation )


{-| A read or write operation on a store


-}
type Operation
    -- Write
    = Add Value (Maybe Value)
    | Clear
    | Delete KeyRange
    | Put Value (Maybe Value)
    -- Read
    | Get KeyRange
    | GetAll
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
    = UpperBound IsOpen Value
    | LowerBound IsOpen Value
    | Bound IsOpen Value IsOpen Value
    | Only Value


{-| Simple alias to make type KeyRange more readable
-}
type alias IsOpen = Bool


{-| The response to an operation.

Will be `Just val` for certain operations and `Nothing` for others TODO doc
-}
type alias Response =
    Maybe Value
