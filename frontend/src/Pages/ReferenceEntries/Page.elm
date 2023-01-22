module Pages.ReferenceEntries.Page exposing (..)

import Api.Auxiliary exposing (JWT, NutrientCode, ReferenceMapId)
import Api.Types.Nutrient exposing (Nutrient)
import Api.Types.ReferenceEntry exposing (ReferenceEntry)
import Api.Types.ReferenceMap exposing (ReferenceMap)
import Dict exposing (Dict)
import Monocle.Lens exposing (Lens)
import Pages.ReferenceEntries.Pagination exposing (Pagination)
import Pages.ReferenceEntries.ReferenceEntryCreationClientInput exposing (ReferenceEntryCreationClientInput)
import Pages.ReferenceEntries.ReferenceEntryUpdateClientInput exposing (ReferenceEntryUpdateClientInput)
import Pages.ReferenceEntries.Status exposing (Status)
import Pages.ReferenceMaps.ReferenceMapUpdateClientInput exposing (ReferenceMapUpdateClientInput)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Util.Editing exposing (Editing)
import Util.HttpUtil exposing (Error)
import Util.Initialization exposing (Initialization)


type alias Model =
    { authorizedAccess : AuthorizedAccess
    , referenceMapId : ReferenceMapId
    , referenceMap : Editing ReferenceMap ReferenceMapUpdateClientInput
    , referenceEntries : ReferenceEntryStateMap
    , nutrients : NutrientMap
    , nutrientsSearchString : String
    , referenceEntriesSearchString : String
    , referenceEntriesToAdd : AddNutrientMap
    , initialization : Initialization Status
    , pagination : Pagination
    }


type alias ReferenceEntryState =
    Editing ReferenceEntry ReferenceEntryUpdateClientInput


type alias NutrientMap =
    Dict NutrientCode Nutrient


type alias AddNutrientMap =
    Dict NutrientCode ReferenceEntryCreationClientInput


type alias ReferenceEntryStateMap =
    Dict NutrientCode ReferenceEntryState


type alias Flags =
    { authorizedAccess : AuthorizedAccess
    , referenceMapId : ReferenceMapId
    }


lenses :
    { referenceMap : Lens Model (Editing ReferenceMap ReferenceMapUpdateClientInput)
    , referenceEntries : Lens Model ReferenceEntryStateMap
    , referenceEntriesToAdd : Lens Model AddNutrientMap
    , nutrients : Lens Model NutrientMap
    , nutrientsSearchString : Lens Model String
    , referenceEntriesSearchString : Lens Model String
    , initialization : Lens Model (Initialization Status)
    , pagination : Lens Model Pagination
    }
lenses =
    { referenceMap = Lens .referenceMap (\b a -> { a | referenceMap = b })
    , referenceEntries = Lens .referenceEntries (\b a -> { a | referenceEntries = b })
    , referenceEntriesToAdd = Lens .referenceEntriesToAdd (\b a -> { a | referenceEntriesToAdd = b })
    , nutrients = Lens .nutrients (\b a -> { a | nutrients = b })
    , nutrientsSearchString = Lens .nutrientsSearchString (\b a -> { a | nutrientsSearchString = b })
    , referenceEntriesSearchString = Lens .referenceEntriesSearchString (\b a -> { a | referenceEntriesSearchString = b })
    , initialization = Lens .initialization (\b a -> { a | initialization = b })
    , pagination = Lens .pagination (\b a -> { a | pagination = b })
    }


type Msg
    = UpdateReferenceEntry ReferenceEntryUpdateClientInput
    | SaveReferenceEntryEdit ReferenceEntryUpdateClientInput
    | GotSaveReferenceEntryResponse (Result Error ReferenceEntry)
    | EnterEditReferenceEntry NutrientCode
    | ExitEditReferenceEntryAt NutrientCode
    | RequestDeleteReferenceEntry NutrientCode
    | ConfirmDeleteReferenceEntry NutrientCode
    | CancelDeleteReferenceEntry NutrientCode
    | GotDeleteReferenceEntryResponse NutrientCode (Result Error ())
    | GotFetchReferenceEntriesResponse (Result Error (List ReferenceEntry))
    | GotFetchReferenceMapResponse (Result Error ReferenceMap)
    | GotFetchNutrientsResponse (Result Error (List Nutrient))
    | SelectNutrient NutrientCode
    | DeselectNutrient NutrientCode
    | AddNutrient NutrientCode
    | GotAddReferenceEntryResponse (Result Error ReferenceEntry)
    | UpdateAddNutrient ReferenceEntryCreationClientInput
    | UpdateNutrients String
    | SetNutrientsSearchString String
    | SetReferenceEntriesSearchString String
    | SetPagination Pagination
    | UpdateReferenceMap ReferenceMapUpdateClientInput
    | SaveReferenceMapEdit
    | GotSaveReferenceMapResponse (Result Error ReferenceMap)
    | EnterEditReferenceMap
    | ExitEditReferenceMapAt
    | RequestDeleteReferenceMap
    | ConfirmDeleteReferenceMap
    | CancelDeleteReferenceMap
    | GotDeleteReferenceMapResponse (Result Error ())
