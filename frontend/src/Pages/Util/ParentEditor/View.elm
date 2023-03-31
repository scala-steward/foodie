module Pages.Util.ParentEditor.View exposing (..)

import Configuration exposing (Configuration)
import Either exposing (Either)
import Html exposing (Attribute, Html, div, table, tbody, td, th, thead, tr)
import Html.Attributes exposing (colspan)
import Html.Events exposing (onClick)
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


viewParentsWith :
    { currentPage : ViewUtil.Page
    , matchesSearchText : String -> parent -> Bool
    , sortBy : parent -> comparable
    , tableHeader : Html (Page.LogicMsg parentId parent creation update)
    , viewLine : Configuration -> parent -> Bool -> List (Html (Page.LogicMsg parentId parent creation update))
    , updateLine : parent -> update -> List (Html (Page.LogicMsg parentId parent creation update))
    , deleteLine : parent -> List (Html (Page.LogicMsg parentId parent creation update))
    , create : Maybe creation -> Either (List (Html (Page.LogicMsg parentId parent creation update))) (List (Html (Page.LogicMsg parentId parent creation update)))
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
                ps.create main.parentCreation
                    |> Either.unpack (\l -> ( l, [] )) (\r -> ( [], r ))
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


tableHeaderWith : { columns : List (Html msg) } -> Html msg
tableHeaderWith ps =
    thead []
        [ tr [ Style.classes.tableHeader, Style.classes.mealEditTable ]
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
