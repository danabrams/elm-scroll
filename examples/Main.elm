module Main exposing (..)

import Html exposing (Html, div, text)
import Html.Attributes exposing (height, style, width)
import Scroll exposing (Position, scroll)


type alias Model =
    Position


init : ( Model, Cmd msg )
init =
    ( { x = 0, y = 0 }, Cmd.none )


type Msg
    = NoOp
    | ScrollEvent Position


update : Msg -> Model -> ( Model, Cmd msg )
update msg model =
    case msg of
        ScrollEvent position ->
            ( position, Cmd.none )

        _ ->
            ( model, Cmd.none )


view : Model -> Html msg
view model =
    div
        [ style
            [ ( "height", "2500px" )
            , ( "width", "2500px" )
            , ( "background", "linear-gradient(to bottom right, white, yellow)" )
            ]
        ]
        [ div
            [ style
                [ ( "position", "fixed" )
                , ( "display", "inline-block" )
                , ( "left", "200px" )
                , ( "top", "200px" )
                ]
            ]
            [ text <| "Scroll Position (top left pixel): (" ++ toString model.x ++ ", " ++ toString model.y ++ ")" ]
        ]


main : Program Never Model Msg
main =
    Html.program { view = view, update = update, init = init, subscriptions = subscriptions }


subscriptions : Model -> Sub Msg
subscriptions model =
    scroll ScrollEvent
