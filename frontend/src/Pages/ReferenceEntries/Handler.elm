module Pages.ReferenceEntries.Handler exposing (init, update)

import Addresses.Frontend
import Api.Auxiliary exposing (JWT, NutrientCode, ReferenceMapId)
import Api.Types.Nutrient exposing (Nutrient, decoderNutrient, encoderNutrient)
import Api.Types.ReferenceEntry exposing (ReferenceEntry)
import Api.Types.ReferenceMap exposing (ReferenceMap)
import Json.Decode as Decode
import Json.Encode as Encode
import Maybe.Extra
import Monocle.Compose as Compose
import Monocle.Lens as Lens
import Monocle.Optional
import Pages.ReferenceEntries.Page as Page exposing (LogicMsg(..))
import Pages.ReferenceEntries.Pagination as Pagination exposing (Pagination)
import Pages.ReferenceEntries.ReferenceEntryCreationClientInput as ReferenceEntryCreationClientInput exposing (ReferenceEntryCreationClientInput)
import Pages.ReferenceEntries.ReferenceEntryUpdateClientInput as ReferenceEntryUpdateClientInput exposing (ReferenceEntryUpdateClientInput)
import Pages.ReferenceEntries.Requests as Requests
import Pages.ReferenceMaps.ReferenceMapUpdateClientInput as ReferenceMapUpdateClientInput exposing (ReferenceMapUpdateClientInput)
import Pages.Util.Links as Links
import Pages.Util.PaginationSettings as PaginationSettings
import Pages.Util.Requests
import Pages.View.Tristate as Tristate
import Ports
import Result.Extra
import Util.DictList as DictList
import Util.Editing as Editing exposing (Editing)
import Util.HttpUtil as HttpUtil exposing (Error)
import Util.LensUtil as LensUtil


init : Page.Flags -> ( Page.Model, Cmd Page.Msg )
init flags =
    ( Page.initial flags.authorizedAccess
    , initialFetch flags |> Cmd.map Tristate.Logic
    )


initialFetch : Page.Flags -> Cmd Page.LogicMsg
initialFetch flags =
    Cmd.batch
        [ Requests.fetchReferenceEntries flags.authorizedAccess flags.referenceMapId
        , Requests.fetchReferenceMap flags.authorizedAccess flags.referenceMapId
        , Ports.doFetchNutrients ()
        ]


update : Page.Msg -> Page.Model -> ( Page.Model, Cmd Page.Msg )
update =
    Tristate.updateWith updateLogic


updateLogic : Page.LogicMsg -> Page.Model -> ( Page.Model, Cmd Page.LogicMsg )
updateLogic msg model =
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


updateReferenceEntry : Page.Model -> ReferenceEntryUpdateClientInput -> ( Page.Model, Cmd Page.LogicMsg )
updateReferenceEntry model referenceEntryUpdateClientInput =
    ( model
        |> mapReferenceEntryStateById referenceEntryUpdateClientInput.nutrientCode
            (Editing.lenses.update.set referenceEntryUpdateClientInput)
    , Cmd.none
    )


saveReferenceEntryEdit : Page.Model -> ReferenceEntryUpdateClientInput -> ( Page.Model, Cmd Page.LogicMsg )
saveReferenceEntryEdit model referenceEntryUpdateClientInput =
    ( model
    , model
        |> Tristate.foldMain Cmd.none
            (\main ->
                referenceEntryUpdateClientInput
                    |> ReferenceEntryUpdateClientInput.to main.referenceMap.original.id
                    |> Requests.saveReferenceEntry
                        { configuration = model.configuration
                        , jwt = main.jwt
                        }
            )
    )


gotSaveReferenceEntryResponse : Page.Model -> Result Error ReferenceEntry -> ( Page.Model, Cmd Page.LogicMsg )
gotSaveReferenceEntryResponse model result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model)
            (\referenceEntry ->
                model
                    |> mapReferenceEntryStateById referenceEntry.nutrientCode
                        (referenceEntry |> Editing.asView |> always)
                    |> Tristate.mapMain (LensUtil.deleteAtId referenceEntry.nutrientCode Page.lenses.main.referenceEntriesToAdd)
            )
    , Cmd.none
    )


enterEditReferenceEntry : Page.Model -> NutrientCode -> ( Page.Model, Cmd Page.LogicMsg )
enterEditReferenceEntry model nutrientCode =
    ( model
        |> mapReferenceEntryStateById nutrientCode
            (Editing.toUpdate ReferenceEntryUpdateClientInput.from)
    , Cmd.none
    )


exitEditReferenceEntryAt : Page.Model -> NutrientCode -> ( Page.Model, Cmd Page.LogicMsg )
exitEditReferenceEntryAt model nutrientCode =
    ( model
        |> mapReferenceEntryStateById nutrientCode Editing.toView
    , Cmd.none
    )


requestDeleteReferenceEntry : Page.Model -> NutrientCode -> ( Page.Model, Cmd Page.LogicMsg )
requestDeleteReferenceEntry model nutrientCode =
    ( model |> mapReferenceEntryStateById nutrientCode Editing.toDelete
    , Cmd.none
    )


confirmDeleteReferenceEntry : Page.Model -> NutrientCode -> ( Page.Model, Cmd Page.LogicMsg )
confirmDeleteReferenceEntry model nutrientCode =
    ( model
    , model
        |> Tristate.foldMain Cmd.none
            (\main ->
                Requests.deleteReferenceEntry
                    { configuration = model.configuration
                    , jwt = main.jwt
                    }
                    main.referenceMap.original.id
                    nutrientCode
            )
    )


cancelDeleteReferenceEntry : Page.Model -> NutrientCode -> ( Page.Model, Cmd Page.LogicMsg )
cancelDeleteReferenceEntry model nutrientCode =
    ( model |> mapReferenceEntryStateById nutrientCode Editing.toView
    , Cmd.none
    )


gotDeleteReferenceEntryResponse : Page.Model -> NutrientCode -> Result Error () -> ( Page.Model, Cmd Page.LogicMsg )
gotDeleteReferenceEntryResponse model nutrientCode result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model)
            (\_ ->
                model
                    |> Tristate.mapMain (LensUtil.deleteAtId nutrientCode Page.lenses.main.referenceEntries)
            )
    , Cmd.none
    )


gotFetchReferenceEntriesResponse : Page.Model -> Result Error (List ReferenceEntry) -> ( Page.Model, Cmd Page.LogicMsg )
gotFetchReferenceEntriesResponse model result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model)
            (\referenceEntries ->
                model
                    |> Tristate.mapInitial (Page.lenses.initial.referenceEntries.set (referenceEntries |> List.map Editing.asView |> DictList.fromListWithKey (.original >> .nutrientCode) |> Just))
                    |> Tristate.fromInitToMain Page.initialToMain
            )
    , Cmd.none
    )


gotFetchReferenceMapResponse : Page.Model -> Result Error ReferenceMap -> ( Page.Model, Cmd Page.LogicMsg )
gotFetchReferenceMapResponse model result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model)
            (\referenceMap ->
                model
                    |> Tristate.mapInitial (Page.lenses.initial.referenceMap.set (referenceMap |> Editing.asView |> Just))
                    |> Tristate.fromInitToMain Page.initialToMain
            )
    , Cmd.none
    )


gotFetchNutrientsResponse : Page.Model -> Result Error (List Nutrient) -> ( Page.Model, Cmd Page.LogicMsg )
gotFetchNutrientsResponse model result =
    result
        |> Result.Extra.unpack (\error -> ( Tristate.toError model error, Cmd.none ))
            (\nutrients ->
                ( model
                    |> Tristate.mapInitial (Page.lenses.initial.nutrients.set (nutrients |> DictList.fromListWithKey .code |> Just))
                    |> Tristate.fromInitToMain Page.initialToMain
                , nutrients
                    |> Encode.list encoderNutrient
                    |> Encode.encode 0
                    |> Ports.storeNutrients
                )
            )


selectNutrient : Page.Model -> NutrientCode -> ( Page.Model, Cmd Page.LogicMsg )
selectNutrient model nutrientCode =
    ( model
        |> Tristate.mapMain
            (LensUtil.insertAtId nutrientCode
                Page.lenses.main.referenceEntriesToAdd
                (ReferenceEntryCreationClientInput.default nutrientCode)
            )
    , Cmd.none
    )


deselectNutrient : Page.Model -> NutrientCode -> ( Page.Model, Cmd Page.LogicMsg )
deselectNutrient model nutrientCode =
    ( model
        |> Tristate.mapMain (LensUtil.deleteAtId nutrientCode Page.lenses.main.referenceEntriesToAdd)
    , Cmd.none
    )


addNutrient : Page.Model -> NutrientCode -> ( Page.Model, Cmd Page.LogicMsg )
addNutrient model nutrientCode =
    ( model
    , model
        |> Tristate.lenses.main.getOption
        |> Maybe.andThen
            (\main ->
                DictList.get nutrientCode main.referenceEntriesToAdd
                    |> Maybe.map
                        (ReferenceEntryCreationClientInput.toCreation main.referenceMap.original.id
                            >> Requests.addReferenceEntry
                                { configuration = model.configuration
                                , jwt = main.jwt
                                }
                        )
            )
        |> Maybe.withDefault Cmd.none
    )


gotAddReferenceEntryResponse : Page.Model -> Result Error ReferenceEntry -> ( Page.Model, Cmd Page.LogicMsg )
gotAddReferenceEntryResponse model result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model)
            (\referenceEntry ->
                model
                    |> Tristate.mapMain
                        (LensUtil.insertAtId referenceEntry.nutrientCode
                            Page.lenses.main.referenceEntries
                            (referenceEntry |> Editing.asView)
                            >> LensUtil.deleteAtId referenceEntry.nutrientCode Page.lenses.main.referenceEntriesToAdd
                        )
            )
    , Cmd.none
    )


updateAddNutrient : Page.Model -> ReferenceEntryCreationClientInput -> ( Page.Model, Cmd Page.LogicMsg )
updateAddNutrient model referenceEntryCreationClientInput =
    ( model
        |> Tristate.mapMain
            (LensUtil.insertAtId referenceEntryCreationClientInput.nutrientCode
                Page.lenses.main.referenceEntriesToAdd
                referenceEntryCreationClientInput
            )
    , Cmd.none
    )


updateNutrients : Page.Model -> String -> ( Page.Model, Cmd Page.LogicMsg )
updateNutrients model =
    Decode.decodeString (Decode.list decoderNutrient)
        >> Result.Extra.unpack (\error -> ( error |> HttpUtil.jsonErrorToError |> Tristate.toError model, Cmd.none ))
            (\nutrients ->
                ( model
                    |> Tristate.mapInitial
                        (Page.lenses.initial.nutrients.set
                            (nutrients
                                |> DictList.fromListWithKey .code
                                |> Just
                                |> Maybe.Extra.filter (DictList.isEmpty >> not)
                            )
                        )
                    |> Tristate.fromInitToMain Page.initialToMain
                , model
                    |> Tristate.lenses.initial.getOption
                    |> Maybe.Extra.filter (always (List.isEmpty nutrients))
                    |> Maybe.Extra.unwrap Cmd.none
                        (\initial ->
                            Requests.fetchNutrients
                                { configuration = model.configuration
                                , jwt = initial.jwt
                                }
                        )
                )
            )


setNutrientsSearchString : Page.Model -> String -> ( Page.Model, Cmd Page.LogicMsg )
setNutrientsSearchString model string =
    ( model
        |> Tristate.mapMain
            (PaginationSettings.setSearchStringAndReset
                { searchStringLens =
                    Page.lenses.main.nutrientsSearchString
                , paginationSettingsLens =
                    Page.lenses.main.pagination
                        |> Compose.lensWithLens Pagination.lenses.nutrients
                }
                string
            )
    , Cmd.none
    )


setReferenceEntriesSearchString : Page.Model -> String -> ( Page.Model, Cmd Page.LogicMsg )
setReferenceEntriesSearchString model string =
    ( model
        |> Tristate.mapMain
            (PaginationSettings.setSearchStringAndReset
                { searchStringLens =
                    Page.lenses.main.referenceEntriesSearchString
                , paginationSettingsLens =
                    Page.lenses.main.pagination
                        |> Compose.lensWithLens Pagination.lenses.referenceEntries
                }
                string
            )
    , Cmd.none
    )


setPagination : Page.Model -> Pagination -> ( Page.Model, Cmd Page.LogicMsg )
setPagination model pagination =
    ( model |> Tristate.mapMain (Page.lenses.main.pagination.set pagination)
    , Cmd.none
    )


updateReferenceMap : Page.Model -> ReferenceMapUpdateClientInput -> ( Page.Model, Cmd Page.LogicMsg )
updateReferenceMap model referenceMapUpdateClientInput =
    ( model
        |> Tristate.mapMain
            ((Page.lenses.main.referenceMap
                |> Compose.lensWithOptional Editing.lenses.update
             ).set
                referenceMapUpdateClientInput
            )
    , Cmd.none
    )


saveReferenceMapEdit : Page.Model -> ( Page.Model, Cmd Page.LogicMsg )
saveReferenceMapEdit model =
    ( model
    , model
        |> Tristate.lenses.main.getOption
        |> Maybe.andThen
            (\main ->
                main
                    |> Page.lenses.main.referenceMap.get
                    |> Editing.extractUpdate
                    |> Maybe.map
                        (ReferenceMapUpdateClientInput.to
                            >> (\referenceMapUpdate ->
                                    Pages.Util.Requests.saveReferenceMapWith
                                        Page.GotSaveReferenceMapResponse
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


gotSaveReferenceMapResponse : Page.Model -> Result Error ReferenceMap -> ( Page.Model, Cmd Page.LogicMsg )
gotSaveReferenceMapResponse model result =
    ( result
        |> Result.Extra.unpack (Tristate.toError model)
            (\referenceMap ->
                model
                    |> Tristate.mapMain (Page.lenses.main.referenceMap.set (referenceMap |> Editing.asView))
            )
    , Cmd.none
    )


enterEditReferenceMap : Page.Model -> ( Page.Model, Cmd Page.LogicMsg )
enterEditReferenceMap model =
    ( model
        |> Tristate.mapMain (Lens.modify Page.lenses.main.referenceMap (Editing.toUpdate ReferenceMapUpdateClientInput.from))
    , Cmd.none
    )


exitEditReferenceMap : Page.Model -> ( Page.Model, Cmd Page.LogicMsg )
exitEditReferenceMap model =
    ( model
        |> Tristate.mapMain (Lens.modify Page.lenses.main.referenceMap Editing.toView)
    , Cmd.none
    )


requestDeleteReferenceMap : Page.Model -> ( Page.Model, Cmd Page.LogicMsg )
requestDeleteReferenceMap model =
    ( model
        |> Tristate.mapMain (Lens.modify Page.lenses.main.referenceMap Editing.toDelete)
    , Cmd.none
    )


confirmDeleteReferenceMap : Page.Model -> ( Page.Model, Cmd Page.LogicMsg )
confirmDeleteReferenceMap model =
    ( model
    , model
        |> Tristate.foldMain Cmd.none
            (\main ->
                Pages.Util.Requests.deleteReferenceMapWith Page.GotDeleteReferenceMapResponse
                    { authorizedAccess =
                        { configuration = model.configuration
                        , jwt = main.jwt
                        }
                    , referenceMapId = main.referenceMap.original.id
                    }
            )
    )


cancelDeleteReferenceMap : Page.Model -> ( Page.Model, Cmd Page.LogicMsg )
cancelDeleteReferenceMap model =
    ( model
        |> Tristate.mapMain (Lens.modify Page.lenses.main.referenceMap Editing.toView)
    , Cmd.none
    )


gotDeleteReferenceMapResponse : Page.Model -> Result Error () -> ( Page.Model, Cmd Page.LogicMsg )
gotDeleteReferenceMapResponse model result =
    result
        |> Result.Extra.unpack (\error -> ( Tristate.toError model error, Cmd.none ))
            (\_ ->
                ( model
                , Links.loadFrontendPage
                    model.configuration
                    (() |> Addresses.Frontend.referenceMaps.address)
                )
            )


mapReferenceEntryStateById : NutrientCode -> (Page.ReferenceEntryState -> Page.ReferenceEntryState) -> Page.Model -> Page.Model
mapReferenceEntryStateById ingredientId =
    LensUtil.updateById ingredientId Page.lenses.main.referenceEntries
        >> Tristate.mapMain
