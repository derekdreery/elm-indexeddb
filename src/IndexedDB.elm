module IndexedDB exposing (Db, open, transaction, request)

{-| This library enables access to [IndexedDB] in pure elm.

[IndexedDB]: https://developer.mozilla.org/en-US/docs/Web/API/IndexedDB_API/Using_IndexedDB

# Types

@docs Db

# Functions

@docs open, transaction, request

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


{-| Execute a single request

Convenience method, executing a transaction with a single request
-}
request : Db -> String -> Data.Operation -> Task Error (Maybe Value)
request db objStore op =
    let
        transRes =
            transaction db [( objStore, op )]
    in
        Task.map (\x -> List.head x |> Maybe.andThen identity) transRes

