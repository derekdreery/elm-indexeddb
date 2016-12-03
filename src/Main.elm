import Html
import Html.Events as HtmlEvt
import Task
import Json.Encode as JSEnc
import IndexedDB
import IndexedDB.Upgrades as IDBUpgrades
import IndexedDB.Data as IDBData


main = Html.program
  { init = init
  , update = update
  , subscriptions = subscriptions
  , view = view
  }


type alias Model =
  { db : Maybe IndexedDB.Db
  , err : Maybe IndexedDB.Error
  }


init : (Model, Cmd Msg)
init =
  let
    model =
      { db = Nothing
      , err = Nothing
      }
  in
    (model, Cmd.none)


type Msg
  = RequestCreateDatabase String Int
  | DatabaseCreated (Result IndexedDB.Error IndexedDB.Db)
  | RequestDbUpdate IDBData.Transaction
  | DbUpdated (Result IDBData.Error ())


subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none


objectStoreOptions =
  { keyPath = IDBUpgrades.SingleKeyPath "id"
  , autoIncrement = False
  }


objectStoreOptions2 =
  { keyPath = IDBUpgrades.MultiKeyPath ["id", "name"]
  , autoIncrement = False
  }


indexOptions =
  { unique = False
  , multiEntry = False
  }


upgradeDb : Int -> Int -> List IDBUpgrades.Operation
upgradeDb oldVersion newVersion =
  [ IDBUpgrades.AddObjectStore "contact" objectStoreOptions
  , IDBUpgrades.AddObjectStore "test" objectStoreOptions2
  , IDBUpgrades.AddIndex "test" "testIdx" (IDBUpgrades.SingleKeyPath "testKey") indexOptions
  ]


transaction : IDBData.Transaction
transaction =
  let
    contact =
      JSEnc.object
        [ ("id", JSEnc.int 0)
        , ("name", JSEnc.string "Joe Bloggs")
        ]
  in
    [ IDBData.Operation "contact" (IDBData.Add contact Nothing)
    ]


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    RequestCreateDatabase name version ->
      let
        openDb =
          IndexedDB.open name version upgradeDb
      in
        (model, Task.attempt DatabaseCreated openDb)

    DatabaseCreated (Ok db) ->
      ({ model | db = Just db }, Cmd.none)

    RequestDbUpdate transaction ->
      case model.db of
        Just db ->
          let
            updateDb =
              IndexedDB.transaction db transaction
          in
            (model, Task.attempt DbUpdated updateDb)
        Nothing ->
          Debug.crash "error"

    {-DatabaseCreated (Err err) ->-}
    _ ->
      Debug.crash "error"


view : Model -> Html.Html Msg
view model =
  Html.div []
    [ Html.text "Hello world"
    , Html.button
      [ HtmlEvt.onClick (RequestCreateDatabase "test" 1) ]
      [ Html.text "Create database" ]
    , Html.button
      [ HtmlEvt.onClick (RequestDbUpdate transaction) ]
      [ Html.text "Update contacts" ]
    ]
