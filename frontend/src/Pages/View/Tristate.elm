module Pages.View.Tristate exposing (Tristate(..), fromInitToMain, lenses, toError, mapMain)

import Html exposing (Html, button, div, label, td, text, tr)
import Html.Events exposing (onClick)
import Maybe.Extra
import Monocle.Optional exposing (Optional)
import Pages.Util.Links as Links
import Pages.Util.Style as Style
import Pages.Util.ViewUtil as ViewUtil exposing (Page(..))
import Util.HttpUtil as HttpUtil exposing (Error)
import Util.Initialization exposing (ErrorExplanation)


type Tristate main initial
    = Initial initial
    | Main main
    | Error ErrorExplanation


fold :
    { onInitial : initial -> a
    , onMain : main -> a
    , onError : ErrorExplanation -> a
    }
    -> Tristate main initial
    -> a
fold fs t =
    case t of
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
        , onMain = f >> Main
        , onError = always t
        }
        t


lenses :
    { initial : Optional (Tristate main initial) initial
    , main : Optional (Tristate main initial) main
    , error : Optional (Tristate main initial) ErrorExplanation
    }
lenses =
    { initial =
        Optional asInitial
            (\b a ->
                case a of
                    Initial _ ->
                        Initial b

                    t ->
                        t
            )
    , main =
        Optional asMain
            (\b a ->
                case a of
                    Main _ ->
                        Main b

                    t ->
                        t
            )
    , error =
        Optional asError
            (\b a ->
                case a of
                    Error _ ->
                        Error b

                    t ->
                        t
            )
    }


asInitial : Tristate main initial -> Maybe initial
asInitial t =
    case t of
        Initial initial ->
            Just initial

        _ ->
            Nothing


asMain : Tristate main initial -> Maybe main
asMain t =
    case t of
        Main main ->
            Just main

        _ ->
            Nothing


asError : Tristate main initial -> Maybe ErrorExplanation
asError t =
    case t of
        Error initial ->
            Just initial

        _ ->
            Nothing


fromInitToMain : (initial -> Maybe main) -> Tristate main initial -> Tristate main initial
fromInitToMain with t =
    t
        |> asInitial
        |> Maybe.andThen with
        |> Maybe.Extra.unwrap t Main


toError : HttpUtil.Error -> Tristate main initial
toError =
    HttpUtil.errorToExplanation >> Error


view :
    { title : String
    , mainPageURL : String
    , viewMain : main -> Html msg
    , reloadMsg : msg
    }
    -> Tristate main initial
    -> Html msg
view ps t =
    case t of
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

                redirectBlock =
                    [ td []
                        [ ViewUtil.navigationToPageButton
                            { page = Login
                            , mainPageURL = ps.mainPageURL
                            , currentPage = Nothing
                            }
                        ]
                    ]
                        |> List.filter (always errorExplanation.redirectToLogin)

                reloadBlock =
                    [ td []
                        [ button [ onClick ps.reloadMsg ] [ text "Reload" ]
                        ]
                    ]
                        |> List.filter (always errorExplanation.suggestReload)
            in
            div [ Style.ids.error ]
                [ tr []
                    [ td [] [ label [] [ text "An error occurred:" ] ]
                    , td [] [ label [] [ text <| errorExplanation.cause ] ]
                    ]
                , tr [] solutionBlock
                , tr [] redirectBlock
                , tr [] reloadBlock
                ]
