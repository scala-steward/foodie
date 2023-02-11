module Pages.Deletion.View exposing (view)

import Configuration exposing (Configuration)
import Html exposing (Html, button, div, label, table, tbody, td, text, tr)
import Html.Events exposing (onClick)
import Pages.Deletion.Page as Page
import Pages.Util.Links as Links
import Pages.Util.Style as Style
import Pages.Util.ViewUtil as ViewUtil
import Pages.View.Tristate as Tristate


view : Page.Model -> Html Page.Msg
view model =
    Tristate.view
        { viewMain = viewMain model.configuration
        , mainPageURLForLoginSuggestion =
            model |> .configuration |> .mainPageURL |> Just
        }
        model


viewMain : Configuration -> Page.Main -> Html Page.Msg
viewMain configuration main =
    ViewUtil.viewWithErrorHandlingSimple
        { configuration = configuration
        , jwt = always Nothing
        , currentPage = Nothing
        , showNavigation = False
        }
        main
    <|
        case main.mode of
            Page.Checking ->
                viewChecking configuration main

            Page.Confirmed ->
                viewConfirmed configuration


viewChecking : Configuration -> Page.Main -> Html Page.Msg
viewChecking configuration model =
    div [ Style.classes.confirm ]
        [ label [ Style.classes.info ] [ text "Confirm deletion" ]
        , table []
            [ tbody []
                [ tr []
                    [ td [] [ label [] [ text "Nickname" ] ]
                    , td [] [ label [] [ text <| model.userIdentifier.nickname ] ]
                    ]
                , tr []
                    [ td [] [ label [] [ text "Email" ] ]
                    , td [] [ label [] [ text <| model.userIdentifier.email ] ]
                    ]
                ]
            ]
        , div []
            [ button
                [ onClick Page.Confirm
                , Style.classes.button.delete
                ]
                [ text "Delete" ]
            ]
        , div []
            [ Links.toLoginButton
                { configuration = configuration
                , buttonText = "Back to main"
                }
            ]
        ]


viewConfirmed : Configuration -> Html Page.Msg
viewConfirmed configuration =
    div [ Style.classes.confirm ]
        [ div [] [ label [] [ text "User deletion successful." ] ]
        , div []
            [ Links.toLoginButton
                { configuration = configuration
                , buttonText = "Main page"
                }
            ]
        ]
