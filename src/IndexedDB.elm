module IndexedDB exposing (Db, open, transaction)

{-| This library enables access to [IndexedDB] in pure elm.

[IndexedDB]: https://developer.mozilla.org/en-US/docs/Web/API/IndexedDB_API/Using_IndexedDB

# Types

@docs Db

# Functions

@docs open, transaction

-}

import Native.IndexedDB
import IndexedDB.Upgrades as Upgrades
import IndexedDB.Data as Data
import IndexedDB.Error exposing (ErrorType, Error)
import Task exposing (Task)
import Json.Encode exposing (Value)


{-| An indexedDB database

An *opaque type* that can only be used in functions from this library.
-}
type Db
    = Db


{-| Open an indexedDB database.

The database will be created if it does not already exist.
-}
open : String -> Int -> (Int -> Int -> List Upgrades.Operation) -> Task Error Db
open =
    Native.IndexedDB.open


{-| Execute a database transaction.
-}
transaction : Db -> Data.Transaction -> Task Error (List (Maybe Value))
transaction =
    Native.IndexedDB.transaction



{--
{-| Execute a single operation

Convenience method
-}
operation : Db -> Data.Operation -> Task Data.Error Data.Response
--}
