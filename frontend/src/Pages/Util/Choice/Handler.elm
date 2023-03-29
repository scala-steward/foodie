module Pages.Util.Choice.Handler exposing (updateLogic)

import Basics.Extra exposing (flip)
import Monocle.Compose as Compose
import Monocle.Lens exposing (Lens)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.Choice.Page as ChoiceGroup
import Pages.Util.Choice.Pagination as Pagination
import Pages.Util.PaginationSettings as PaginationSettings
import Pages.View.Tristate as Tristate
import Result.Extra
import Util.DictList as DictList
import Util.Editing as Editing exposing (Editing)
import Util.LensUtil as LensUtil


updateLogic :
    { idOfElement : element -> elementId
    , idOfUpdate : update -> elementId
    , idOfChoice : choice -> choiceId
    , choiceIdOfElement : element -> choiceId
    , choiceIdOfCreation : creation -> choiceId
    , toUpdate : element -> update
    , toCreation : choice -> parentId -> creation
    , createElement : AuthorizedAccess -> parentId -> creation -> Cmd (ChoiceGroup.LogicMsg elementId element update choiceId choice creation)
    , saveElement : AuthorizedAccess -> parentId -> update -> Cmd (ChoiceGroup.LogicMsg elementId element update choiceId choice creation)
    , deleteElement : AuthorizedAccess -> parentId -> elementId -> Cmd (ChoiceGroup.LogicMsg elementId element update choiceId choice creation)
    , storeChoices : List choice -> Cmd (ChoiceGroup.LogicMsg elementId element update choiceId choice creation)
    }
    -> ChoiceGroup.LogicMsg elementId element update choiceId choice creation
    -> ChoiceGroup.Model parentId elementId element update choiceId choice creation
    -> ( ChoiceGroup.Model parentId elementId element update choiceId choice creation, Cmd (ChoiceGroup.LogicMsg elementId element update choiceId choice creation) )
updateLogic ps msg model =
    let
        edit update =
            ( model
                |> mapElementStateById (update |> ps.idOfUpdate)
                    (Editing.lenses.update.set update)
            , Cmd.none
            )

        saveEdit elementUpdateClientInput =
            ( model
            , model
                |> Tristate.foldMain Cmd.none
                    (\main ->
                        elementUpdateClientInput
                            |> ps.saveElement
                                { configuration = model.configuration
                                , jwt = main.jwt
                                }
                                main.parentId
                    )
            )

        gotSaveEditResponse result =
            ( result
                |> Result.Extra.unpack (Tristate.toError model)
                    (\element ->
                        model
                            |> mapElementStateById (element |> ps.idOfElement)
                                (Editing.asViewWithElement element)
                    )
            , Cmd.none
            )

        toggleControls elementId =
            ( model
                |> mapElementStateById elementId Editing.toggleControls
            , Cmd.none
            )

        enterEdit elementId =
            ( model
                |> mapElementStateById elementId (Editing.toUpdate ps.toUpdate)
            , Cmd.none
            )

        exitEdit elementId =
            ( model
                |> mapElementStateById elementId Editing.toView
            , Cmd.none
            )

        requestDelete elementId =
            ( model
                |> mapElementStateById elementId Editing.toDelete
            , Cmd.none
            )

        confirmDelete elementId =
            ( model
            , model
                |> Tristate.foldMain Cmd.none
                    (\main ->
                        ps.deleteElement
                            { configuration = model.configuration
                            , jwt = main.jwt
                            }
                            main.parentId
                            elementId
                    )
            )

        cancelDelete elementId =
            ( model
                |> mapElementStateById elementId Editing.toView
            , Cmd.none
            )

        gotDeleteResponse elementId result =
            ( result
                |> Result.Extra.unpack (Tristate.toError model)
                    (model
                        |> Tristate.mapMain
                            (LensUtil.deleteAtId elementId
                                ChoiceGroup.lenses.main.elements
                            )
                        |> always
                    )
            , Cmd.none
            )

        gotFetchElementsResponse result =
            ( result
                |> Result.Extra.unpack (Tristate.toError model)
                    (\elements ->
                        model
                            |> Tristate.mapInitial
                                (ChoiceGroup.lenses.initial.elements.set
                                    (elements
                                        |> DictList.fromListWithKey ps.idOfElement
                                        |> Just
                                    )
                                )
                    )
            , Cmd.none
            )

        gotFetchChoicesResponse result =
            result
                |> Result.Extra.unpack (\error -> ( Tristate.toError model error, Cmd.none ))
                    (\choices ->
                        ( model
                            |> Tristate.mapInitial
                                (ChoiceGroup.lenses.initial.choices.set
                                    (choices |> DictList.fromListWithKey ps.idOfChoice |> Just)
                                )
                        , choices
                            |> ps.storeChoices
                        )
                    )

        toggleChoiceControls choiceId =
            ( model
                |> Tristate.mapMain (LensUtil.updateById choiceId ChoiceGroup.lenses.main.choices Editing.toggleControls)
            , Cmd.none
            )

        selectChoice choice =
            ( model
                |> Tristate.mapMain
                    (\main ->
                        main
                            |> LensUtil.updateById (choice |> ps.idOfChoice)
                                ChoiceGroup.lenses.main.choices
                                (Editing.toUpdate (flip ps.toCreation main.parentId))
                    )
            , Cmd.none
            )

        deselectChoice choiceId =
            ( model
                |> Tristate.mapMain
                    (LensUtil.updateById choiceId
                        ChoiceGroup.lenses.main.choices
                        Editing.toView
                    )
            , Cmd.none
            )

        create choiceId =
            ( model
            , model
                |> Tristate.lenses.main.getOption
                |> Maybe.andThen
                    (\main ->
                        main
                            |> (ChoiceGroup.lenses.main.choices
                                    |> Compose.lensWithOptional (LensUtil.dictByKey choiceId)
                                    |> Compose.optionalWithOptional Editing.lenses.update
                               ).getOption
                            |> Maybe.map
                                (ps.createElement
                                    { configuration = model.configuration
                                    , jwt = main.jwt
                                    }
                                    main.parentId
                                )
                    )
                |> Maybe.withDefault Cmd.none
            )

        gotCreateResponse result =
            ( result
                |> Result.Extra.unpack (Tristate.toError model)
                    (\element ->
                        model
                            |> Tristate.mapMain
                                (LensUtil.insertAtId (element |> ps.idOfElement)
                                    ChoiceGroup.lenses.main.elements
                                    (element |> Editing.asView)
                                    >> LensUtil.updateById (element |> ps.choiceIdOfElement)
                                        ChoiceGroup.lenses.main.choices
                                        Editing.toView
                                )
                    )
            , Cmd.none
            )

        updateCreation elementCreationClientInput =
            ( model
                |> Tristate.mapMain
                    (LensUtil.updateById (elementCreationClientInput |> ps.choiceIdOfCreation)
                        ChoiceGroup.lenses.main.choices
                        (Editing.lenses.update.set elementCreationClientInput)
                    )
            , Cmd.none
            )

        setPagination pagination =
            ( model
                |> Tristate.mapMain (ChoiceGroup.lenses.main.pagination.set pagination)
            , Cmd.none
            )

        setElementsSearchString string =
            ( model
                |> Tristate.mapMain
                    (PaginationSettings.setSearchStringAndReset
                        { searchStringLens =
                            ChoiceGroup.lenses.main.elementsSearchString
                        , paginationSettingsLens =
                            ChoiceGroup.lenses.main.pagination |> Compose.lensWithLens Pagination.lenses.elements
                        }
                        string
                    )
            , Cmd.none
            )

        setChoicesSearchString string =
            ( model
                |> Tristate.mapMain
                    (PaginationSettings.setSearchStringAndReset
                        { searchStringLens =
                            ChoiceGroup.lenses.main.choicesSearchString
                        , paginationSettingsLens =
                            ChoiceGroup.lenses.main.pagination
                                |> Compose.lensWithLens Pagination.lenses.choices
                        }
                        string
                    )
            , Cmd.none
            )
    in
    case msg of
        ChoiceGroup.Edit update ->
            edit update

        ChoiceGroup.SaveEdit update ->
            saveEdit update

        ChoiceGroup.GotSaveEditResponse result ->
            gotSaveEditResponse result

        ChoiceGroup.ToggleControls elementId ->
            toggleControls elementId

        ChoiceGroup.EnterEdit elementId ->
            enterEdit elementId

        ChoiceGroup.ExitEdit elementId ->
            exitEdit elementId

        ChoiceGroup.RequestDelete elementId ->
            requestDelete elementId

        ChoiceGroup.ConfirmDelete elementId ->
            confirmDelete elementId

        ChoiceGroup.CancelDelete elementId ->
            cancelDelete elementId

        ChoiceGroup.GotDeleteResponse elementId result ->
            gotDeleteResponse elementId result

        ChoiceGroup.GotFetchElementsResponse result ->
            gotFetchElementsResponse result

        ChoiceGroup.GotFetchChoicesResponse result ->
            gotFetchChoicesResponse result

        ChoiceGroup.ToggleChoiceControls choiceId ->
            toggleChoiceControls choiceId

        ChoiceGroup.SelectChoice choice ->
            selectChoice choice

        ChoiceGroup.DeselectChoice choiceId ->
            deselectChoice choiceId

        ChoiceGroup.Create choiceId ->
            create choiceId

        ChoiceGroup.GotCreateResponse result ->
            gotCreateResponse result

        ChoiceGroup.UpdateCreation creation ->
            updateCreation creation

        ChoiceGroup.SetPagination pagination ->
            setPagination pagination

        ChoiceGroup.SetElementsSearchString string ->
            setElementsSearchString string

        ChoiceGroup.SetChoicesSearchString string ->
            setChoicesSearchString string


mapElementStateById :
    elementId
    -> (Editing element update -> Editing element update)
    -> ChoiceGroup.Model parentId elementId element update choiceId choice creation
    -> ChoiceGroup.Model parentId elementId element update choiceId choice creation
mapElementStateById elementId =
    (ChoiceGroup.lenses.main.elements
        |> LensUtil.updateById elementId
    )
        >> Tristate.mapMain
