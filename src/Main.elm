import Html
import Html.Events as HtmlEvt
import Task
import Json.Decode as JSDec
import Json.Encode as JSEnc
import Json.Decode.Pipeline as P
import IndexedDB
import IndexedDB.Upgrades as IDBUpgrades
import IndexedDB.Data as IDBData


main = Html.program
  { init = init
  , update = update
  , subscriptions = subscriptions
  , view = view
  }


type alias Contact =
  { id : Int
  , name : String
  }


contactDecoder : JSDec.Decoder Contact
contactDecoder =
  P.decode Contact
    |> P.required "id" JSDec.int
    |> P.required "name" JSDec.string


type alias Model =
  { db : Maybe IndexedDB.Db
  , err : Maybe IndexedDB.Error
  , contacts: List Contact
  }


init : (Model, Cmd Msg)
init =
  let
    model =
      { db = Nothing
      , err = Nothing
      , contacts = []
      }
  in
    (model, Cmd.none)


-- UPDATE


type Msg
  = RequestCreateDatabase
  | DatabaseCreated (Result IndexedDB.Error IndexedDB.Db)
  | RequestAddContact
  | ContactsAdded (Result IDBData.Error (List IDBData.Response))
  | RequestGetContacts
  | GotContacts (Result IDBData.Error (List IDBData.Response))


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


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of

    -- create database
    RequestCreateDatabase ->
      let
        openDb =
          IndexedDB.open "test" 1 upgradeDb
      in
        (model, Task.attempt DatabaseCreated openDb)

    DatabaseCreated (Ok db) ->
      ({ model | db = Just db }, Cmd.none)

    DatabaseCreated (Err err) ->
      let
        err2 = Debug.log "failed to create db" err
      in
        (model, Cmd.none)

    -- create tables
    RequestAddContact ->
      case model.db of
        Just db ->
          let
            contact =
              JSEnc.object
                [ ("id", JSEnc.int 0)
                , ("name", JSEnc.string "Joe Bloggs")
                ]
            trans =
              [ IDBData.Operation "contact" (IDBData.Add contact Nothing)
              ]
            addContact =
              IndexedDB.transaction db trans
          in
            (model, Task.attempt ContactsAdded addContact)
        Nothing ->
          (model, Cmd.none)

    ContactsAdded (Ok a) ->
      (model, Cmd.none)


    -- fetch contacts
    RequestGetContacts ->
      case model.db of
        Just db ->
          let
            op =
              JSEnc.int 0
              |> IDBData.Only -- make keyRange
              |> IDBData.Get -- make operation
            transaction =
              [ IDBData.Operation "contact" op
              ]
            getContacts =
              IndexedDB.transaction db transaction
          in
            (model, Task.attempt GotContacts getContacts)
        Nothing ->
          (model, Cmd.none)

    GotContacts (Ok result) ->
      let
        responses =
          case result of
            Just a ->
              a

            Nothing ->
              Debug.crash "error"

        contacts =
          case (List.head responses) of
            Just a ->
              a

            Nothing ->
              Debug.crash "error"

        decodedContacts = JSDec.decodeValue (JSDec.list contactDecoder) (List.head contacts)
      in
        ({ model | contacts = decodedContacts }, Cmd.none)

    {-DatabaseCreated (Err err) ->-}
    _ ->
      Debug.crash "error"


-- VIEW


view : Model -> Html.Html Msg
view model =
  Html.div []
    [ Html.text "Hello world"
    , Html.button
      [ HtmlEvt.onClick (RequestCreateDatabase) ]
      [ Html.text "Create database" ]
    , Html.button
      [ HtmlEvt.onClick (RequestAddContact) ]
      [ Html.text "Update contacts" ]
    , Html.button
      [ HtmlEvt.onClick (RequestGetContacts) ]
      [ Html.text "Get contacts" ]
    ]
