module Pages.ReferenceEntries.Map.View exposing (..)

import Html exposing (Attribute, Html, button, td, text)
import Html.Events exposing (onClick)
import Pages.ReferenceEntries.Map.Page as Page
import Pages.ReferenceMaps.ReferenceMapUpdateClientInput as ReferenceMapUpdateClientInput
import Pages.ReferenceMaps.View
import Pages.Util.Parent.Page
import Pages.Util.Parent.View
import Pages.Util.Style as Style


viewMain : Page.Main -> Html Page.LogicMsg
viewMain main =
    Pages.Util.Parent.View.viewMain
        { tableHeader = Pages.ReferenceMaps.View.tableHeader
        , onView =
            \referenceMap showControls ->
                Pages.ReferenceMaps.View.referenceMapLineWith
                    { controls =
                        [ td [ Style.classes.controls ]
                            [ button [ Style.classes.button.edit, Pages.Util.Parent.Page.EnterEdit |> onClick ] [ text "Edit" ] ]
                        , td [ Style.classes.controls ]
                            [ button
                                [ Style.classes.button.delete, Pages.Util.Parent.Page.RequestDelete |> onClick ]
                                [ text "Delete" ]
                            ]
                        ]
                    , toggleCommand = Pages.Util.Parent.Page.ToggleControls
                    , showControls = showControls
                    }
                    referenceMap
        , onUpdate =
            Pages.ReferenceMaps.View.editReferenceMapLineWith
                { saveMsg = Pages.Util.Parent.Page.SaveEdit
                , nameLens = ReferenceMapUpdateClientInput.lenses.name
                , updateMsg = Pages.Util.Parent.Page.Edit
                , confirmName = "Save"
                , cancelMsg = Pages.Util.Parent.Page.ExitEdit
                , cancelName = "Cancel"
                , rowStyles = []
                , toggleCommand = Just Pages.Util.Parent.Page.ToggleControls
                }
                |> always
        , onDelete =
            Pages.ReferenceMaps.View.referenceMapLineWith
                { controls =
                    [ td [ Style.classes.controls ]
                        [ button [ Style.classes.button.delete, onClick <| Pages.Util.Parent.Page.ConfirmDelete ] [ text "Delete?" ] ]
                    , td [ Style.classes.controls ]
                        [ button
                            [ Style.classes.button.confirm, onClick <| Pages.Util.Parent.Page.CancelDelete ]
                            [ text "Cancel" ]
                        ]
                    ]
                , toggleCommand = Pages.Util.Parent.Page.ToggleControls
                , showControls = True
                }
        }
        main
