effect module Scroll where { subscription = MySub } exposing (..)

{-| This library lets you listen to scroll events. It'll help you create pages
that respond to scrolling, such as a page that has a header that becomes sticky when
you start scrolling.

It uses no native code, other than the Native code provide by Elm-Lang.


# Scroll Position

@docs Position, position


# Subscriptions

@docs scroll

-}

import Dict
import Dom.LowLevel as Dom
import Json.Decode as Json
import Process
import Task exposing (Task)


-- POSITIONS


{-| The Scroll Position of the window. _x_ is scrollX, _y_ is scrollY
-}
type alias Position =
    { x : Int
    , y : Int
    }


{-| The decoder used to extract a `Position` from a JavaScript scroll event.
-}
position : Json.Decoder Position
position =
    Json.map2 Position
        (Json.at [ "target", "defaultView", "scrollX" ] Json.int)
        (Json.at [ "target", "defaultView", "scrollY" ] Json.int)



-- SCROLL EVENTS


{-| -}
scroll : (Position -> msg) -> Sub msg
scroll tagger =
    subscription (MySub "scroll" tagger)



-- SUBSCRIPTIONS


type MySub msg
    = MySub String (Position -> msg)


subMap : (a -> b) -> MySub a -> MySub b
subMap func (MySub category tagger) =
    MySub category (tagger >> func)



-- EFFECT MANAGER STATE


type alias State msg =
    Dict.Dict String (Watcher msg)


type alias Watcher msg =
    { taggers : List (Position -> msg)
    , pid : Process.Id
    }



-- CATEGORIZE SUBSCRIPTIONS


type alias SubDict msg =
    Dict.Dict String (List (Position -> msg))


categorize : List (MySub msg) -> SubDict msg
categorize subs =
    categorizeHelp subs Dict.empty


categorizeHelp : List (MySub msg) -> SubDict msg -> SubDict msg
categorizeHelp subs subDict =
    case subs of
        [] ->
            subDict

        (MySub category tagger) :: rest ->
            categorizeHelp rest <|
                Dict.update category (categorizeHelpHelp tagger) subDict


categorizeHelpHelp : a -> Maybe (List a) -> Maybe (List a)
categorizeHelpHelp value maybeValues =
    case maybeValues of
        Nothing ->
            Just [ value ]

        Just values ->
            Just (value :: values)



-- EFFECT MANAGER


init : Task Never (State msg)
init =
    Task.succeed Dict.empty


type alias Msg =
    { category : String
    , position : Position
    }


(&>) t1 t2 =
    Task.andThen (\_ -> t2) t1


onEffects : Platform.Router msg Msg -> List (MySub msg) -> State msg -> Task Never (State msg)
onEffects router newSubs oldState =
    let
        leftStep category { pid } task =
            Process.kill pid &> task

        bothStep category { pid } taggers task =
            task
                |> Task.andThen (\state -> Task.succeed (Dict.insert category (Watcher taggers pid) state))

        rightStep category taggers task =
            let
                tracker =
                    Dom.onWindow category position (Platform.sendToSelf router << Msg category)
            in
            task
                |> Task.andThen
                    (\state ->
                        Process.spawn tracker
                            |> Task.andThen (\pid -> Task.succeed (Dict.insert category (Watcher taggers pid) state))
                    )
    in
    Dict.merge
        leftStep
        bothStep
        rightStep
        oldState
        (categorize newSubs)
        (Task.succeed Dict.empty)


onSelfMsg : Platform.Router msg Msg -> Msg -> State msg -> Task Never (State msg)
onSelfMsg router { category, position } state =
    case Dict.get category state of
        Nothing ->
            Task.succeed state

        Just { taggers } ->
            let
                send tagger =
                    Platform.sendToApp router (tagger position)
            in
            Task.sequence (List.map send taggers)
                &> Task.succeed state
