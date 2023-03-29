module Pages.Util.Choice.View exposing (..)

import Basics.Extra exposing (flip)
import Html exposing (Attribute, Html, button, div, label, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (colspan, disabled)
import Html.Events exposing (onClick)
import Html.Events.Extra exposing (onEnter)
import Maybe.Extra
import Monocle.Compose as Compose
import Pages.Util.Choice.Page
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
    , elementHeaderColumns : List (Html (Pages.Util.Choice.Page.LogicMsg elementId element update choiceId choice creation))
    , info : element -> List (Column (Pages.Util.Choice.Page.LogicMsg elementId element update choiceId choice creation))
    , controls : element -> List (Html (Pages.Util.Choice.Page.LogicMsg elementId element update choiceId choice creation))
    , isValidInput : update -> Bool
    , edit : element -> update -> List (Column (Pages.Util.Choice.Page.LogicMsg elementId element update choiceId choice creation))
    , fitControlsToColumns : Int
    }
    -> Pages.Util.Choice.Page.Main parentId elementId element update choiceId choice creation
    -> Html (Pages.Util.Choice.Page.LogicMsg elementId element update choiceId choice creation)
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
                        Pages.Util.Choice.Page.lenses.main.pagination
                            |> Compose.lensWithLens Pagination.lenses.elements
                    }
                    main
    in
    div [ Style.classes.choices ]
        [ HtmlUtil.searchAreaWith
            { msg = Pages.Util.Choice.Page.SetElementsSearchString
            , searchString = main.elementsSearchString
            }
        , table [ Style.classes.elementsWithControlsTable, Style.classes.elementEditTable ]
            [ thead []
                [ tr [ Style.classes.tableHeader ]
                    (ps.elementHeaderColumns
                        ++ [ th [ Style.classes.toggle ] [] ]
                    )
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
                        { pagination = Pages.Util.Choice.Page.lenses.main.pagination
                        , items = Pagination.lenses.elements
                        }
                        main
                        >> Pages.Util.Choice.Page.SetPagination
                , elements = paginatedElements
                }
            ]
        ]


viewChoices :
    { matchesSearchText : String -> choice -> Bool
    , sortBy : choice -> comparable
    , choiceHeaderColumns : List (Html (Pages.Util.Choice.Page.LogicMsg elementId element update choiceId choice creation))
    , idOfChoice : choice -> choiceId
    , nameOfChoice : choice -> String
    , elementCreationLine : choice -> creation -> List (Html (Pages.Util.Choice.Page.LogicMsg elementId element update choiceId choice creation))
    , elementCreationControls : choice -> creation -> List (Html (Pages.Util.Choice.Page.LogicMsg elementId element update choiceId choice creation))
    , viewChoiceLine : choice -> List (Column (Pages.Util.Choice.Page.LogicMsg elementId element update choiceId choice creation))
    , viewChoiceLineControls : choice -> List (Html (Pages.Util.Choice.Page.LogicMsg elementId element update choiceId choice creation))
    }
    -> Pages.Util.Choice.Page.Main parentId elementId element update choiceId choice creation
    -> Html (Pages.Util.Choice.Page.LogicMsg elementId element update choiceId choice creation)
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
                        Pages.Util.Choice.Page.lenses.main.pagination
                            |> Compose.lensWithLens Pagination.lenses.choices
                    }
                    main
    in
    div [ Style.classes.addView ]
        [ div [ Style.classes.addElement ]
            [ HtmlUtil.searchAreaWith
                { msg = Pages.Util.Choice.Page.SetChoicesSearchString
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
                            { pagination = Pages.Util.Choice.Page.lenses.main.pagination
                            , items = Pagination.lenses.choices
                            }
                            main
                            >> Pages.Util.Choice.Page.SetPagination
                    , elements = paginatedChoices
                    }
                ]
            ]
        ]


viewElementLine :
    { idOfElement : element -> elementId
    , info : element -> List (Column (Pages.Util.Choice.Page.LogicMsg elementId element update choiceId choice creation))
    , controls : element -> List (Html (Pages.Util.Choice.Page.LogicMsg elementId element update choiceId choice creation))
    }
    -> element
    -> Bool
    -> List (Html (Pages.Util.Choice.Page.LogicMsg elementId element update choiceId choice creation))
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
    , info : element -> List (Column (Pages.Util.Choice.Page.LogicMsg elementId element update choiceId choice creation))
    }
    -> element
    -> List (Html (Pages.Util.Choice.Page.LogicMsg elementId element update choiceId choice creation))
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
                [ td [ Style.classes.controls ] [ button [ Style.classes.button.delete, onClick <| Pages.Util.Choice.Page.ConfirmDelete <| elementId ] [ text "Delete?" ] ]
                , td [ Style.classes.controls ] [ button [ Style.classes.button.confirm, onClick <| Pages.Util.Choice.Page.CancelDelete <| elementId ] [ text "Cancel" ] ]
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
    , info : element -> List (Column (Pages.Util.Choice.Page.LogicMsg elementId element update choiceId choice creation))
    , controls : element -> List (Html (Pages.Util.Choice.Page.LogicMsg elementId element update choiceId choice creation))
    , showControls : Bool
    }
    -> element
    -> List (Html (Pages.Util.Choice.Page.LogicMsg elementId element update choiceId choice creation))
elementLineWith ps element =
    let
        toggleCommand =
            Pages.Util.Choice.Page.ToggleControls <| ps.idOfElement <| element

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
    , edit : element -> update -> List (Column (Pages.Util.Choice.Page.LogicMsg elementId element update choiceId choice creation))
    , fitControlsToColumns : Int
    }
    -> element
    -> update
    -> List (Html (Pages.Util.Choice.Page.LogicMsg elementId element update choiceId choice creation))
editElementLine ps element elementUpdateClientInput =
    let
        saveMsg =
            Pages.Util.Choice.Page.SaveEdit elementUpdateClientInput

        elementId =
            element |> ps.idOfElement

        cancelMsg =
            Pages.Util.Choice.Page.ExitEdit <| elementId

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
                    ++ [ HtmlUtil.toggleControlsCell <| Pages.Util.Choice.Page.ToggleControls <| elementId ]
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
    , choiceOnView : choice -> List (Column (Pages.Util.Choice.Page.LogicMsg elementId element update choiceId choice creation))
    , choiceControls : choice -> List (Html (Pages.Util.Choice.Page.LogicMsg elementId element update choiceId choice creation))
    }
    -> choice
    -> Bool
    -> List (Html (Pages.Util.Choice.Page.LogicMsg elementId element update choiceId choice creation))
viewChoiceLine ps choice showControls =
    let
        toggleCommand =
            Pages.Util.Choice.Page.ToggleChoiceControls <| ps.idOfChoice <| choice

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
    , elementCreationLine : choice -> creation -> List (Html (Pages.Util.Choice.Page.LogicMsg elementId element update choiceId choice creation))
    , elementCreationControls : choice -> creation -> List (Html (Pages.Util.Choice.Page.LogicMsg elementId element update choiceId choice creation))
    }
    -> choice
    -> creation
    -> List (Html (Pages.Util.Choice.Page.LogicMsg elementId element update choiceId choice creation))
editElementCreation ps choice creation =
    let
        choiceId =
            choice |> ps.idOfChoice

        toggleMsg =
            Pages.Util.Choice.Page.ToggleChoiceControls <| choiceId

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
