module Pages.Util.Choice.ChoiceGroupView exposing (..)

import Basics.Extra exposing (flip)
import Html exposing (Attribute, Html, button, div, label, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (colspan, disabled)
import Html.Events exposing (onClick)
import Html.Events.Extra exposing (onEnter)
import Maybe.Extra
import Monocle.Compose as Compose
import Pages.Util.Choice.ChoiceGroup as ChoiceGroup
import Pages.Util.Choice.Pagination as Pagination exposing (Pagination)
import Pages.Util.HtmlUtil as HtmlUtil
import Pages.Util.PaginationSettings as PaginationSettings
import Pages.Util.Style as Style
import Pages.Util.ViewUtil as ViewUtil
import Paginate exposing (PaginatedList)
import Util.DictList as DictList exposing (DictList)
import Util.Editing as Editing exposing (Editing)
import Util.MaybeUtil as MaybeUtil
import Util.SearchUtil as SearchUtil


viewMain :
    { nameOfChoice : choice -> String
    , choiceIdOfElement : element -> choiceId
    , idOfElement : element -> elementId
    , info : element -> List (Column (ChoiceGroup.LogicMsg elementId element update choiceId choice creation))
    , controls : element -> List (Html (ChoiceGroup.LogicMsg elementId element update choiceId choice creation))
    , isValidInput : update -> Bool
    , edit : element -> update -> List (Column (ChoiceGroup.LogicMsg elementId element update choiceId choice creation))
    , fitControlsToColumns : Int
    }
    -> ChoiceGroup.Main parentId elementId element update choiceId choice creation
    -> Html (ChoiceGroup.LogicMsg elementId element update choiceId choice creation)
viewMain ps main =
    let
        viewElementState =
            Editing.unpack
                { onView =
                    viewElementLine
                        { idOfElement = ps.idOfElement
                        , controls = ps.controls
                        , info = ps.info
                        }
                , onUpdate =
                    editElementLine
                        { idOfElement = ps.idOfElement
                        , isValidInput = ps.isValidInput
                        , edit = ps.edit
                        , fitControlsToColumns = ps.fitControlsToColumns
                        }
                , onDelete =
                    deleteElementLine
                        { idOfElement = ps.idOfElement
                        , info = ps.info
                        }
                }

        extractedName =
            .original
                >> ps.choiceIdOfElement
                >> flip DictList.get main.choices
                >> Maybe.Extra.unwrap "" (.original >> ps.nameOfChoice)

        paginatedElements =
            main
                |> .elements
                |> DictList.values
                |> List.filter
                    (extractedName
                        >> SearchUtil.search main.elementsSearchString
                    )
                |> List.sortBy
                    (extractedName
                        >> String.toLower
                    )
                |> ViewUtil.paginate
                    { pagination =
                        ChoiceGroup.lenses.main.pagination
                            |> Compose.lensWithLens Pagination.lenses.elements
                    }
                    main
    in
    div [ Style.classes.choices ]
        [ HtmlUtil.searchAreaWith
            { msg = ChoiceGroup.SetElementsSearchString
            , searchString = main.elementsSearchString
            }
        , table [ Style.classes.elementsWithControlsTable, Style.classes.elementEditTable ]
            [ thead []
                [ tr [ Style.classes.tableHeader ]
                    [ th [] [ label [] [ text "Name" ] ]
                    , th [ Style.classes.numberLabel ] [ label [] [ text "Amount" ] ]
                    , th [ Style.classes.numberLabel ] [ label [] [ text "Unit" ] ]
                    , th [ Style.classes.toggle ] []
                    ]
                ]
            , tbody []
                (paginatedElements
                    |> Paginate.page
                    |> List.concatMap viewElementState
                )
            ]
        , div [ Style.classes.pagination ]
            [ ViewUtil.pagerButtons
                { msg =
                    PaginationSettings.updateCurrentPage
                        { pagination = ChoiceGroup.lenses.main.pagination
                        , items = Pagination.lenses.elements
                        }
                        main
                        >> ChoiceGroup.SetPagination
                , elements = paginatedElements
                }
            ]
        ]


viewChoices :
    { matchesSearchText : String -> choice -> Bool
    , sortBy : choice -> comparable
    , choiceHeaderColumns : List (Html (ChoiceGroup.LogicMsg elementId element update choiceId choice creation))
    , idOfChoice : choice -> choiceId
    , nameOfChoice : choice -> String
    , elementCreationLine : choice -> creation -> List (Html (ChoiceGroup.LogicMsg elementId element update choiceId choice creation))
    , elementCreationControls : choice -> creation -> List (Html (ChoiceGroup.LogicMsg elementId element update choiceId choice creation))
    , viewChoiceLine : choice -> List (Column (ChoiceGroup.LogicMsg elementId element update choiceId choice creation))
    , viewChoiceLineControls : choice -> List (Html (ChoiceGroup.LogicMsg elementId element update choiceId choice creation))
    }
    -> ChoiceGroup.Main parentId elementId element update choiceId choice creation
    -> Html (ChoiceGroup.LogicMsg elementId element update choiceId choice creation)
viewChoices ps main =
    let
        paginatedChoices =
            main
                |> .choices
                |> DictList.values
                |> List.filter (.original >> ps.matchesSearchText main.choicesSearchString)
                |> List.sortBy (.original >> ps.sortBy)
                |> ViewUtil.paginate
                    { pagination =
                        ChoiceGroup.lenses.main.pagination
                            |> Compose.lensWithLens Pagination.lenses.choices
                    }
                    main
    in
    div [ Style.classes.addView ]
        [ div [ Style.classes.addElement ]
            [ HtmlUtil.searchAreaWith
                { msg = ChoiceGroup.SetChoicesSearchString
                , searchString = main.choicesSearchString
                }
            , table [ Style.classes.elementsWithControlsTable ]
                [ thead []
                    [ tr [ Style.classes.tableHeader ]
                        (ps.choiceHeaderColumns
                            ++ [ th [ Style.classes.toggle ] [] ]
                        )
                    ]
                , tbody []
                    (paginatedChoices
                        |> Paginate.page
                        |> List.concatMap
                            (Editing.unpack
                                { onView =
                                    viewChoiceLine
                                        { nameOfChoice = ps.nameOfChoice
                                        , idOfChoice = ps.idOfChoice
                                        , choiceOnView = ps.viewChoiceLine
                                        , choiceControls = ps.viewChoiceLineControls
                                        }
                                , onUpdate =
                                    editElementCreation
                                        { idOfChoice = ps.idOfChoice
                                        , nameOfChoice = ps.nameOfChoice
                                        , elementCreationLine = ps.elementCreationLine
                                        , elementCreationControls = ps.elementCreationControls
                                        }
                                , onDelete = always []
                                }
                            )
                    )
                ]
            , div [ Style.classes.pagination ]
                [ ViewUtil.pagerButtons
                    { msg =
                        PaginationSettings.updateCurrentPage
                            { pagination = ChoiceGroup.lenses.main.pagination
                            , items = Pagination.lenses.choices
                            }
                            main
                            >> ChoiceGroup.SetPagination
                    , elements = paginatedChoices
                    }
                ]
            ]
        ]


viewElementLine :
    { idOfElement : element -> elementId
    , info : element -> List (Column (ChoiceGroup.LogicMsg elementId element update choiceId choice creation))
    , controls : element -> List (Html (ChoiceGroup.LogicMsg elementId element update choiceId choice creation))
    }
    -> element
    -> Bool
    -> List (Html (ChoiceGroup.LogicMsg elementId element update choiceId choice creation))
viewElementLine ps element showControls =
    elementLineWith
        { idOfElement = ps.idOfElement
        , info = ps.info
        , controls = ps.controls
        , showControls = showControls
        }
        element


deleteElementLine :
    { idOfElement : element -> elementId
    , info : element -> List (Column (ChoiceGroup.LogicMsg elementId element update choiceId choice creation))
    }
    -> element
    -> List (Html (ChoiceGroup.LogicMsg elementId element update choiceId choice creation))
deleteElementLine ps =
    elementLineWith
        { idOfElement = ps.idOfElement
        , info = ps.info
        , controls =
            \element ->
                let
                    elementId =
                        element |> ps.idOfElement
                in
                [ td [ Style.classes.controls ] [ button [ Style.classes.button.delete, onClick <| ChoiceGroup.ConfirmDelete <| elementId ] [ text "Delete?" ] ]
                , td [ Style.classes.controls ] [ button [ Style.classes.button.confirm, onClick <| ChoiceGroup.CancelDelete <| elementId ] [ text "Cancel" ] ]
                ]
        , showControls = True
        }


type alias Column msg =
    { attributes : List (Attribute msg)
    , children : List (Html msg)
    }


withExtraAttributes : List (Attribute msg) -> Column msg -> Html msg
withExtraAttributes extra column =
    td (column.attributes ++ extra) column.children


elementLineWith :
    { idOfElement : element -> elementId
    , info : element -> List (Column (ChoiceGroup.LogicMsg elementId element update choiceId choice creation))
    , controls : element -> List (Html (ChoiceGroup.LogicMsg elementId element update choiceId choice creation))
    , showControls : Bool
    }
    -> element
    -> List (Html (ChoiceGroup.LogicMsg elementId element update choiceId choice creation))
elementLineWith ps element =
    let
        toggleCommand =
            ChoiceGroup.ToggleControls <| ps.idOfElement <| element

        infoColumns =
            ps.info element

        infoCells =
            infoColumns |> List.map (withExtraAttributes [ toggleCommand |> onClick ])

        infoRow =
            tr [ Style.classes.editing ]
                (infoCells
                    ++ [ HtmlUtil.toggleControlsCell toggleCommand ]
                )

        controlsRow =
            tr []
                [ td [ colspan <| List.length <| infoColumns ] [ table [ Style.classes.elementsWithControlsTable ] [ tr [] (ps.controls <| element) ] ]
                ]
    in
    infoRow
        :: (if ps.showControls then
                [ controlsRow ]

            else
                []
           )


editElementLine :
    { idOfElement : element -> elementId
    , isValidInput : update -> Bool
    , edit : element -> update -> List (Column (ChoiceGroup.LogicMsg elementId element update choiceId choice creation))
    , fitControlsToColumns : Int
    }
    -> element
    -> update
    -> List (Html (ChoiceGroup.LogicMsg elementId element update choiceId choice creation))
editElementLine ps element elementUpdateClientInput =
    let
        saveMsg =
            ChoiceGroup.SaveEdit elementUpdateClientInput

        elementId =
            element |> ps.idOfElement

        cancelMsg =
            ChoiceGroup.ExitEdit <| elementId

        validInput =
            elementUpdateClientInput |> ps.isValidInput

        editRow =
            tr [ Style.classes.editLine ]
                ((ps.edit element elementUpdateClientInput
                    |> List.map
                        (withExtraAttributes
                            [ onEnter saveMsg
                            , HtmlUtil.onEscape cancelMsg
                            ]
                        )
                 )
                    ++ [ HtmlUtil.toggleControlsCell <| ChoiceGroup.ToggleControls <| elementId ]
                )

        controlsRow =
            tr []
                [ td [ colspan <| ps.fitControlsToColumns ]
                    [ table [ Style.classes.elementsWithControlsTable ]
                        [ tr []
                            [ td [ Style.classes.controls ]
                                [ button
                                    ([ MaybeUtil.defined <| Style.classes.button.confirm
                                     , MaybeUtil.defined <| disabled <| not <| validInput
                                     , MaybeUtil.optional validInput <| onClick saveMsg
                                     ]
                                        |> Maybe.Extra.values
                                    )
                                    [ text <| "Save" ]
                                ]
                            , td [ Style.classes.controls ]
                                [ button [ Style.classes.button.cancel, onClick cancelMsg ]
                                    [ text <| "Cancel" ]
                                ]
                            ]
                        ]
                    ]
                ]
    in
    [ editRow, controlsRow ]


viewChoiceLine :
    { nameOfChoice : choice -> String
    , idOfChoice : choice -> choiceId
    , choiceOnView : choice -> List (Column (ChoiceGroup.LogicMsg elementId element update choiceId choice creation))
    , choiceControls : choice -> List (Html (ChoiceGroup.LogicMsg elementId element update choiceId choice creation))
    }
    -> choice
    -> Bool
    -> List (Html (ChoiceGroup.LogicMsg elementId element update choiceId choice creation))
viewChoiceLine ps choice showControls =
    let
        toggleCommand =
            ChoiceGroup.ToggleChoiceControls <| ps.idOfChoice <| choice

        columns =
            ps.choiceOnView choice |> List.map (withExtraAttributes [ onClick toggleCommand ])

        infoRow =
            tr [ Style.classes.editing ]
                (td [ Style.classes.editable, onClick toggleCommand ] [ label [] [ text <| ps.nameOfChoice <| choice ] ]
                    :: (columns ++ [ HtmlUtil.toggleControlsCell toggleCommand ])
                )

        -- Extra column because the name is fixed
        controlsRow =
            tr []
                [ td [ colspan <| (+) 1 <| List.length <| columns ] [ table [ Style.classes.elementsWithControlsTable ] [ tr [] (ps.choiceControls <| choice) ] ]
                ]
    in
    infoRow
        :: (if showControls then
                [ controlsRow ]

            else
                []
           )


editElementCreation :
    { idOfChoice : choice -> choiceId
    , nameOfChoice : choice -> String
    , elementCreationLine : choice -> creation -> List (Html (ChoiceGroup.LogicMsg elementId element update choiceId choice creation))
    , elementCreationControls : choice -> creation -> List (Html (ChoiceGroup.LogicMsg elementId element update choiceId choice creation))
    }
    -> choice
    -> creation
    -> List (Html (ChoiceGroup.LogicMsg elementId element update choiceId choice creation))
editElementCreation ps choice creation =
    let
        choiceId =
            choice |> ps.idOfChoice

        toggleMsg =
            ChoiceGroup.ToggleChoiceControls <| choiceId

        creationRow =
            tr []
                (td [ Style.classes.editable ] [ label [] [ text <| ps.nameOfChoice <| choice ] ]
                    :: ps.elementCreationLine choice creation
                    ++ [ HtmlUtil.toggleControlsCell <| toggleMsg ]
                )

        columns =
            ps.elementCreationLine choice creation

        -- Extra column because the name is fixed
        controlsRow =
            tr []
                [ td [ colspan <| (+) 1 <| List.length <| columns ]
                    [ table [ Style.classes.elementsWithControlsTable ]
                        [ tr []
                            (ps.elementCreationControls choice creation)
                        ]
                    ]
                ]
    in
    [ creationRow, controlsRow ]
