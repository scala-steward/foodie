module Pages.ReferenceEntries.Page exposing (..)

import Api.Auxiliary exposing (JWT, NutrientCode, ReferenceMapId)
import Api.Types.Nutrient exposing (Nutrient)
import Api.Types.ReferenceEntry exposing (ReferenceEntry)
import Api.Types.ReferenceMap exposing (ReferenceMap)
import Monocle.Lens exposing (Lens)
import Pages.ReferenceEntries.Pagination as Pagination exposing (Pagination)
import Pages.ReferenceEntries.ReferenceEntryCreationClientInput exposing (ReferenceEntryCreationClientInput)
import Pages.ReferenceEntries.ReferenceEntryUpdateClientInput exposing (ReferenceEntryUpdateClientInput)
import Pages.ReferenceMaps.ReferenceMapUpdateClientInput exposing (ReferenceMapUpdateClientInput)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.View.Tristate as Tristate
import Util.DictList as DictList exposing (DictList)
import Util.Editing exposing (Editing)
import Util.HttpUtil exposing (Error)


type alias Model =
    Tristate.Model Main Initial


type alias Main =
    { jwt : JWT
    , referenceMap : Editing ReferenceMap ReferenceMapUpdateClientInput
    , referenceEntries : ReferenceEntryStateMap
    , nutrients : NutrientMap
    , nutrientsSearchString : String
    , referenceEntriesSearchString : String
    , referenceEntriesToAdd : AddNutrientMap
    , pagination : Pagination
    }


type alias Initial =
    { jwt : JWT
    , nutrients : Maybe NutrientMap
    , referenceMap : Maybe (Editing ReferenceMap ReferenceMapUpdateClientInput)
    , referenceEntries : Maybe ReferenceEntryStateMap
    }


initial : AuthorizedAccess -> Model
initial authorizedAccess =
    { jwt = authorizedAccess.jwt
    , nutrients = Nothing
    , referenceMap = Nothing
    , referenceEntries = Nothing
    }
        |> Tristate.createInitial authorizedAccess.configuration


initialToMain : Initial -> Maybe Main
initialToMain i =
    Maybe.map3
        (\nutrients referenceMap referenceEntries ->
            { jwt = i.jwt
            , referenceMap = referenceMap
            , referenceEntries = referenceEntries
            , nutrients = nutrients
            , nutrientsSearchString = ""
            , referenceEntriesSearchString = ""
            , referenceEntriesToAdd = DictList.empty
            , pagination = Pagination.initial
            }
        )
        i.nutrients
        i.referenceMap
        i.referenceEntries


type alias ReferenceEntryState =
    Editing ReferenceEntry ReferenceEntryUpdateClientInput


type alias NutrientMap =
    DictList NutrientCode Nutrient


type alias AddNutrientMap =
    DictList NutrientCode ReferenceEntryCreationClientInput


type alias ReferenceEntryStateMap =
    DictList NutrientCode ReferenceEntryState


type alias Flags =
    { authorizedAccess : AuthorizedAccess
    , referenceMapId : ReferenceMapId
    }


lenses :
    { initial :
        { referenceMap : Lens Initial (Maybe (Editing ReferenceMap ReferenceMapUpdateClientInput))
        , referenceEntries : Lens Initial (Maybe ReferenceEntryStateMap)
        , nutrients : Lens Initial (Maybe NutrientMap)
        }
    , main :
        { referenceMap : Lens Main (Editing ReferenceMap ReferenceMapUpdateClientInput)
        , referenceEntries : Lens Main ReferenceEntryStateMap
        , referenceEntriesToAdd : Lens Main AddNutrientMap
        , nutrients : Lens Main NutrientMap
        , nutrientsSearchString : Lens Main String
        , referenceEntriesSearchString : Lens Main String
        , pagination : Lens Main Pagination
        }
    }
lenses =
    { initial =
        { referenceMap = Lens .referenceMap (\b a -> { a | referenceMap = b })
        , referenceEntries = Lens .referenceEntries (\b a -> { a | referenceEntries = b })
        , nutrients = Lens .nutrients (\b a -> { a | nutrients = b })
        }
    , main =
        { referenceMap = Lens .referenceMap (\b a -> { a | referenceMap = b })
        , referenceEntries = Lens .referenceEntries (\b a -> { a | referenceEntries = b })
        , referenceEntriesToAdd = Lens .referenceEntriesToAdd (\b a -> { a | referenceEntriesToAdd = b })
        , nutrients = Lens .nutrients (\b a -> { a | nutrients = b })
        , nutrientsSearchString = Lens .nutrientsSearchString (\b a -> { a | nutrientsSearchString = b })
        , referenceEntriesSearchString = Lens .referenceEntriesSearchString (\b a -> { a | referenceEntriesSearchString = b })
        , pagination = Lens .pagination (\b a -> { a | pagination = b })
        }
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
    | ExitEditReferenceMap
    | RequestDeleteReferenceMap
    | ConfirmDeleteReferenceMap
    | CancelDeleteReferenceMap
    | GotDeleteReferenceMapResponse (Result Error ())
