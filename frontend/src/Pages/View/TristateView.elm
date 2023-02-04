module Pages.View.TristateView exposing (TristateView(..), lenses)

import Html exposing (Html, button, div, label, td, text, tr)
import Html.Events exposing (onClick)
import Maybe.Extra
import Monocle.Optional exposing (Optional)
import Pages.Util.Links as Links
import Pages.Util.Style as Style
import Pages.Util.ViewUtil as ViewUtil exposing (Page(..))


type TristateView model initial
    = Initial initial
    | Main model
    | Error ErrorExplanation


type alias ErrorExplanation =
    { cause : String
    , possibleSolution : String
    , redirectToLogin : Bool
    , suggestReload : Bool
    }


lenses :
    { initial : Optional (TristateView model initial) initial
    , main : Optional (TristateView model initial) model
    , error : Optional (TristateView model initial) ErrorExplanation
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


asInitial : TristateView model initial -> Maybe initial
asInitial t =
    case t of
        Initial initial ->
            Just initial

        _ ->
            Nothing


asMain : TristateView model initial -> Maybe model
asMain t =
    case t of
        Main model ->
            Just model

        _ ->
            Nothing


asError : TristateView model initial -> Maybe ErrorExplanation
asError t =
    case t of
        Error initial ->
            Just initial

        _ ->
            Nothing


fromInitToMain : (initial -> model) -> TristateView model initial -> TristateView model initial
fromInitToMain with t =
    t
        |> asInitial
        |> Maybe.Extra.unwrap t (with >> Main)


toError : ErrorExplanation -> TristateView model initial
toError =
    Error


view :
    { title : String
    , mainPageURL : String
    , viewMain : model -> Html msg
    , reloadMsg : msg
    }
    -> TristateView model initial
    -> Html msg
view ps t =
    case t of
        Initial _ ->
            div [] [ Links.loadingSymbol ]

        Main model ->
            ps.viewMain model

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
