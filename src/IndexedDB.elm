module IndexedDB exposing (Error, Db, open, transaction)
{-| This library enables access to [IndexedDB] in pure elm.

[IndexedDB]: https://developer.mozilla.org/en-US/docs/Web/API/IndexedDB_API/Using_IndexedDB

# Types

@docs Error, Db

# Functions

@docs open, transaction

-}


import Native.IndexedDB
import IndexedDB.Upgrades as Upgrades
import IndexedDB.Data as Data
import Task exposing (Task)


{-| The various errors that can be returned from indexeddb e.g.

 - You may request a version less than the current version
 ...
-}
type Error
  = VersionError String
  | NoIndexedDBError String


{-| An indexedDB database
-}
type alias Db = Int


{-| Open an indexedDB database.

The database will be created if it does not already exist.
-}
open : String -> Int -> (Int -> Int -> List Upgrades.Operation) -> Task Error Db
open =
  Native.IndexedDB.open


{-| Execute a database transaction.
-}
transaction : Db -> Data.Transaction -> Task Data.Error (List Data.Response)
transaction =
  Native.IndexedDB.transaction


{-{-| Execute a single operation

Convenience method
-}
operation : Db -> Data.Operation -> Task Data.Error Data.Response -}
