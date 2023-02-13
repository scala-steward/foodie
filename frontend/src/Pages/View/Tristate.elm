module Pages.View.Tristate exposing (Model, Status(..), createError, createInitial, createMain, fold, foldMain, fromInitToMain, lenses, mapInitial, mapMain, toError, view)

import Configuration exposing (Configuration)
import Html exposing (Html, div, label, td, text, tr)
import Maybe.Extra
import Monocle.Optional exposing (Optional)
import Pages.Util.Links as Links
import Pages.Util.Style as Style
import Pages.Util.ViewUtil as ViewUtil exposing (Page(..))
import Util.HttpUtil as HttpUtil exposing (Error)
import Util.Initialization exposing (ErrorExplanation)


type alias Model main initial =
    { configuration : Configuration
    , status : Status main initial
    }


type Status main initial
    = Initial initial
    | Main main
    | Error ErrorExplanation


createInitial : Configuration -> initial -> Model main initial
createInitial configuration =
    Initial >> Model configuration


createMain : Configuration -> main -> Model main initial
createMain configuration =
    Main >> Model configuration


createError : Configuration -> ErrorExplanation -> Model main initial
createError configuration =
    Error >> Model configuration


fold :
    { onInitial : initial -> a
    , onMain : main -> a
    , onError : ErrorExplanation -> a
    }
    -> Model main initial
    -> a
fold fs t =
    case t.status of
        Initial initial ->
            fs.onInitial initial

        Main main ->
            fs.onMain main

        Error errorExplanation ->
            fs.onError errorExplanation


mapMain : (main -> main) -> Model main initial -> Model main initial
mapMain f t =
    fold
        { onInitial = always t
        , onMain = f >> createMain t.configuration
        , onError = always t
        }
        t


mapInitial : (initial -> initial) -> Model main initial -> Model main initial
mapInitial f t =
    fold
        { onInitial = f >> createInitial t.configuration
        , onMain = always t
        , onError = always t
        }
        t


foldMain : c -> (main -> c) -> Model main initial -> c
foldMain c f =
    fold
        { onInitial = always c
        , onMain = f
        , onError = always c
        }


lenses :
    { initial : Optional (Model main initial) initial
    , main : Optional (Model main initial) main
    , error : Optional (Model main initial) ErrorExplanation
    }
lenses =
    { initial =
        Optional asInitial
            (\b a ->
                case a.status of
                    Initial _ ->
                        Initial b |> Model a.configuration

                    _ ->
                        a
            )
    , main =
        Optional asMain
            (\b a ->
                case a.status of
                    Main _ ->
                        Main b |> Model a.configuration

                    _ ->
                        a
            )
    , error =
        Optional asError
            (\b a ->
                case a.status of
                    Error _ ->
                        Error b |> Model a.configuration

                    _ ->
                        a
            )
    }


asInitial : Model main initial -> Maybe initial
asInitial t =
    case t.status of
        Initial initial ->
            Just initial

        _ ->
            Nothing


asMain : Model main initial -> Maybe main
asMain t =
    case t.status of
        Main main ->
            Just main

        _ ->
            Nothing


asError : Model main initial -> Maybe ErrorExplanation
asError t =
    case t.status of
        Error error ->
            Just error

        _ ->
            Nothing


fromInitToMain : (initial -> Maybe main) -> Model main initial -> Model main initial
fromInitToMain with t =
    t
        |> asInitial
        |> Maybe.andThen with
        |> Maybe.Extra.unwrap t (Main >> Model t.configuration)


toError : Configuration -> HttpUtil.Error -> Model main initial
toError configuration =
    HttpUtil.errorToExplanation
        >> createError configuration


view :
    { showLoginRedirect : Bool
    , viewMain : Configuration -> main -> Html msg
    }
    -> Model main initial
    -> Html msg
view ps t =
    case t.status of
        Initial _ ->
            div [] [ Links.loadingSymbol ]

        Main main ->
            ps.viewMain t.configuration main

        Error errorExplanation ->
            let
                solutionBlock =
                    if errorExplanation.possibleSolution |> String.isEmpty then
                        []

                    else
                        [ td [] [ label [] [ text "Try the following:" ] ]
                        , td [] [ label [] [ text <| errorExplanation.possibleSolution ] ]
                        ]

                redirectRow =
                    t.configuration
                        |> Just
                        |> Maybe.Extra.filter (always ps.showLoginRedirect)
                        |> Maybe.Extra.unwrap []
                            (\configuration ->
                                [ tr []
                                    [ td []
                                        [ ViewUtil.navigationToPageButton
                                            { page = Login
                                            , mainPageURL = configuration.mainPageURL
                                            , currentPage = Nothing
                                            }
                                        ]
                                    ]
                                ]
                            )

                reloadRow =
                    [ tr []
                        [ td []
                            [ Links.linkButton
                                { url = "."
                                , attributes = []
                                , children = [ text "Reload" ]
                                }
                            ]
                        ]
                    ]
                        |> List.filter (always errorExplanation.suggestReload)
            in
            div [ Style.ids.error ]
                ([ tr []
                    [ td [] [ label [] [ text "An error occurred:" ] ]
                    , td [] [ label [] [ text <| errorExplanation.cause ] ]
                    ]
                 , tr [] solutionBlock
                 ]
                    ++ redirectRow
                    ++ reloadRow
                )
