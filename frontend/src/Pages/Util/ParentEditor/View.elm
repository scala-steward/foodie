module Pages.Util.ParentEditor.View exposing (..)

import Configuration exposing (Configuration)
import Either exposing (Either)
import Html exposing (Attribute, Html, div, table, tbody)
import Monocle.Compose as Compose
import Monocle.Lens exposing (Lens)
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
    , nameLens : Lens parent String
    , sortBy : parent -> comparable
    , tableHeader : List (Html (Page.LogicMsg parentId parent creation update))
    , viewLine : Configuration -> parent -> Bool -> List (Html (Page.LogicMsg parentId parent creation update))
    , updateLine : parent -> update -> List (Html (Page.LogicMsg parentId parent creation update))
    , deleteLine : parent -> List (Html (Page.LogicMsg parentId parent creation update))
    , create : Maybe creation -> Either (List (Html (Page.LogicMsg parentId parent creation update))) (List (Html (Page.LogicMsg parentId parent creation update)))
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
        div [ Style.classes.addView ]
            (button
                ++ [ HtmlUtil.searchAreaWith
                        { msg = Page.SetSearchString
                        , searchString = main.searchString
                        }
                   , table [ Style.classes.elementsWithControlsTable ]
                        (ps.tableHeader
                            ++ [ tbody []
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
