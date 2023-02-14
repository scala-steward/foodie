module Pages.Registration.Request.View exposing (..)

import Basics.Extra exposing (flip)
import Configuration exposing (Configuration)
import Html exposing (Html, button, div, input, label, table, tbody, td, text, tr)
import Html.Attributes exposing (disabled)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra exposing (onEnter)
import Maybe.Extra
import Monocle.Lens exposing (Lens)
import Pages.Registration.Request.Page as Page
import Pages.Util.Links as Links
import Pages.Util.Style as Style
import Pages.Util.ValidatedInput as ValidatedInput
import Pages.Util.ViewUtil as ViewUtil
import Pages.View.Tristate as Tristate
import Util.LensUtil as LensUtil
import Util.MaybeUtil as MaybeUtil


view : Page.Model -> Html Page.Msg
view =
    Tristate.view
        { viewMain = viewMain
        , showLoginRedirect = True
        }


viewMain : Configuration -> Page.Main -> Html Page.Msg
viewMain configuration main =
    ViewUtil.viewMainWith
        { configuration = configuration
        , jwt = always Nothing
        , currentPage = Nothing
        , showNavigation = False
        }
        main
    <|
        case main.mode of
            Page.Editing ->
                viewEditing main

            Page.Confirmed ->
                viewConfirmed configuration


viewEditing : Page.Main -> Html Page.Msg
viewEditing main =
    let
        isValid =
            ValidatedInput.isValid main.nickname && ValidatedInput.isValid main.email

        enterAction =
            MaybeUtil.optional isValid <| onEnter Page.Request
    in
    div [ Style.classes.request ]
        [ div [] [ label [ Style.classes.info ] [ text "Registration" ] ]
        , table []
            [ tbody []
                [ tr []
                    [ td [] [ label [] [ text "Nickname" ] ]
                    , td []
                        [ input
                            ([ MaybeUtil.defined <|
                                onInput <|
                                    flip (ValidatedInput.lift LensUtil.identityLens).set main.nickname
                                        >> Page.SetNickname
                             , MaybeUtil.defined <| Style.classes.editable
                             , enterAction
                             ]
                                |> Maybe.Extra.values
                            )
                            []
                        ]
                    ]
                , tr []
                    [ td [] [ label [] [ text "Email" ] ]
                    , td []
                        [ input
                            ([ MaybeUtil.defined <|
                                onInput <|
                                    flip (ValidatedInput.lift LensUtil.identityLens).set main.email
                                        >> Page.SetEmail
                             , MaybeUtil.defined <| Style.classes.editable
                             , enterAction
                             ]
                                |> Maybe.Extra.values
                            )
                            []
                        ]
                    ]
                ]
            ]
        , div []
            [ button
                [ onClick Page.Request
                , Style.classes.button.confirm
                , disabled <| not <| isValid
                ]
                [ text "Register" ]
            ]
        ]


viewConfirmed : Configuration -> Html Page.Msg
viewConfirmed configuration =
    div [ Style.classes.confirm ]
        [ div [] [ label [] [ text "Registration requested. Please check your email to continue." ] ]
        , div []
            [ Links.toLoginButton
                { configuration = configuration
                , buttonText = "Main page"
                }
            ]
        ]
