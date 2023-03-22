module Pages.ReferenceMaps.View exposing (editReferenceMapLineWith, referenceMapLineWith, tableHeader, view)

import Addresses.Frontend
import Api.Types.ReferenceMap exposing (ReferenceMap)
import Basics.Extra exposing (flip)
import Configuration exposing (Configuration)
import Either exposing (Either(..))
import Html exposing (Attribute, Html, button, col, colgroup, div, input, label, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (colspan, disabled, scope, value)
import Html.Attributes.Extra exposing (stringProperty)
import Html.Events exposing (onClick, onInput)
import Html.Events.Extra exposing (onEnter)
import Maybe.Extra
import Monocle.Compose as Compose
import Monocle.Lens exposing (Lens)
import Pages.ReferenceMaps.Page as Page
import Pages.ReferenceMaps.Pagination as Pagination
import Pages.ReferenceMaps.ReferenceMapCreationClientInput as ReferenceMapCreationClientInput exposing (ReferenceMapCreationClientInput)
import Pages.ReferenceMaps.ReferenceMapUpdateClientInput as ReferenceMapUpdateClientInput exposing (ReferenceMapUpdateClientInput)
import Pages.Util.HtmlUtil as HtmlUtil
import Pages.Util.Links as Links
import Pages.Util.PaginationSettings as PaginationSettings
import Pages.Util.Style as Style
import Pages.Util.ValidatedInput as ValidatedInput exposing (ValidatedInput)
import Pages.Util.ViewUtil as ViewUtil
import Pages.View.Tristate as Tristate
import Paginate
import Util.DictList as DictList
import Util.Editing as Editing
import Util.MaybeUtil as MaybeUtil
import Util.SearchUtil as SearchUtil


view : Page.Model -> Html Page.Msg
view =
    Tristate.view
        { viewMain = viewMain
        , showLoginRedirect = True
        }


viewMain : Configuration -> Page.Main -> Html Page.LogicMsg
viewMain configuration main =
    ViewUtil.viewMainWith
        { configuration = configuration
        , jwt = .jwt >> Just
        , currentPage = Just ViewUtil.ReferenceMaps
        , showNavigation = True
        }
        main
    <|
        let
            viewReferenceMapState =
                Editing.unpack
                    { onView = viewReferenceMapLine configuration
                    , onUpdate = editReferenceMapLine |> always
                    , onDelete = deleteReferenceMapLine
                    }

            viewReferenceMaps =
                main.referenceMaps
                    |> DictList.filter (\_ v -> SearchUtil.search main.searchString v.original.name)
                    |> DictList.values
                    |> List.sortBy (.original >> .name >> String.toLower)
                    |> ViewUtil.paginate
                        { pagination = Page.lenses.main.pagination |> Compose.lensWithLens Pagination.lenses.referenceMaps
                        }
                        main

            ( button, creationLine ) =
                createReferenceMap main.referenceMapToAdd
                    |> Either.unpack (\l -> ( [ l ], [] )) (\r -> ( [], [ r ] ))
                    |> Tuple.mapBoth List.concat List.concat
        in
        div [ Style.ids.addReferenceMapView ]
            (button
                ++ [ HtmlUtil.searchAreaWith
                        { msg = Page.SetSearchString
                        , searchString = main.searchString
                        }
                   , table [ Style.classes.elementsWithControlsTable ]
                        (tableHeader
                            ++ [ tbody []
                                    (creationLine
                                        ++ (viewReferenceMaps |> Paginate.page |> List.concatMap viewReferenceMapState)
                                    )
                               ]
                        )
                   , div [ Style.classes.pagination ]
                        [ ViewUtil.pagerButtons
                            { msg =
                                PaginationSettings.updateCurrentPage
                                    { pagination = Page.lenses.main.pagination
                                    , items = Pagination.lenses.referenceMaps
                                    }
                                    main
                                    >> Page.SetPagination
                            , elements = viewReferenceMaps
                            }
                        ]
                   ]
            )


tableHeader : List (Html msg)
tableHeader =
    [ colgroup []
        [ col [] []
        , col [] []
        ]
    , thead []
        [ tr [ Style.classes.tableHeader, Style.classes.referenceMapEditTable ]
            [ th [] [ label [] [ text "Name" ] ]
            , th [ Style.classes.toggle ] []
            ]
        ]
    ]


createReferenceMap : Maybe ReferenceMapCreationClientInput -> Either (List (Html Page.LogicMsg)) (List (Html Page.LogicMsg))
createReferenceMap maybeCreation =
    case maybeCreation of
        Nothing ->
            [ div [ Style.ids.add ]
                [ button
                    [ Style.classes.button.add
                    , onClick <| Page.UpdateReferenceMapCreation <| Just <| ReferenceMapCreationClientInput.default
                    ]
                    [ text "New reference map" ]
                ]
            ]
                |> Left

        Just creation ->
            createReferenceMapLine creation |> Right


viewReferenceMapLine : Configuration -> ReferenceMap -> Bool -> List (Html Page.LogicMsg)
viewReferenceMapLine configuration referenceMap showControls =
    referenceMapLineWith
        { controls =
            [ td [ Style.classes.controls ]
                [ button [ Style.classes.button.edit, Page.EnterEditReferenceMap referenceMap.id |> onClick ] [ text "Edit" ] ]
            , td [ Style.classes.controls ]
                [ Links.linkButton
                    { url = Links.frontendPage configuration <| Addresses.Frontend.referenceEntries.address <| referenceMap.id
                    , attributes = [ Style.classes.button.editor ]
                    , children = [ text "Entries" ]
                    }
                ]
            , td [ Style.classes.controls ]
                [ button
                    [ Style.classes.button.delete, onClick (Page.RequestDeleteReferenceMap referenceMap.id) ]
                    [ text "Delete" ]
                ]
            ]
        , toggleCommand = Page.ToggleControls referenceMap.id
        , showControls = showControls
        }
        referenceMap


deleteReferenceMapLine : ReferenceMap -> List (Html Page.LogicMsg)
deleteReferenceMapLine referenceMap =
    referenceMapLineWith
        { controls =
            [ td [ Style.classes.controls ]
                [ button
                    [ Style.classes.button.delete, onClick (Page.ConfirmDeleteReferenceMap referenceMap.id) ]
                    [ text "Delete?" ]
                ]
            , td [ Style.classes.controls ]
                [ button
                    [ Style.classes.button.confirm, onClick (Page.CancelDeleteReferenceMap referenceMap.id) ]
                    [ text "Cancel" ]
                ]
            ]
        , toggleCommand = Page.ToggleControls referenceMap.id
        , showControls = True
        }
        referenceMap


referenceMapLineWith :
    { controls : List (Html msg)
    , toggleCommand : msg
    , showControls : Bool
    }
    -> ReferenceMap
    -> List (Html msg)
referenceMapLineWith ps referenceMap =
    let
        withOnClick =
            (::) (ps.toggleCommand |> onClick)

        infoRow =
            tr [ Style.classes.editing ]
                [ td ([ Style.classes.editable ] |> withOnClick)
                    [ label [] [ text referenceMap.name ] ]
                , HtmlUtil.toggleControlsCell ps.toggleCommand
                ]

        controlsRow =
            tr []
                [ td [ colspan 1 ] [ table [ Style.classes.elementsWithControlsTable ] [ tr [] ps.controls ] ]
                ]
    in
    infoRow
        :: (if ps.showControls then
                [ controlsRow ]

            else
                []
           )


editReferenceMapLine : ReferenceMapUpdateClientInput -> List (Html Page.LogicMsg)
editReferenceMapLine referenceMapUpdateClientInput =
    editReferenceMapLineWith
        { saveMsg = Page.SaveReferenceMapEdit referenceMapUpdateClientInput.id
        , nameLens = ReferenceMapUpdateClientInput.lenses.name
        , updateMsg = Page.UpdateReferenceMap
        , confirmName = "Save"
        , cancelMsg = Page.ExitEditReferenceMapAt referenceMapUpdateClientInput.id
        , cancelName = "Cancel"
        , rowStyles = [ Style.classes.editLine ]
        , toggleCommand = Page.ToggleControls referenceMapUpdateClientInput.id |> Just
        }
        referenceMapUpdateClientInput


createReferenceMapLine : ReferenceMapCreationClientInput -> List (Html Page.LogicMsg)
createReferenceMapLine referenceMapCreationClientInput =
    editReferenceMapLineWith
        { saveMsg = Page.CreateReferenceMap
        , nameLens = ReferenceMapCreationClientInput.lenses.name
        , updateMsg = Just >> Page.UpdateReferenceMapCreation
        , confirmName = "Add"
        , cancelMsg = Page.UpdateReferenceMapCreation Nothing
        , cancelName = "Cancel"
        , rowStyles = [ Style.classes.editLine ]
        , toggleCommand = Nothing
        }
        referenceMapCreationClientInput


editReferenceMapLineWith :
    { saveMsg : msg
    , nameLens : Lens editedValue (ValidatedInput String)
    , updateMsg : editedValue -> msg
    , confirmName : String
    , cancelMsg : msg
    , cancelName : String
    , rowStyles : List (Attribute msg)
    , toggleCommand : Maybe msg
    }
    -> editedValue
    -> List (Html msg)
editReferenceMapLineWith handling editedValue =
    let
        validInput =
            handling.nameLens.get editedValue
                |> ValidatedInput.isValid

        validatedSaveAction =
            MaybeUtil.optional validInput <| onEnter handling.saveMsg

        controlsRow =
            tr []
                [ td [ colspan 1 ]
                    [ table [ Style.classes.elementsWithControlsTable ]
                        [ td [ Style.classes.controls ]
                            [ button
                                ([ MaybeUtil.defined <| Style.classes.button.confirm
                                 , MaybeUtil.defined <| disabled <| not <| validInput
                                 , MaybeUtil.optional validInput <| onClick handling.saveMsg
                                 ]
                                    |> Maybe.Extra.values
                                )
                                [ text handling.confirmName ]
                            ]
                        , td [ Style.classes.controls ]
                            [ button [ Style.classes.button.cancel, onClick handling.cancelMsg ]
                                [ text handling.cancelName ]
                            ]
                        ]
                    ]
                ]

        commandToggle =
            handling.toggleCommand
                |> Maybe.Extra.unwrap []
                    (HtmlUtil.toggleControlsCell >> List.singleton)
    in
    [ tr handling.rowStyles
        ([ td [ Style.classes.editable ]
            [ input
                ([ MaybeUtil.defined <| value <| .text <| handling.nameLens.get <| editedValue
                 , MaybeUtil.defined <|
                    onInput <|
                        flip (ValidatedInput.lift handling.nameLens).set editedValue
                            >> handling.updateMsg
                 , MaybeUtil.defined <| HtmlUtil.onEscape handling.cancelMsg
                 , validatedSaveAction
                 ]
                    |> Maybe.Extra.values
                )
                []
            ]
         ]
            ++ commandToggle
        )
    , controlsRow
    ]
