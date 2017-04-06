module IndexedDB.Upgrades
    exposing
        ( Operation(..)
        , ObjectStoreOptions
        , KeyPath(..)
        )

{-| This module contains the possible upgrade operations to a database.

It is used when creating an upgrade function `Int -> Int -> List Operation`

# Types

@docs Operation, ObjectStoreOptions, KeyPath
-}

import IndexedDB.Common exposing (StoreName, IndexName)


{-| A change to a database
-}
type Operation
    = AddObjectStore StoreName ObjectStoreOptions
    | DeleteObjectStore StoreName
    | AddIndex StoreName IndexName KeyPath IndexOptions
    | DeleteIndex StoreName IndexName


{-| Possible options when creating an object store
-}
type alias ObjectStoreOptions =
    { keyPath : KeyPath
    , autoIncrement : Bool
    }


{-| Possible options when creating an index
-}
type alias IndexOptions =
    { unique : Bool
    , multiEntry : Bool
    }


{-| Possible types of keyPath for an object store/index
-}
type KeyPath
    = NoKeyPath
    | SingleKeyPath String
    | MultiKeyPath (List String)
