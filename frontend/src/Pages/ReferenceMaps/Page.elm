module Pages.ReferenceMaps.Page exposing (..)

import Api.Auxiliary exposing (JWT, ReferenceMapId)
import Api.Types.ReferenceMap exposing (ReferenceMap)
import Monocle.Lens exposing (Lens)
import Pages.ReferenceMaps.Pagination as Pagination exposing (Pagination)
import Pages.ReferenceMaps.ReferenceMapCreationClientInput exposing (ReferenceMapCreationClientInput)
import Pages.ReferenceMaps.ReferenceMapUpdateClientInput exposing (ReferenceMapUpdateClientInput)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.View.Tristate as Tristate
import Util.DictList exposing (DictList)
import Util.Editing exposing (Editing)
import Util.HttpUtil exposing (Error)


type alias Model =
    Tristate.Model Main Initial


type alias Main =
    { jwt : JWT
    , referenceMaps : ReferenceMapStateMap
    , referenceMapToAdd : Maybe ReferenceMapCreationClientInput
    , searchString : String
    , pagination : Pagination
    }


type alias Initial =
    { jwt : JWT
    , referenceMaps : Maybe ReferenceMapStateMap
    }


initial : AuthorizedAccess -> Model
initial authorizedAccess =
    { jwt = authorizedAccess.jwt
    , referenceMaps = Nothing
    }
        |> Tristate.createInitial authorizedAccess.configuration


initialToMain : Initial -> Maybe Main
initialToMain i =
    Maybe.map
        (\referenceMaps ->
            { jwt = i.jwt
            , referenceMaps = referenceMaps
            , referenceMapToAdd = Nothing
            , searchString = ""
            , pagination = Pagination.initial
            }
        )
        i.referenceMaps


type alias ReferenceMapState =
    Editing ReferenceMap ReferenceMapUpdateClientInput


type alias ReferenceMapStateMap =
    DictList ReferenceMapId ReferenceMapState


lenses :
    { initial :
        { referenceMaps : Lens Initial (Maybe ReferenceMapStateMap)
        }
    , main :
        { referenceMaps : Lens Main ReferenceMapStateMap
        , referenceMapToAdd : Lens Main (Maybe ReferenceMapCreationClientInput)
        , searchString : Lens Main String
        , pagination : Lens Main Pagination
        }
    }
lenses =
    { initial = { referenceMaps = Lens .referenceMaps (\b a -> { a | referenceMaps = b }) }
    , main =
        { referenceMaps = Lens .referenceMaps (\b a -> { a | referenceMaps = b })
        , referenceMapToAdd = Lens .referenceMapToAdd (\b a -> { a | referenceMapToAdd = b })
        , searchString = Lens .searchString (\b a -> { a | searchString = b })
        , pagination = Lens .pagination (\b a -> { a | pagination = b })
        }
    }


type alias Flags =
    { authorizedAccess : AuthorizedAccess
    }


type alias Msg =
    Tristate.Msg LogicMsg


type LogicMsg
    = UpdateReferenceMapCreation (Maybe ReferenceMapCreationClientInput)
    | CreateReferenceMap
    | GotCreateReferenceMapResponse (Result Error ReferenceMap)
    | UpdateReferenceMap ReferenceMapUpdateClientInput
    | SaveReferenceMapEdit ReferenceMapId
    | GotSaveReferenceMapResponse (Result Error ReferenceMap)
    | EnterEditReferenceMap ReferenceMapId
    | ExitEditReferenceMapAt ReferenceMapId
    | RequestDeleteReferenceMap ReferenceMapId
    | ConfirmDeleteReferenceMap ReferenceMapId
    | CancelDeleteReferenceMap ReferenceMapId
    | GotDeleteReferenceMapResponse ReferenceMapId (Result Error ())
    | GotFetchReferenceMapsResponse (Result Error (List ReferenceMap))
    | SetPagination Pagination
    | SetSearchString String
