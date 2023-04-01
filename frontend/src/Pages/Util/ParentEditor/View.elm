module Pages.Util.ParentEditor.View exposing (..)

import Configuration exposing (Configuration)
import Html exposing (Attribute, Html, button, div, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (colspan, disabled)
import Html.Events exposing (onClick)
import Maybe.Extra
import Monocle.Compose as Compose
import Pages.Util.HtmlUtil as HtmlUtil
import Pages.Util.PaginationSettings as PaginationSettings
import Pages.Util.ParentEditor.Page as Page
import Pages.Util.ParentEditor.Pagination as Pagination
import Pages.Util.Style as Style
import Pages.Util.ViewUtil as ViewUtil
import Paginate
import Util.DictList as DictList
import Util.Editing as Editing
import Util.MaybeUtil as MaybeUtil


viewParentsWith :
    { currentPage : ViewUtil.Page
    , matchesSearchText : String -> parent -> Bool
    , sortBy : parent -> comparable
    , tableHeader : Html (Page.LogicMsg parentId parent creation update)
    , viewLine : Configuration -> parent -> Bool -> List (Html (Page.LogicMsg parentId parent creation update))
    , updateLine : parent -> update -> List (Html (Page.LogicMsg parentId parent creation update))
    , deleteLine : parent -> List (Html (Page.LogicMsg parentId parent creation update))
    , create :
        { ifCreating : creation -> List (Html (Page.LogicMsg parentId parent creation update))
        , default : creation
        , label : String
        }
    , styling : Attribute (Page.LogicMsg parentId parent creation update)
    }
    -> Configuration
    -> Page.Main parentId parent creation update
    -> Html (Page.LogicMsg parentId parent creation update)
viewParentsWith ps configuration main =
    ViewUtil.viewMainWith
        { configuration = configuration
        , jwt = .jwt >> Just
        , currentPage = Just ps.currentPage
        , showNavigation = True
        }
        main
    <|
        let
            viewParent =
                Editing.unpack
                    { onView = ps.viewLine configuration
                    , onUpdate = ps.updateLine
                    , onDelete = ps.deleteLine
                    }

            viewParents =
                main.parents
                    |> DictList.filter
                        (\_ v ->
                            ps.matchesSearchText main.searchString v.original
                        )
                    |> DictList.values
                    |> List.sortBy (.original >> ps.sortBy)
                    |> ViewUtil.paginate
                        { pagination = Page.lenses.main.pagination |> Compose.lensWithLens Pagination.lenses.parents
                        }
                        main

            ( button, creationLine ) =
                main.parentCreation
                    |> Maybe.Extra.unwrap
                        ( [ div [ Style.ids.add ]
                                [ creationButton { defaultCreation = ps.create.default, label = ps.create.label }
                                ]
                          ]
                        , []
                        )
                        (ps.create.ifCreating >> Tuple.pair [])
        in
        div [ ps.styling ]
            (button
                ++ [ HtmlUtil.searchAreaWith
                        { msg = Page.SetSearchString
                        , searchString = main.searchString
                        }
                   , table [ Style.classes.elementsWithControlsTable ]
                        (ps.tableHeader
                            :: [ tbody []
                                    (creationLine
                                        ++ (viewParents |> Paginate.page |> List.concatMap viewParent)
                                    )
                               ]
                        )
                   , div [ Style.classes.pagination ]
                        [ ViewUtil.pagerButtons
                            { msg =
                                PaginationSettings.updateCurrentPage
                                    { pagination = Page.lenses.main.pagination
                                    , items = Pagination.lenses.parents
                                    }
                                    main
                                    >> Page.SetPagination
                            , elements = viewParents
                            }
                        ]
                   ]
            )


tableHeaderWith :
    { columns : List (Html msg)
    , style : Attribute msg
    }
    -> Html msg
tableHeaderWith ps =
    thead []
        [ tr [ Style.classes.tableHeader, ps.style ]
            (ps.columns
                ++ [ th [ Style.classes.toggle ] []
                   ]
            )
        ]


lineWith :
    { rowWithControls : parent -> HtmlUtil.RowWithControls msg
    , toggleMsg : msg
    , showControls : Bool
    }
    -> parent
    -> List (Html msg)
lineWith ps parent =
    let
        row =
            parent |> ps.rowWithControls

        displayColumns =
            row
                |> .display
                |> List.map (HtmlUtil.withExtraAttributes [ ps.toggleMsg |> onClick ])

        infoRow =
            tr [ Style.classes.editing ]
                (displayColumns
                    ++ [ HtmlUtil.toggleControlsCell ps.toggleMsg ]
                )

        controlsRow =
            tr []
                [ td [ colspan <| List.length <| displayColumns ]
                    [ table [ Style.classes.elementsWithControlsTable ]
                        [ tr [] row.controls ]
                    ]
                ]
    in
    infoRow
        :: (if ps.showControls then
                [ controlsRow ]

            else
                []
           )


creationButton :
    { defaultCreation : creation
    , label : String
    }
    -> Html (Page.LogicMsg parentId parent creation update)
creationButton ps =
    button
        [ Style.classes.button.add
        , onClick <| Page.UpdateCreation <| Just <| ps.defaultCreation
        ]
        [ text <| ps.label ]


type alias LabelledButton msg =
    { msg : msg
    , name : String
    }


controlsRowWith :
    { colspan : Int
    , validInput : Bool
    , confirm : LabelledButton msg
    , cancel : LabelledButton msg
    }
    -> Html msg
controlsRowWith ps =
    tr []
        [ td [ colspan <| ps.colspan ]
            [ table [ Style.classes.elementsWithControlsTable ]
                [ tr []
                    [ td [ Style.classes.controls ]
                        [ button
                            ([ MaybeUtil.defined <| Style.classes.button.confirm
                             , MaybeUtil.defined <| disabled <| not <| ps.validInput
                             , MaybeUtil.optional ps.validInput <| onClick ps.confirm.msg
                             ]
                                |> Maybe.Extra.values
                            )
                            [ text <| ps.confirm.name ]
                        ]
                    , td [ Style.classes.controls ]
                        [ button [ Style.classes.button.cancel, onClick <| ps.cancel.msg ]
                            [ text <| ps.cancel.name ]
                        ]
                    ]
                ]
            ]
        ]
