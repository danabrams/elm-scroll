# elm-scroll
An Elm Scroll package with no ports.

**Note: This is a rough, rough prototype. I hacked this together on a flight in less than three hours.**

### How to use

1) Add a subscription to the scroll function: 

``` main : Program Never Model Msg
main =
    Html.program { view = view, update = update, init = init, subscriptions = subscriptions }


subscriptions : Model -> Sub Msg
subscriptions model =
    scroll ScrollEvent 
```

2) Create a message that takes a Position type:

``` type Msg
    = NoOp
    | ScrollEvent Position 
```

I am looking for feedback. Again, this is a rough prototype and there are **lots** of improvements to be made.