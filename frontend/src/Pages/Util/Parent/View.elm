module Pages.Util.Parent.View exposing (..)

import Html exposing (Attribute, Html, table, tbody)
import Pages.Util.Parent.Page as Page
import Pages.Util.Style as Style
import Util.Editing as Editing


viewMain :
    { tableHeader : List (Html (Page.LogicMsg parent update))
    , onView : parent -> Bool -> List (Html (Page.LogicMsg parent update))
    , onUpdate : parent -> update -> List (Html (Page.LogicMsg parent update))
    , onDelete : parent -> List (Html (Page.LogicMsg parent update))
    }
    -> Page.Main parent update
    -> Html (Page.LogicMsg parent update)
viewMain ps main =
    table [ Style.classes.elementsWithControlsTable ]
        (ps.tableHeader
            ++ [ tbody []
                    (Editing.unpack
                        { onView = ps.onView
                        , onUpdate = ps.onUpdate
                        , onDelete =
                            ps.onDelete
                        }
                        main.parent
                    )
               ]
        )
