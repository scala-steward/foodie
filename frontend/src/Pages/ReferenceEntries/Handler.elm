module Pages.ReferenceEntries.Handler exposing (init, update)

import Addresses.Frontend
import Api.Auxiliary exposing (JWT, NutrientCode, ReferenceMapId)
import Api.Types.Nutrient exposing (Nutrient, decoderNutrient, encoderNutrient)
import Api.Types.ReferenceEntry exposing (ReferenceEntry)
import Api.Types.ReferenceMap exposing (ReferenceMap)
import Basics.Extra exposing (flip)
import Dict
import Dict.Extra
import Json.Decode as Decode
import Json.Encode as Encode
import Maybe.Extra
import Monocle.Compose as Compose
import Monocle.Lens as Lens
import Monocle.Optional
import Pages.ReferenceEntries.Page as Page exposing (Msg(..))
import Pages.ReferenceEntries.Pagination as Pagination exposing (Pagination)
import Pages.ReferenceEntries.ReferenceEntryCreationClientInput as ReferenceEntryCreationClientInput exposing (ReferenceEntryCreationClientInput)
import Pages.ReferenceEntries.ReferenceEntryUpdateClientInput as ReferenceEntryUpdateClientInput exposing (ReferenceEntryUpdateClientInput)
import Pages.ReferenceEntries.Requests as Requests
import Pages.ReferenceEntries.Status as Status
import Pages.ReferenceMaps.ReferenceMapUpdateClientInput as ReferenceMapUpdateClientInput exposing (ReferenceMapUpdateClientInput)
import Pages.Util.Links as Links
import Pages.Util.PaginationSettings as PaginationSettings
import Pages.Util.Requests
import Ports
import Result.Extra
import Util.Editing as Editing exposing (Editing)
import Util.HttpUtil as HttpUtil exposing (Error)
import Util.Initialization as Initialization
import Util.LensUtil as LensUtil


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( { authorizedAccess = flags.authorizedAccess
      , referenceMapId = flags.referenceMapId
      , referenceMap =
            Editing.asView
                { id = flags.referenceMapId
                , name = ""
                }
      , referenceEntries = Dict.empty
      , nutrients = Dict.empty
      , nutrientsSearchString = ""
      , referenceEntriesSearchString = ""
      , referenceEntriesToAdd = Dict.empty
      , initialization = Initialization.Loading Status.initial
      , pagination = Pagination.initial
      }
    , initialFetch flags
    )


initialFetch : Page.Flags -> Cmd Page.Msg
initialFetch flags =
    Cmd.batch
        [ Requests.fetchReferenceEntries flags.authorizedAccess flags.referenceMapId
        , Requests.fetchReferenceMap flags.authorizedAccess flags.referenceMapId
        , Ports.doFetchNutrients ()
        ]


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update msg model =
    case msg of
        Page.UpdateReferenceEntry referenceEntryUpdateClientInput ->
            updateReferenceEntry model referenceEntryUpdateClientInput

        Page.SaveReferenceEntryEdit referenceEntryUpdateClientInput ->
            saveReferenceEntryEdit model referenceEntryUpdateClientInput

        Page.GotSaveReferenceEntryResponse result ->
            gotSaveReferenceEntryResponse model result

        Page.EnterEditReferenceEntry nutrientCode ->
            enterEditReferenceEntry model nutrientCode

        Page.ExitEditReferenceEntryAt nutrientCode ->
            exitEditReferenceEntryAt model nutrientCode

        Page.RequestDeleteReferenceEntry nutrientCode ->
            requestDeleteReferenceEntry model nutrientCode

        Page.ConfirmDeleteReferenceEntry nutrientCode ->
            confirmDeleteReferenceEntry model nutrientCode

        Page.CancelDeleteReferenceEntry nutrientCode ->
            cancelDeleteReferenceEntry model nutrientCode

        Page.GotDeleteReferenceEntryResponse nutrientCode result ->
            gotDeleteReferenceEntryResponse model nutrientCode result

        Page.GotFetchReferenceEntriesResponse result ->
            gotFetchReferenceEntriesResponse model result

        Page.GotFetchReferenceMapResponse result ->
            gotFetchReferenceMapResponse model result

        Page.GotFetchNutrientsResponse result ->
            gotFetchNutrientsResponse model result

        Page.SelectNutrient nutrient ->
            selectNutrient model nutrient

        Page.DeselectNutrient nutrientCode ->
            deselectNutrient model nutrientCode

        Page.AddNutrient nutrientCode ->
            addNutrient model nutrientCode

        Page.GotAddReferenceEntryResponse result ->
            gotAddReferenceEntryResponse model result

        Page.UpdateAddNutrient referenceEntryCreationClientInput ->
            updateAddNutrient model referenceEntryCreationClientInput

        Page.SetNutrientsSearchString string ->
            setNutrientsSearchString model string

        Page.SetReferenceEntriesSearchString string ->
            setReferenceEntriesSearchString model string

        Page.UpdateNutrients string ->
            updateNutrients model string

        Page.SetPagination pagination ->
            setPagination model pagination

        Page.UpdateReferenceMap referenceMapUpdateClientInput ->
            updateReferenceMap model referenceMapUpdateClientInput

        Page.SaveReferenceMapEdit ->
            saveReferenceMapEdit model

        Page.GotSaveReferenceMapResponse result ->
            gotSaveReferenceMapResponse model result

        Page.EnterEditReferenceMap ->
            enterEditReferenceMap model

        Page.ExitEditReferenceMap ->
            exitEditReferenceMap model

        Page.RequestDeleteReferenceMap ->
            requestDeleteReferenceMap model

        Page.ConfirmDeleteReferenceMap ->
            confirmDeleteReferenceMap model

        Page.CancelDeleteReferenceMap ->
            cancelDeleteReferenceMap model

        Page.GotDeleteReferenceMapResponse result ->
            gotDeleteReferenceMapResponse model result


updateReferenceEntry : Page.Model -> ReferenceEntryUpdateClientInput -> ( Page.Model, Cmd Page.Msg )
updateReferenceEntry model referenceEntryUpdateClientInput =
    ( model
        |> mapReferenceEntryStateById referenceEntryUpdateClientInput.nutrientCode
            (Editing.lenses.update.set referenceEntryUpdateClientInput)
    , Cmd.none
    )


saveReferenceEntryEdit : Page.Model -> ReferenceEntryUpdateClientInput -> ( Page.Model, Cmd Page.Msg )
saveReferenceEntryEdit model referenceEntryUpdateClientInput =
    ( model
    , referenceEntryUpdateClientInput
        |> ReferenceEntryUpdateClientInput.to model.referenceMapId
        |> Requests.saveReferenceEntry model.authorizedAccess
    )


gotSaveReferenceEntryResponse : Page.Model -> Result Error ReferenceEntry -> ( Page.Model, Cmd Page.Msg )
gotSaveReferenceEntryResponse model result =
    ( result
        |> Result.Extra.unpack (flip setError model)
            (\referenceEntry ->
                model
                    |> mapReferenceEntryStateById referenceEntry.nutrientCode
                        (referenceEntry |> Editing.asView |> always)
                    |> LensUtil.deleteAtId referenceEntry.nutrientCode Page.lenses.referenceEntriesToAdd
            )
    , Cmd.none
    )


enterEditReferenceEntry : Page.Model -> NutrientCode -> ( Page.Model, Cmd Page.Msg )
enterEditReferenceEntry model nutrientCode =
    ( model
        |> mapReferenceEntryStateById nutrientCode
            (Editing.toUpdate ReferenceEntryUpdateClientInput.from)
    , Cmd.none
    )


exitEditReferenceEntryAt : Page.Model -> NutrientCode -> ( Page.Model, Cmd Page.Msg )
exitEditReferenceEntryAt model nutrientCode =
    ( model
        |> mapReferenceEntryStateById nutrientCode Editing.toView
    , Cmd.none
    )


requestDeleteReferenceEntry : Page.Model -> NutrientCode -> ( Page.Model, Cmd Page.Msg )
requestDeleteReferenceEntry model nutrientCode =
    ( model |> mapReferenceEntryStateById nutrientCode Editing.toDelete
    , Cmd.none
    )


confirmDeleteReferenceEntry : Page.Model -> NutrientCode -> ( Page.Model, Cmd Page.Msg )
confirmDeleteReferenceEntry model nutrientCode =
    ( model
    , Requests.deleteReferenceEntry model.authorizedAccess model.referenceMapId nutrientCode
    )


cancelDeleteReferenceEntry : Page.Model -> NutrientCode -> ( Page.Model, Cmd Page.Msg )
cancelDeleteReferenceEntry model nutrientCode =
    ( model |> mapReferenceEntryStateById nutrientCode Editing.toView
    , Cmd.none
    )


gotDeleteReferenceEntryResponse : Page.Model -> NutrientCode -> Result Error () -> ( Page.Model, Cmd Page.Msg )
gotDeleteReferenceEntryResponse model nutrientCode result =
    ( result
        |> Result.Extra.unpack (flip setError model)
            (\_ ->
                model
                    |> LensUtil.deleteAtId nutrientCode Page.lenses.referenceEntries
            )
    , Cmd.none
    )


gotFetchReferenceEntriesResponse : Page.Model -> Result Error (List ReferenceEntry) -> ( Page.Model, Cmd Page.Msg )
gotFetchReferenceEntriesResponse model result =
    ( result
        |> Result.Extra.unpack (flip setError model)
            (\referenceEntries ->
                model
                    |> Page.lenses.referenceEntries.set (referenceEntries |> List.map Editing.asView |> Dict.Extra.fromListBy (.original >> .nutrientCode))
                    |> (LensUtil.initializationField Page.lenses.initialization Status.lenses.referenceEntries).set True
            )
    , Cmd.none
    )


gotFetchReferenceMapResponse : Page.Model -> Result Error ReferenceMap -> ( Page.Model, Cmd Page.Msg )
gotFetchReferenceMapResponse model result =
    ( result
        |> Result.Extra.unpack (flip setError model)
            (\referenceMap ->
                model
                    |> Page.lenses.referenceMap.set (referenceMap |> Editing.asView)
                    |> (LensUtil.initializationField Page.lenses.initialization Status.lenses.referenceMap).set True
            )
    , Cmd.none
    )


gotFetchNutrientsResponse : Page.Model -> Result Error (List Nutrient) -> ( Page.Model, Cmd Page.Msg )
gotFetchNutrientsResponse model result =
    result
        |> Result.Extra.unpack (\error -> ( setError error model, Cmd.none ))
            (\nutrients ->
                ( model
                    |> LensUtil.set nutrients .code Page.lenses.nutrients
                    |> (LensUtil.initializationField Page.lenses.initialization Status.lenses.nutrients).set True
                , nutrients
                    |> Encode.list encoderNutrient
                    |> Encode.encode 0
                    |> Ports.storeNutrients
                )
            )


selectNutrient : Page.Model -> NutrientCode -> ( Page.Model, Cmd Page.Msg )
selectNutrient model nutrientCode =
    ( model
        |> LensUtil.insertAtId nutrientCode
            Page.lenses.referenceEntriesToAdd
            (ReferenceEntryCreationClientInput.default nutrientCode)
    , Cmd.none
    )


deselectNutrient : Page.Model -> NutrientCode -> ( Page.Model, Cmd Page.Msg )
deselectNutrient model nutrientCode =
    ( model
        |> LensUtil.deleteAtId nutrientCode Page.lenses.referenceEntriesToAdd
    , Cmd.none
    )


addNutrient : Page.Model -> NutrientCode -> ( Page.Model, Cmd Page.Msg )
addNutrient model nutrientCode =
    ( model
    , Dict.get nutrientCode model.referenceEntriesToAdd
        |> Maybe.map
            (ReferenceEntryCreationClientInput.toCreation model.referenceMapId
                >> Requests.addReferenceEntry model.authorizedAccess
            )
        |> Maybe.withDefault Cmd.none
    )


gotAddReferenceEntryResponse : Page.Model -> Result Error ReferenceEntry -> ( Page.Model, Cmd Page.Msg )
gotAddReferenceEntryResponse model result =
    ( result
        |> Result.Extra.unpack (flip setError model)
            (\referenceEntry ->
                model
                    |> LensUtil.insertAtId referenceEntry.nutrientCode
                        Page.lenses.referenceEntries
                        (referenceEntry |> Editing.asView)
                    |> LensUtil.deleteAtId referenceEntry.nutrientCode Page.lenses.referenceEntriesToAdd
            )
    , Cmd.none
    )


updateAddNutrient : Page.Model -> ReferenceEntryCreationClientInput -> ( Page.Model, Cmd Page.Msg )
updateAddNutrient model referenceEntryCreationClientInput =
    ( model
        |> LensUtil.insertAtId referenceEntryCreationClientInput.nutrientCode
            Page.lenses.referenceEntriesToAdd
            referenceEntryCreationClientInput
    , Cmd.none
    )


updateNutrients : Page.Model -> String -> ( Page.Model, Cmd Page.Msg )
updateNutrients model =
    Decode.decodeString (Decode.list decoderNutrient)
        >> Result.Extra.unpack (\error -> ( setJsonError error model, Cmd.none ))
            (\nutrients ->
                ( model
                    |> LensUtil.set nutrients .code Page.lenses.nutrients
                    |> (LensUtil.initializationField Page.lenses.initialization Status.lenses.nutrients).set
                        (nutrients
                            |> List.isEmpty
                            |> not
                        )
                , if List.isEmpty nutrients then
                    Requests.fetchNutrients model.authorizedAccess

                  else
                    Cmd.none
                )
            )


setNutrientsSearchString : Page.Model -> String -> ( Page.Model, Cmd Page.Msg )
setNutrientsSearchString model string =
    ( PaginationSettings.setSearchStringAndReset
        { searchStringLens =
            Page.lenses.nutrientsSearchString
        , paginationSettingsLens =
            Page.lenses.pagination
                |> Compose.lensWithLens Pagination.lenses.nutrients
        }
        model
        string
    , Cmd.none
    )


setReferenceEntriesSearchString : Page.Model -> String -> ( Page.Model, Cmd Page.Msg )
setReferenceEntriesSearchString model string =
    ( PaginationSettings.setSearchStringAndReset
        { searchStringLens =
            Page.lenses.referenceEntriesSearchString
        , paginationSettingsLens =
            Page.lenses.pagination
                |> Compose.lensWithLens Pagination.lenses.referenceEntries
        }
        model
        string
    , Cmd.none
    )


setPagination : Page.Model -> Pagination -> ( Page.Model, Cmd Page.Msg )
setPagination model pagination =
    ( model |> Page.lenses.pagination.set pagination
    , Cmd.none
    )


updateReferenceMap : Page.Model -> ReferenceMapUpdateClientInput -> ( Page.Model, Cmd Page.Msg )
updateReferenceMap model referenceMapUpdateClientInput =
    ( model
        |> (Page.lenses.referenceMap
                |> Compose.lensWithOptional Editing.lenses.update
           ).set
            referenceMapUpdateClientInput
    , Cmd.none
    )


saveReferenceMapEdit : Page.Model -> ( Page.Model, Cmd Page.Msg )
saveReferenceMapEdit model =
    ( model
    , model
        |> Page.lenses.referenceMap.get
        |> Editing.extractUpdate
        |> Maybe.Extra.unwrap
            Cmd.none
            (ReferenceMapUpdateClientInput.to
                >> (\referenceMapUpdate ->
                        Pages.Util.Requests.saveReferenceMapWith
                            Page.GotSaveReferenceMapResponse
                            { authorizedAccess = model.authorizedAccess
                            , referenceMapUpdate = referenceMapUpdate
                            }
                   )
            )
    )


gotSaveReferenceMapResponse : Page.Model -> Result Error ReferenceMap -> ( Page.Model, Cmd Page.Msg )
gotSaveReferenceMapResponse model result =
    ( result
        |> Result.Extra.unpack (flip setError model)
            (\referenceMap ->
                model
                    |> Page.lenses.referenceMap.set (referenceMap |> Editing.asView)
            )
    , Cmd.none
    )


enterEditReferenceMap : Page.Model -> ( Page.Model, Cmd Page.Msg )
enterEditReferenceMap model =
    ( model
        |> Lens.modify Page.lenses.referenceMap (Editing.toUpdate ReferenceMapUpdateClientInput.from)
    , Cmd.none
    )


exitEditReferenceMap : Page.Model -> ( Page.Model, Cmd Page.Msg )
exitEditReferenceMap model =
    ( model
        |> Lens.modify Page.lenses.referenceMap Editing.toView
    , Cmd.none
    )


requestDeleteReferenceMap : Page.Model -> ( Page.Model, Cmd Page.Msg )
requestDeleteReferenceMap model =
    ( model
        |> Lens.modify Page.lenses.referenceMap Editing.toDelete
    , Cmd.none
    )


confirmDeleteReferenceMap : Page.Model -> ( Page.Model, Cmd Page.Msg )
confirmDeleteReferenceMap model =
    ( model
    , Pages.Util.Requests.deleteReferenceMapWith Page.GotDeleteReferenceMapResponse
        { authorizedAccess = model.authorizedAccess
        , referenceMapId = model.referenceMap.original.id
        }
    )


cancelDeleteReferenceMap : Page.Model -> ( Page.Model, Cmd Page.Msg )
cancelDeleteReferenceMap model =
    ( model
        |> Lens.modify Page.lenses.referenceMap Editing.toView
    , Cmd.none
    )


gotDeleteReferenceMapResponse : Page.Model -> Result Error () -> ( Page.Model, Cmd Page.Msg )
gotDeleteReferenceMapResponse model result =
    result
        |> Result.Extra.unpack (\error -> ( model |> setError error, Cmd.none ))
            (\_ ->
                ( model
                , Links.loadFrontendPage
                    model.authorizedAccess.configuration
                    (() |> Addresses.Frontend.referenceMaps.address)
                )
            )


mapReferenceEntryStateById : NutrientCode -> (Page.ReferenceEntryState -> Page.ReferenceEntryState) -> Page.Model -> Page.Model
mapReferenceEntryStateById ingredientId =
    Page.lenses.referenceEntries
        |> LensUtil.updateById ingredientId


setError : Error -> Page.Model -> Page.Model
setError =
    HttpUtil.setError Page.lenses.initialization


setJsonError : Decode.Error -> Page.Model -> Page.Model
setJsonError =
    HttpUtil.setJsonError Page.lenses.initialization
