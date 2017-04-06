module Main exposing (..)

import Html
import Html.Attributes as Attr
import Html.Events as HtmlEvt
import Task
import Json.Decode as JSDec
import Json.Encode as JSEnc
import Json.Decode.Pipeline as P
import IndexedDB
import IndexedDB.Upgrades as IDBUpgrades
import IndexedDB.Data as IDBData
import IndexedDB.Error exposing (Error)


main =
    Html.program
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


type alias Contact =
    { name : String
    }


contactDecoder : JSDec.Decoder Contact
contactDecoder =
    P.decode Contact
        --|> P.required "id" JSDec.int
        |> P.required "name" JSDec.string


type alias Model =
    { db : Maybe IndexedDB.Db
    , err : Maybe Error
    , contacts : List Contact
    , newContact : String
    }


init : ( Model, Cmd Msg )
init =
    let
        model =
            { db = Nothing
            , err = Nothing
            , contacts = []
            , newContact = ""
            }
    in
        ( model, Cmd.none )



-- UPDATE


type Msg
    = RequestCreateDatabase
    | DatabaseCreated (Result Error IndexedDB.Db)
    | RequestAddContact
    | ContactsAdded (Result Error (List IDBData.Response))
    | RequestGetContacts
    | GotContacts (Result Error (List IDBData.Response))
    | ChangeNewContact String


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


objectStoreOptions =
    { keyPath = IDBUpgrades.SingleKeyPath "name"
    , autoIncrement = False
    }


objectStoreOptions2 =
    { keyPath = IDBUpgrades.MultiKeyPath [ "id", "name" ]
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


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        -- create database
        RequestCreateDatabase ->
            let
                openDb =
                    IndexedDB.open "test" 1 upgradeDb
            in
                ( model, Task.attempt DatabaseCreated openDb )

        DatabaseCreated (Ok db) ->
            ( { model | db = Just db }, Cmd.none )

        DatabaseCreated (Err e) ->
            ( { model | err = Just e }, Cmd.none )

        -- create tables
        RequestAddContact ->
            case model.db of
                Just db ->
                    let
                        contact =
                            JSEnc.object
                                [ ( "name", JSEnc.string model.newContact )
                                ]

                        trans =
                            [ ( "contact", IDBData.Add contact Nothing )
                            ]

                        addContact =
                            IndexedDB.transaction db trans
                    in
                        ( model, Task.attempt ContactsAdded addContact )

                Nothing ->
                    ( Debug.log "Error: db not instantiated" model, Cmd.none )

        ContactsAdded (Ok a) ->
            ( model, Cmd.none )

        ContactsAdded (Err e) ->
            let
                etmp = Debug.log "Error" e
            in
                ( model, Cmd.none )

        -- fetch contacts
        RequestGetContacts ->
            case model.db of
                Just db ->
                    let
                        op =
                            IDBData.GetAll

                        -- make operation
                        transaction =
                            [ ( "contact", op )
                            ]

                        getContacts =
                            IndexedDB.transaction db transaction
                    in
                        ( model, Task.attempt GotContacts getContacts )

                Nothing ->
                    ( Debug.log "Error: db not instantiated" model, Cmd.none )

        GotContacts (Ok result) ->
            let
                rtmp =
                    Debug.log "Results" result
                decoder =
                    JSDec.decodeValue (JSDec.list contactDecoder)

                contacts =
                    result
                        |> List.head
                        |> Maybe.andThen identity -- (Maybe (Maybe a) -> Maybe a)
                        |> Result.fromMaybe "error fetching results"
                        |> Result.andThen decoder

            in
                case contacts of
                    Ok contacts_ ->
                        ( { model | contacts = contacts_ }, Cmd.none )

                    Err e ->
                        let
                            etmp =
                                Debug.log "Error" e
                        in
                            ( model, Cmd.none )

        {- DatabaseCreated (Err err) -> -}
        GotContacts (Err e) ->
            let
                etmp = Debug.log "Error" e
            in
               ( model, Cmd.none )

        ChangeNewContact val ->
            ( { model | newContact = val }, Cmd.none )



-- VIEW


view : Model -> Html.Html Msg
view model =
    Html.div []
        [ Html.h1 [] [ Html.text "Example IndexedDB App" ]
        , Html.div []
            [ Html.button
                [ HtmlEvt.onClick (RequestCreateDatabase) ]
                [ Html.text "Create database" ]
            , Html.button
                [ HtmlEvt.onClick (RequestGetContacts) ]
                [ Html.text "Get contacts" ]
            ]
        , Html.div []
            [ Html.label [] [ Html.text "New Contact" ]
            , Html.input
                [ Attr.value model.newContact
                , HtmlEvt.onInput ChangeNewContact
                ]
                []
            , Html.button
                [ HtmlEvt.onClick (RequestAddContact) ]
                [ Html.text "Add new contact" ]
            ]
        , Html.h1 [] [ Html.text "Contacts" ]
        , Html.div []
            (List.map
                (\c ->
                    (Html.div []
                        [ Html.text (toString c.name)
                        ]
                    )
                )
                model.contacts
            )
        ]



-- HELPER


getError : Model -> String
getError model =
    case Debug.log "Error" model.err of
        Just ( type_, msg ) ->
            msg

        Nothing ->
            ""
