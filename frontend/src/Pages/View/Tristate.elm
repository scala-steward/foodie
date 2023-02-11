module Pages.View.Tristate exposing (Status(..), Tristate, createError, createInitial, createMain, fold, foldMain, fromInitToMain, lenses, mapMain, toError, view)

import Configuration exposing (Configuration)
import Html exposing (Html, div, label, td, text, tr)
import Maybe.Extra
import Monocle.Optional exposing (Optional)
import Pages.Util.Links as Links
import Pages.Util.Style as Style
import Pages.Util.ViewUtil as ViewUtil exposing (Page(..))
import Util.HttpUtil as HttpUtil exposing (Error)
import Util.Initialization exposing (ErrorExplanation)


type alias Tristate main initial =
    { configuration : Configuration
    , status : Status main initial
    }


type Status main initial
    = Initial initial
    | Main main
    | Error ErrorExplanation


createInitial : Configuration -> initial -> Tristate main initial
createInitial configuration =
    Initial >> Tristate configuration


createMain : Configuration -> main -> Tristate main initial
createMain configuration =
    Main >> Tristate configuration


createError : Configuration -> ErrorExplanation -> Tristate main initial
createError configuration =
    Error >> Tristate configuration


fold :
    { onInitial : initial -> a
    , onMain : main -> a
    , onError : ErrorExplanation -> a
    }
    -> Tristate main initial
    -> a
fold fs t =
    case t.status of
        Initial initial ->
            fs.onInitial initial

        Main main ->
            fs.onMain main

        Error errorExplanation ->
            fs.onError errorExplanation


mapMain : (main -> main) -> Tristate main initial -> Tristate main initial
mapMain f t =
    fold
        { onInitial = always t
        , onMain = f >> Main >> Tristate t.configuration
        , onError = always t
        }
        t


foldMain : c -> (main -> c) -> Tristate main initial -> c
foldMain c f =
    fold
        { onInitial = always c
        , onMain = f
        , onError = always c
        }


lenses :
    { initial : Optional (Tristate main initial) initial
    , main : Optional (Tristate main initial) main
    , error : Optional (Tristate main initial) ErrorExplanation
    }
lenses =
    { initial =
        Optional asInitial
            (\b a ->
                case a.status of
                    Initial _ ->
                        Initial b |> Tristate a.configuration

                    _ ->
                        a
            )
    , main =
        Optional asMain
            (\b a ->
                case a.status of
                    Main _ ->
                        Main b |> Tristate a.configuration

                    _ ->
                        a
            )
    , error =
        Optional asError
            (\b a ->
                case a.status of
                    Error _ ->
                        Error b |> Tristate a.configuration

                    _ ->
                        a
            )
    }


asInitial : Tristate main initial -> Maybe initial
asInitial t =
    case t.status of
        Initial initial ->
            Just initial

        _ ->
            Nothing


asMain : Tristate main initial -> Maybe main
asMain t =
    case t.status of
        Main main ->
            Just main

        _ ->
            Nothing


asError : Tristate main initial -> Maybe ErrorExplanation
asError t =
    case t.status of
        Error error ->
            Just error

        _ ->
            Nothing


fromInitToMain : (initial -> Maybe main) -> Tristate main initial -> Tristate main initial
fromInitToMain with t =
    t
        |> asInitial
        |> Maybe.andThen with
        |> Maybe.Extra.unwrap t (Main >> Tristate t.configuration)


toError : Configuration -> HttpUtil.Error -> Tristate main initial
toError configuration =
    HttpUtil.errorToExplanation
        >> createError configuration


view :
    { mainPageURLForLoginSuggestion : Maybe String
    , viewMain : main -> Html msg
    }
    -> Tristate main initial
    -> Html msg
view ps t =
    case t.status of
        Initial _ ->
            div [] [ Links.loadingSymbol ]

        Main main ->
            ps.viewMain main

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
                    ps.mainPageURLForLoginSuggestion
                        |> Maybe.Extra.unwrap []
                            (\address ->
                                [ tr []
                                    [ td []
                                        [ ViewUtil.navigationToPageButton
                                            { page = Login
                                            , mainPageURL = address
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
