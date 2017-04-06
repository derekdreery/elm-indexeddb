module IndexedDB.Error exposing (ErrorType, Error)

{-| The various errors that can be returned from indexeddb e.g.

 - You may request a version less than the current version
 ...
-}


type ErrorType
    = Abort
    | NotFoundError
    | VersionError
    | NoIndexedDBError
    | ConstraintError


{-| The error type
-}
type alias Error =
    ( ErrorType, String )
