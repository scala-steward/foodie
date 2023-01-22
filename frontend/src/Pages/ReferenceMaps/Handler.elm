module Pages.ReferenceMaps.Handler exposing (init, update)

import Addresses.Frontend
import Api.Auxiliary exposing (JWT, ReferenceMapId)
import Api.Types.ReferenceMap exposing (ReferenceMap)
import Basics.Extra exposing (flip)
import Dict
import Dict.Extra
import Maybe.Extra
import Monocle.Compose as Compose
import Monocle.Lens
import Monocle.Optional
import Pages.ReferenceMaps.Page as Page exposing (ReferenceMapState)
import Pages.ReferenceMaps.Pagination as Pagination exposing (Pagination)
import Pages.ReferenceMaps.ReferenceMapCreationClientInput as ReferenceMapCreationClientInput exposing (ReferenceMapCreationClientInput)
import Pages.ReferenceMaps.ReferenceMapUpdateClientInput as ReferenceMapUpdateClientInput exposing (ReferenceMapUpdateClientInput)
import Pages.ReferenceMaps.Requests as Requests
import Pages.ReferenceMaps.Status as Status
import Pages.Util.Links as Links
import Pages.Util.PaginationSettings as PaginationSettings
import Result.Extra
import Util.Editing as Editing exposing (Editing)
import Util.HttpUtil as HttpUtil exposing (Error)
import Util.Initialization as Initialization exposing (Initialization(..))
import Util.LensUtil as LensUtil


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( { authorizedAccess = flags.authorizedAccess
      , referenceMaps = Dict.empty
      , referenceMapToAdd = Nothing
      , searchString = ""
      , initialization = Initialization.Loading Status.initial
      , pagination = Pagination.initial
      }
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
        |> Page.lenses.referenceMapToAdd.set referenceMapToAdd
    , Cmd.none
    )


createReferenceMap : Page.Model -> ( Page.Model, Cmd Page.Msg )
createReferenceMap model =
    ( model
    , model.referenceMapToAdd
        |> Maybe.Extra.unwrap Cmd.none (ReferenceMapCreationClientInput.toCreation >> Requests.createReferenceMap model.authorizedAccess)
    )


gotCreateReferenceMapResponse : Page.Model -> Result Error ReferenceMap -> ( Page.Model, Cmd Page.Msg )
gotCreateReferenceMapResponse model dataOrError =
    dataOrError
        |> Result.Extra.unpack (\error -> ( setError error model, Cmd.none ))
            (\referenceMap ->
                ( model
                    |> LensUtil.insertAtId referenceMap.id
                        Page.lenses.referenceMaps
                        (referenceMap |> Editing.asView)
                    |> Page.lenses.referenceMapToAdd.set Nothing
                , referenceMap.id
                    |> Addresses.Frontend.referenceEntries.address
                    |> Links.loadFrontendPage model.authorizedAccess.configuration
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
        |> Page.lenses.referenceMaps.get
        |> Dict.get referenceMapId
        |> Maybe.andThen Editing.extractUpdate
        |> Maybe.Extra.unwrap
            Cmd.none
            (ReferenceMapUpdateClientInput.to
                >> (\referenceMapUpdate ->
                        Requests.saveReferenceMap
                            { authorizedAccess = model.authorizedAccess
                            , referenceMapUpdate = referenceMapUpdate
                            }
                   )
            )
    )


gotSaveReferenceMapResponse : Page.Model -> Result Error ReferenceMap -> ( Page.Model, Cmd Page.Msg )
gotSaveReferenceMapResponse model dataOrError =
    ( dataOrError
        |> Result.Extra.unpack (flip setError model)
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
    , Requests.deleteReferenceMap
        { authorizedAccess = model.authorizedAccess
        , referenceMapId = referenceMapId
        }
    )


cancelDeleteReferenceMap : Page.Model -> ReferenceMapId -> ( Page.Model, Cmd Page.Msg )
cancelDeleteReferenceMap model referenceMapId =
    ( model |> mapReferenceMapStateById referenceMapId Editing.toView
    , Cmd.none
    )


gotDeleteReferenceMapResponse : Page.Model -> ReferenceMapId -> Result Error () -> ( Page.Model, Cmd Page.Msg )
gotDeleteReferenceMapResponse model deletedId dataOrError =
    ( dataOrError
        |> Result.Extra.unpack (flip setError model)
            (\_ ->
                model
                    |> LensUtil.deleteAtId deletedId Page.lenses.referenceMaps
            )
    , Cmd.none
    )


gotFetchReferenceMapsResponse : Page.Model -> Result Error (List ReferenceMap) -> ( Page.Model, Cmd Page.Msg )
gotFetchReferenceMapsResponse model dataOrError =
    ( dataOrError
        |> Result.Extra.unpack (flip setError model)
            (\referenceMaps ->
                model
                    |> Page.lenses.referenceMaps.set (referenceMaps |> List.map Editing.asView |> Dict.Extra.fromListBy (.original >> .id))
                    |> (LensUtil.initializationField Page.lenses.initialization Status.lenses.referenceMaps).set True
            )
    , Cmd.none
    )


setPagination : Page.Model -> Pagination -> ( Page.Model, Cmd Page.Msg )
setPagination model pagination =
    ( model |> Page.lenses.pagination.set pagination
    , Cmd.none
    )


setSearchString : Page.Model -> String -> ( Page.Model, Cmd Page.Msg )
setSearchString model string =
    ( PaginationSettings.setSearchStringAndReset
        { searchStringLens =
            Page.lenses.searchString
        , paginationSettingsLens =
            Page.lenses.pagination
                |> Compose.lensWithLens Pagination.lenses.referenceMaps
        }
        model
        string
    , Cmd.none
    )


mapReferenceMapStateById : ReferenceMapId -> (Page.ReferenceMapState -> Page.ReferenceMapState) -> Page.Model -> Page.Model
mapReferenceMapStateById referenceMapId =
    Page.lenses.referenceMaps
        |> LensUtil.updateById referenceMapId


setError : Error -> Page.Model -> Page.Model
setError =
    HttpUtil.setError Page.lenses.initialization
