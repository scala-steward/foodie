module Pages.ReferenceEntries.View exposing (view)

import Api.Auxiliary exposing (NutrientCode)
import Api.Types.Nutrient exposing (Nutrient)
import Api.Types.NutrientUnit as NutrientUnit
import Api.Types.ReferenceEntry exposing (ReferenceEntry)
import Basics.Extra exposing (flip)
import Dict
import Html exposing (Attribute, Html, button, col, colgroup, div, input, label, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (colspan, disabled, scope, value)
import Html.Attributes.Extra exposing (stringProperty)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra exposing (onEnter)
import Maybe.Extra
import Monocle.Compose as Compose
import Pages.ReferenceEntries.Page as Page exposing (NutrientMap)
import Pages.ReferenceEntries.Pagination as Pagination
import Pages.ReferenceEntries.ReferenceEntryCreationClientInput as ReferenceEntryCreationClientInput exposing (ReferenceEntryCreationClientInput)
import Pages.ReferenceEntries.ReferenceEntryUpdateClientInput as ReferenceEntryUpdateClientInput exposing (ReferenceEntryUpdateClientInput)
import Pages.ReferenceEntries.Status as Status
import Pages.Util.HtmlUtil as HtmlUtil
import Pages.Util.PaginationSettings as PaginationSettings
import Pages.Util.Style as Style
import Pages.Util.ValidatedInput as ValidatedInput
import Pages.Util.ViewUtil as ViewUtil
import Paginate
import Util.Editing as Editing
import Util.SearchUtil as SearchUtil


view : Page.Model -> Html Page.Msg
view model =
    ViewUtil.viewWithErrorHandling
        { isFinished = Status.isFinished
        , initialization = .initialization
        , configuration = .authorizedAccess >> .configuration
        , jwt = .authorizedAccess >> .jwt >> Just
        , currentPage = Nothing
        , showNavigation = True
        }
        model
    <|
        let
            viewReferenceEntryState =
                Editing.unpack
                    { onView = viewReferenceEntryLine model.nutrients
                    , onUpdate = updateReferenceEntryLine model.nutrients
                    , onDelete = deleteReferenceEntryLine model.nutrients
                    }

            viewReferenceEntries =
                model.referenceEntries
                    |> Dict.filter (\_ v -> SearchUtil.search model.referenceEntriesSearchString (v.original.nutrientCode |> nutrientInfo model.nutrients |> .name))
                    |> Dict.toList
                    |> List.sortBy (\( k, _ ) -> nutrientInfo model.nutrients k |> .unitName |> String.toLower)
                    |> List.map Tuple.second
                    |> ViewUtil.paginate
                        { pagination = Page.lenses.pagination |> Compose.lensWithLens Pagination.lenses.referenceEntries
                        }
                        model

            viewNutrients =
                model.nutrients
                    |> Dict.filter (\_ v -> SearchUtil.search model.nutrientsSearchString v.name)
                    |> Dict.values
                    |> List.sortBy .name
                    |> ViewUtil.paginate
                        { pagination = Page.lenses.pagination |> Compose.lensWithLens Pagination.lenses.nutrients
                        }
                        model

            anySelection =
                model.referenceEntriesToAdd
                    |> Dict.isEmpty
                    |> not

            ( referenceValue, unit ) =
                if anySelection then
                    ( "Reference value", "Unit" )

                else
                    ( "", "" )
        in
        div [ Style.ids.referenceEntryEditor ]
            [ div []
                [ HtmlUtil.searchAreaWith
                    { msg = Page.SetReferenceEntriesSearchString
                    , searchString = model.referenceEntriesSearchString
                    }
                , table []
                    [ colgroup []
                        [ col [] []
                        , col [] []
                        , col [] []
                        , col [ stringProperty "span" "2" ] []
                        ]
                    , thead []
                        [ tr [ Style.classes.tableHeader ]
                            [ th [ scope "col" ] [ label [] [ text "Name" ] ]
                            , th [ scope "col", Style.classes.numberLabel ] [ label [] [ text "Reference value" ] ]
                            , th [ scope "col", Style.classes.numberLabel ] [ label [] [ text "Unit" ] ]
                            , th [ colspan 2, scope "colgroup", Style.classes.controlsGroup ] []
                            ]
                        ]
                    , tbody []
                        (viewReferenceEntries
                            |> Paginate.page
                            |> List.map viewReferenceEntryState
                        )
                    ]
                ]
            , div [ Style.classes.pagination ]
                [ ViewUtil.pagerButtons
                    { msg =
                        PaginationSettings.updateCurrentPage
                            { pagination = Page.lenses.pagination
                            , items = Pagination.lenses.referenceEntries
                            }
                            model
                            >> Page.SetPagination
                    , elements = viewReferenceEntries
                    }
                ]
            , div [ Style.classes.addView ]
                [ div [ Style.classes.addElement ]
                    [ HtmlUtil.searchAreaWith
                        { msg = Page.SetNutrientsSearchString
                        , searchString = model.nutrientsSearchString
                        }
                    , table [ Style.classes.choiceTable ]
                        [ colgroup []
                            [ col [] []
                            , col [] []
                            , col [] []
                            , col [ stringProperty "span" "2" ] []
                            ]
                        , thead []
                            [ tr [ Style.classes.tableHeader ]
                                [ th [ scope "col" ] [ label [] [ text "Name" ] ]
                                , th [ scope "col", Style.classes.numberLabel ] [ label [] [ text referenceValue ] ]
                                , th [ scope "col", Style.classes.numberLabel ] [ label [] [ text unit ] ]
                                , th [ colspan 2, scope "colgroup", Style.classes.controlsGroup ] []
                                ]
                            ]
                        , tbody []
                            (viewNutrients
                                |> Paginate.page
                                |> List.map (viewNutrientLine model.nutrients model.referenceEntries model.referenceEntriesToAdd)
                            )
                        ]
                    , div [ Style.classes.pagination ]
                        [ ViewUtil.pagerButtons
                            { msg =
                                PaginationSettings.updateCurrentPage
                                    { pagination = Page.lenses.pagination
                                    , items = Pagination.lenses.nutrients
                                    }
                                    model
                                    >> Page.SetPagination
                            , elements = viewNutrients
                            }
                        ]
                    ]
                ]
            ]


viewReferenceEntryLine : Page.NutrientMap -> ReferenceEntry -> Html Page.Msg
viewReferenceEntryLine nutrientMap referenceEntry =
    let
        editMsg =
            Page.EnterEditReferenceEntry referenceEntry.nutrientCode |> onClick
    in
    referenceEntryLineWith
        { controls =
            [ td [ Style.classes.controls ] [ button [ Style.classes.button.edit, editMsg ] [ text "Edit" ] ]
            , td [ Style.classes.controls ] [ button [ Style.classes.button.delete, onClick (Page.RequestDeleteReferenceEntry referenceEntry.nutrientCode) ] [ text "Delete" ] ]
            ]
        , onClick = [ editMsg ]
        , nutrientMap = nutrientMap
        }
        referenceEntry


deleteReferenceEntryLine : Page.NutrientMap -> ReferenceEntry -> Html Page.Msg
deleteReferenceEntryLine nutrientMap referenceEntry =
    referenceEntryLineWith
        { controls =
            [ td [ Style.classes.controls ] [ button [ Style.classes.button.delete, onClick (Page.ConfirmDeleteReferenceEntry referenceEntry.nutrientCode) ] [ text "Delete?" ] ]
            , td [ Style.classes.controls ] [ button [ Style.classes.button.confirm, onClick (Page.CancelDeleteReferenceEntry referenceEntry.nutrientCode) ] [ text "Cancel" ] ]
            ]
        , onClick = []
        , nutrientMap = nutrientMap
        }
        referenceEntry


referenceEntryLineWith :
    { controls : List (Html Page.Msg)
    , onClick : List (Attribute Page.Msg)
    , nutrientMap : Page.NutrientMap
    }
    -> ReferenceEntry
    -> Html Page.Msg
referenceEntryLineWith ps referenceNutrient =
    let
        withOnClick =
            (++) ps.onClick

        info =
            nutrientInfo ps.nutrientMap referenceNutrient.nutrientCode
    in
    tr [ Style.classes.editing ]
        ([ td ([ Style.classes.editable ] |> withOnClick) [ label [] [ text <| info.name ] ]
         , td ([ Style.classes.editable, Style.classes.numberLabel ] |> withOnClick) [ label [] [ text <| String.fromFloat <| referenceNutrient.amount ] ]
         , td ([ Style.classes.editable, Style.classes.numberLabel ] |> withOnClick) [ label [] [ text <| info.unitName ] ]
         ]
            ++ ps.controls
        )


updateReferenceEntryLine : Page.NutrientMap -> ReferenceEntry -> ReferenceEntryUpdateClientInput -> Html Page.Msg
updateReferenceEntryLine nutrientMap referenceNutrient referenceNutrientUpdateClientInput =
    let
        saveMsg =
            Page.SaveReferenceEntryEdit referenceNutrientUpdateClientInput

        cancelMsg =
            Page.ExitEditReferenceEntryAt referenceNutrient.nutrientCode

        info =
            nutrientInfo nutrientMap referenceNutrient.nutrientCode
    in
    tr [ Style.classes.editLine ]
        [ td [] [ label [] [ text <| .name <| info ] ]
        , td [ Style.classes.numberCell ]
            [ input
                [ value
                    referenceNutrientUpdateClientInput.amount.text
                , onInput
                    (flip
                        (ValidatedInput.lift
                            ReferenceEntryUpdateClientInput.lenses.amount
                        ).set
                        referenceNutrientUpdateClientInput
                        >> Page.UpdateReferenceEntry
                    )
                , onEnter saveMsg
                , HtmlUtil.onEscape cancelMsg
                , Style.classes.numberLabel
                ]
                []
            ]
        , td [ Style.classes.numberCell ]
            [ label [ Style.classes.numberLabel ]
                [ text <| .unitName <| info
                ]
            ]
        , td []
            [ button [ Style.classes.button.confirm, onClick saveMsg ]
                [ text "Save" ]
            ]
        , td []
            [ button [ Style.classes.button.cancel, onClick cancelMsg ]
                [ text "Cancel" ]
            ]
        ]


viewNutrientLine : Page.NutrientMap -> Page.ReferenceEntryStateMap -> Page.AddNutrientMap -> Nutrient -> Html Page.Msg
viewNutrientLine nutrientMap referenceEntries referenceEntriesToAdd nutrient =
    let
        addMsg =
            Page.AddNutrient nutrient.code

        selectMsg =
            Page.SelectNutrient nutrient.code

        cancelMsg =
            Page.DeselectNutrient nutrient.code

        maybeReferenceEntryToAdd =
            Dict.get nutrient.code referenceEntriesToAdd

        rowClickAction =
            if Maybe.Extra.isJust maybeReferenceEntryToAdd then
                []

            else
                [ onClick selectMsg ]

        process =
            case maybeReferenceEntryToAdd of
                Nothing ->
                    [ td [ Style.classes.editable, Style.classes.numberCell ] []
                    , td [ Style.classes.editable, Style.classes.numberCell ] []
                    , td [ Style.classes.controls ] []
                    , td [] [ button [ Style.classes.button.select, onClick selectMsg ] [ text "Select" ] ]
                    ]

                Just referenceNutrientToAdd ->
                    let
                        exists =
                            Dict.get referenceNutrientToAdd.nutrientCode referenceEntries |> Maybe.Extra.isJust

                        ( confirmName, confirmStyle ) =
                            if exists then
                                ( "Added", Style.classes.button.edit )

                            else
                                ( "Add", Style.classes.button.confirm )

                        validInput =
                            List.all identity
                                [ referenceNutrientToAdd.amount |> ValidatedInput.isValid
                                , exists |> not
                                ]
                    in
                    [ td [ Style.classes.numberCell ]
                        ([ input
                            [ value referenceNutrientToAdd.amount.text
                            , onInput
                                (flip
                                    (ValidatedInput.lift
                                        ReferenceEntryCreationClientInput.lenses.amount
                                    ).set
                                    referenceNutrientToAdd
                                    >> Page.UpdateAddNutrient
                                )
                            , onEnter addMsg
                            , HtmlUtil.onEscape cancelMsg
                            , Style.classes.numberLabel
                            ]
                            []
                         ]
                            |> List.filter (exists |> not |> always)
                        )
                    , td [ Style.classes.numberCell ] [ label [] [ text <| .unitName <| nutrientInfo nutrientMap <| referenceNutrientToAdd.nutrientCode ] ]
                    , td [ Style.classes.controls ]
                        [ button
                            ([ confirmStyle
                             , disabled <| not <| validInput
                             ]
                                ++ (if validInput then
                                        [ onClick addMsg ]

                                    else
                                        []
                                   )
                            )
                            [ text <| confirmName ]
                        ]
                    , td [ Style.classes.controls ] [ button [ Style.classes.button.cancel, onClick cancelMsg ] [ text "Cancel" ] ]
                    ]
    in
    tr ([ Style.classes.editing ] ++ rowClickAction)
        (td [ Style.classes.editable ] [ label [] [ text nutrient.name ] ]
            :: process
        )


nutrientInfo : NutrientMap -> NutrientCode -> { name : String, unitName : String }
nutrientInfo nutrientMap =
    flip Dict.get nutrientMap
        >> Maybe.Extra.unwrap
            { name = ""
            , unitName = ""
            }
            (\nutrient ->
                { name = nutrient.name
                , unitName = nutrient.unit |> NutrientUnit.toString
                }
            )
