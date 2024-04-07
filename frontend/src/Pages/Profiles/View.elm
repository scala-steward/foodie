module Pages.Profiles.View exposing (..)

import Configuration exposing (Configuration)
import Html exposing (Html)
import Pages.Profiles.Page as Page
import Pages.Util.ParentEditor.View
import Pages.View.Tristate as Tristate


view : Page.Model -> Html Page.Msg
view =
    Tristate.view
        { viewMain = viewMain
        , showLoginRedirect = True
        }


viewMain : Configuration -> Page.Main -> Html Page.LogicMsg
viewMain =
    Pages.Util.ParentEditor.View.viewParentsWith
        { currentPage = ViewUtil.Profiles
        , matchesSearchText = \string referenceMap -> SearchUtil.search string referenceMap.name
        , sort = List.sortBy (.original >> .name)
        , tableHeader = tableHeader
        , viewLine = viewProfileLine
        , updateLine = .id >> updateProfileLine
        , deleteLine = deleteProfileLine
        , create =
            { ifCreating = createProfileLine
            , default = ProfileCreationClientInput.default
            , label = "New reference map"
            , update = Pages.Util.ParentEditor.Page.UpdateCreation
            }
        , setSearchString = Pages.Util.ParentEditor.Page.SetSearchString
        , setPagination = Pages.Util.ParentEditor.Page.SetPagination
        , styling = Style.ids.addProfileView
        }


tableHeader : Html msg
tableHeader =
    Pages.Util.ParentEditor.View.tableHeaderWith
        { columns = [ th [] [ label [] [ text "Name" ] ] ]
        , style = Style.classes.referenceMapEditTable
        }


viewProfileLine : Configuration -> Profile -> Bool -> List (Html Page.LogicMsg)
viewProfileLine configuration referenceMap showControls =
    referenceMapLineWith
        { controls =
            [ td [ Style.classes.controls ]
                [ button [ Style.classes.button.edit, Pages.Util.ParentEditor.Page.EnterEdit referenceMap.id |> onClick ] [ text "Edit" ] ]
            , td [ Style.classes.controls ]
                [ Links.linkButton
                    { url = Links.frontendPage configuration <| Addresses.Frontend.referenceEntries.address <| referenceMap.id
                    , attributes = [ Style.classes.button.editor ]
                    , children = [ text "Entries" ]
                    }
                ]
            , td [ Style.classes.controls ]
                [ button
                    [ Style.classes.button.delete, onClick <| Pages.Util.ParentEditor.Page.RequestDelete <| referenceMap.id ]
                    [ text "Delete" ]
                ]
            , td [ Style.classes.controls ]
                [ button
                    [ Style.classes.button.confirm, onClick <| Pages.Util.ParentEditor.Page.Duplicate <| referenceMap.id ]
                    [ text "Duplicate" ]
                ]
            ]
        , toggleMsg = Pages.Util.ParentEditor.Page.ToggleControls referenceMap.id
        , showControls = showControls
        }
        referenceMap


deleteProfileLine : Profile -> List (Html Page.LogicMsg)
deleteProfileLine referenceMap =
    referenceMapLineWith
        { controls =
            [ td [ Style.classes.controls ]
                [ button
                    [ Style.classes.button.delete, onClick <| Pages.Util.ParentEditor.Page.ConfirmDelete <| referenceMap.id ]
                    [ text "Delete?" ]
                ]
            , td [ Style.classes.controls ]
                [ button
                    [ Style.classes.button.confirm, onClick <| Pages.Util.ParentEditor.Page.CancelDelete <| referenceMap.id ]
                    [ text "Cancel" ]
                ]
            ]
        , toggleMsg = Pages.Util.ParentEditor.Page.ToggleControls referenceMap.id
        , showControls = True
        }
        referenceMap


referenceMapInfoColumns : Profile -> List (HtmlUtil.Column msg)
referenceMapInfoColumns referenceMap =
    [ { attributes = [ Style.classes.editable ]
      , children = [ label [] [ text referenceMap.name ] ]
      }
    ]


referenceMapLineWith :
    { controls : List (Html msg)
    , toggleMsg : msg
    , showControls : Bool
    }
    -> Profile
    -> List (Html msg)
referenceMapLineWith ps =
    Pages.Util.ParentEditor.View.lineWith
        { rowWithControls =
            \referenceMap ->
                { display = referenceMapInfoColumns referenceMap
                , controls = ps.controls
                }
        , toggleMsg = ps.toggleMsg
        , showControls = ps.showControls
        }


updateProfileLine : ProfileId -> ProfileUpdateClientInput -> List (Html Page.LogicMsg)
updateProfileLine referenceMapId =
    editProfileLineWith
        { saveMsg = Pages.Util.ParentEditor.Page.SaveEdit referenceMapId
        , nameLens = ProfileUpdateClientInput.lenses.name
        , updateMsg = Pages.Util.ParentEditor.Page.Edit referenceMapId
        , confirmName = "Save"
        , cancelMsg = Pages.Util.ParentEditor.Page.ExitEdit referenceMapId
        , cancelName = "Cancel"
        , rowStyles = [ Style.classes.editLine ]
        , toggleCommand = Pages.Util.ParentEditor.Page.ToggleControls referenceMapId |> Just
        }


createProfileLine : ProfileCreationClientInput -> List (Html Page.LogicMsg)
createProfileLine referenceMapCreationClientInput =
    editProfileLineWith
        { saveMsg = Pages.Util.ParentEditor.Page.Create
        , nameLens = ProfileCreationClientInput.lenses.name
        , updateMsg = Just >> Pages.Util.ParentEditor.Page.UpdateCreation
        , confirmName = "Add"
        , cancelMsg = Pages.Util.ParentEditor.Page.UpdateCreation Nothing
        , cancelName = "Cancel"
        , rowStyles = [ Style.classes.editLine ]
        , toggleCommand = Nothing
        }
        referenceMapCreationClientInput


editProfileLineWith :
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
editProfileLineWith handling editedValue =
    let
        validInput =
            handling.nameLens.get editedValue
                |> ValidatedInput.isValid

        validatedSaveAction =
            MaybeUtil.optional validInput <| onEnter handling.saveMsg

        infoColumns =
            [ td [ Style.classes.editable ]
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

        controlsRow =
            Pages.Util.ParentEditor.View.controlsRowWith
                { colspan = infoColumns |> List.length
                , validInput = validInput
                , confirm =
                    { msg = handling.saveMsg
                    , name = handling.confirmName
                    }
                , cancel =
                    { msg = handling.cancelMsg
                    , name = handling.cancelName
                    }
                }

        commandToggle =
            handling.toggleCommand
                |> Maybe.Extra.unwrap []
                    (HtmlUtil.toggleControlsCell >> List.singleton)
    in
    [ tr handling.rowStyles (infoColumns ++ commandToggle)
    , controlsRow
    ]
