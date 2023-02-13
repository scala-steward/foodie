module Pages.ReferenceMaps.Handler exposing (init, update)

import Addresses.Frontend
import Api.Auxiliary exposing (JWT, ReferenceMapId)
import Api.Types.ReferenceMap exposing (ReferenceMap)
import Monocle.Compose as Compose
import Monocle.Optional
import Pages.ReferenceMaps.Page as Page exposing (ReferenceMapState)
import Pages.ReferenceMaps.Pagination as Pagination exposing (Pagination)
import Pages.ReferenceMaps.ReferenceMapCreationClientInput as ReferenceMapCreationClientInput exposing (ReferenceMapCreationClientInput)
import Pages.ReferenceMaps.ReferenceMapUpdateClientInput as ReferenceMapUpdateClientInput exposing (ReferenceMapUpdateClientInput)
import Pages.ReferenceMaps.Requests as Requests
import Pages.Util.Links as Links
import Pages.Util.PaginationSettings as PaginationSettings
import Pages.View.Tristate as Tristate
import Result.Extra
import Util.DictList as DictList
import Util.Editing as Editing exposing (Editing)
import Util.HttpUtil exposing (Error)
import Util.LensUtil as LensUtil


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( Page.initial flags.authorizedAccess
    , Requests.fetchReferenceMaps flags.authorizedAccess
    )


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update msg model =
    case msg of
        Page.UpdateReferenceMapCreation referenceMapCreationClientInput ->
            updateReferenceMapCreation model referenceMapCreationClientInput

        Page.CreateReferenceMap ->
            createReferenceMap model

        Page.GotCreateReferenceMapResponse dataOrError ->
            gotCreateReferenceMapResponse model dataOrError

        Page.UpdateReferenceMap referenceMapUpdate ->
            updateReferenceMap model referenceMapUpdate

        Page.SaveReferenceMapEdit referenceMapId ->
            saveReferenceMapEdit model referenceMapId

        Page.GotSaveReferenceMapResponse dataOrError ->
            gotSaveReferenceMapResponse model dataOrError

        Page.EnterEditReferenceMap referenceMapId ->
            enterEditReferenceMap model referenceMapId

        Page.ExitEditReferenceMapAt referenceMapId ->
            exitEditReferenceMapAt model referenceMapId

        Page.RequestDeleteReferenceMap referenceMapId ->
            requestDeleteReferenceMap model referenceMapId

        Page.ConfirmDeleteReferenceMap referenceMapId ->
            confirmDeleteReferenceMap model referenceMapId

        Page.CancelDeleteReferenceMap referenceMapId ->
            cancelDeleteReferenceMap model referenceMapId

        Page.GotDeleteReferenceMapResponse deletedId dataOrError ->
            gotDeleteReferenceMapResponse model deletedId dataOrError

        Page.GotFetchReferenceMapsResponse dataOrError ->
            gotFetchReferenceMapsResponse model dataOrError

        Page.SetPagination pagination ->
            setPagination model pagination

        Page.SetSearchString string ->
            setSearchString model string


updateReferenceMapCreation : Page.Model -> Maybe ReferenceMapCreationClientInput -> ( Page.Model, Cmd Page.Msg )
updateReferenceMapCreation model referenceMapToAdd =
    ( model
        |> Tristate.mapMain (Page.lenses.main.referenceMapToAdd.set referenceMapToAdd)
    , Cmd.none
    )


createReferenceMap : Page.Model -> ( Page.Model, Cmd Page.Msg )
createReferenceMap model =
    ( model
    , model
        |> Tristate.lenses.main.getOption
        |> Maybe.andThen
            (\main ->
                main
                    |> Page.lenses.main.referenceMapToAdd.get
                    |> Maybe.map
                        (ReferenceMapCreationClientInput.toCreation
                            >> Requests.createReferenceMap
                                { configuration = model.configuration
                                , jwt = main.jwt
                                }
                        )
            )
        |> Maybe.withDefault Cmd.none
    )


gotCreateReferenceMapResponse : Page.Model -> Result Error ReferenceMap -> ( Page.Model, Cmd Page.Msg )
gotCreateReferenceMapResponse model dataOrError =
    dataOrError
        |> Result.Extra.unpack (\error -> ( Tristate.toError model.configuration error, Cmd.none ))
            (\referenceMap ->
                ( model
                    |> Tristate.mapMain
                        (LensUtil.insertAtId referenceMap.id
                            Page.lenses.main.referenceMaps
                            (referenceMap |> Editing.asView)
                            >> Page.lenses.main.referenceMapToAdd.set Nothing
                        )
                , referenceMap.id
                    |> Addresses.Frontend.referenceEntries.address
                    |> Links.loadFrontendPage model.configuration
                )
            )


updateReferenceMap : Page.Model -> ReferenceMapUpdateClientInput -> ( Page.Model, Cmd Page.Msg )
updateReferenceMap model referenceMapUpdate =
    ( model
        |> mapReferenceMapStateById referenceMapUpdate.id
            (Editing.lenses.update.set referenceMapUpdate)
    , Cmd.none
    )


saveReferenceMapEdit : Page.Model -> ReferenceMapId -> ( Page.Model, Cmd Page.Msg )
saveReferenceMapEdit model referenceMapId =
    ( model
    , model
        |> Tristate.lenses.main.getOption
        |> Maybe.andThen
            (\main ->
                main
                    |> Page.lenses.main.referenceMaps.get
                    |> DictList.get referenceMapId
                    |> Maybe.andThen Editing.extractUpdate
                    |> Maybe.map
                        (ReferenceMapUpdateClientInput.to
                            >> (\referenceMapUpdate ->
                                    Requests.saveReferenceMap
                                        { authorizedAccess =
                                            { configuration = model.configuration
                                            , jwt = main.jwt
                                            }
                                        , referenceMapUpdate = referenceMapUpdate
                                        }
                               )
                        )
            )
        |> Maybe.withDefault Cmd.none
    )


gotSaveReferenceMapResponse : Page.Model -> Result Error ReferenceMap -> ( Page.Model, Cmd Page.Msg )
gotSaveReferenceMapResponse model dataOrError =
    ( dataOrError
        |> Result.Extra.unpack (Tristate.toError model.configuration)
            (\referenceMap ->
                model
                    |> mapReferenceMapStateById referenceMap.id
                        (referenceMap |> Editing.asView |> always)
            )
    , Cmd.none
    )


enterEditReferenceMap : Page.Model -> ReferenceMapId -> ( Page.Model, Cmd Page.Msg )
enterEditReferenceMap model referenceMapId =
    ( model
        |> mapReferenceMapStateById referenceMapId
            (Editing.toUpdate ReferenceMapUpdateClientInput.from)
    , Cmd.none
    )


exitEditReferenceMapAt : Page.Model -> ReferenceMapId -> ( Page.Model, Cmd Page.Msg )
exitEditReferenceMapAt model referenceMapId =
    ( model |> mapReferenceMapStateById referenceMapId Editing.toView
    , Cmd.none
    )


requestDeleteReferenceMap : Page.Model -> ReferenceMapId -> ( Page.Model, Cmd Page.Msg )
requestDeleteReferenceMap model referenceMapId =
    ( model |> mapReferenceMapStateById referenceMapId Editing.toDelete
    , Cmd.none
    )


confirmDeleteReferenceMap : Page.Model -> ReferenceMapId -> ( Page.Model, Cmd Page.Msg )
confirmDeleteReferenceMap model referenceMapId =
    ( model
    , model
        |> Tristate.foldMain Cmd.none
            (\main ->
                Requests.deleteReferenceMap
                    { authorizedAccess =
                        { configuration = model.configuration
                        , jwt = main.jwt
                        }
                    , referenceMapId = referenceMapId
                    }
            )
    )


cancelDeleteReferenceMap : Page.Model -> ReferenceMapId -> ( Page.Model, Cmd Page.Msg )
cancelDeleteReferenceMap model referenceMapId =
    ( model |> mapReferenceMapStateById referenceMapId Editing.toView
    , Cmd.none
    )


gotDeleteReferenceMapResponse : Page.Model -> ReferenceMapId -> Result Error () -> ( Page.Model, Cmd Page.Msg )
gotDeleteReferenceMapResponse model deletedId dataOrError =
    ( dataOrError
        |> Result.Extra.unpack (Tristate.toError model.configuration)
            (\_ ->
                model
                    |> Tristate.mapMain (LensUtil.deleteAtId deletedId Page.lenses.main.referenceMaps)
            )
    , Cmd.none
    )


gotFetchReferenceMapsResponse : Page.Model -> Result Error (List ReferenceMap) -> ( Page.Model, Cmd Page.Msg )
gotFetchReferenceMapsResponse model dataOrError =
    ( dataOrError
        |> Result.Extra.unpack (Tristate.toError model.configuration)
            (\referenceMaps ->
                model
                    |> Tristate.mapInitial (Page.lenses.initial.referenceMaps.set (referenceMaps |> List.map Editing.asView |> DictList.fromListWithKey (.original >> .id) |> Just))
                    |> Tristate.fromInitToMain Page.initialToMain
            )
    , Cmd.none
    )


setPagination : Page.Model -> Pagination -> ( Page.Model, Cmd Page.Msg )
setPagination model pagination =
    ( model |> Tristate.mapMain (Page.lenses.main.pagination.set pagination)
    , Cmd.none
    )


setSearchString : Page.Model -> String -> ( Page.Model, Cmd Page.Msg )
setSearchString model string =
    ( model
        |> Tristate.mapMain
            (PaginationSettings.setSearchStringAndReset
                { searchStringLens =
                    Page.lenses.main.searchString
                , paginationSettingsLens =
                    Page.lenses.main.pagination
                        |> Compose.lensWithLens Pagination.lenses.referenceMaps
                }
                string
            )
    , Cmd.none
    )


mapReferenceMapStateById : ReferenceMapId -> (Page.ReferenceMapState -> Page.ReferenceMapState) -> Page.Model -> Page.Model
mapReferenceMapStateById referenceMapId =
    LensUtil.updateById referenceMapId Page.lenses.main.referenceMaps
        >> Tristate.mapMain
