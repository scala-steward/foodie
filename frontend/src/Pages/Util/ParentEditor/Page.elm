module Pages.Util.ParentEditor.Page exposing (..)

import Api.Auxiliary exposing (JWT)
import Monocle.Lens exposing (Lens)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.DateUtil as DateUtil
import Pages.Util.ParentEditor.Pagination as Pagination exposing (Pagination)
import Pages.View.Tristate as Tristate
import Util.DictList exposing (DictList)
import Util.Editing exposing (Editing)
import Util.HttpUtil exposing (Error)


type alias Model parentId parent creation update =
    Tristate.Model (Main parentId parent creation update) (Initial parentId parent update)


type alias Main parentId parent creation update =
    { jwt : JWT
    , parents : DictList parentId (Editing parent update)
    , parentCreation : Maybe creation
    , searchString : String
    , pagination : Pagination
    }


type alias Initial parentId parent update =
    { jwt : JWT
    , parents : Maybe (DictList parentId (Editing parent update))
    }


initial : AuthorizedAccess -> Model parentId parent creation update
initial authorizedAccess =
    { parents = Nothing
    , jwt = authorizedAccess.jwt
    }
        |> Tristate.createInitial authorizedAccess.configuration


initialToMain : Initial parentId parent update -> Maybe (Main parentId parent creation update)
initialToMain i =
    i.parents
        |> Maybe.map
            (\recipes ->
                { jwt = i.jwt
                , parents = recipes
                , parentCreation = Nothing
                , searchString = ""
                , pagination = Pagination.initial
                }
            )


lenses :
    { initial : { parents : Lens (Initial parentId parent update) (Maybe (DictList parentId (Editing parent update))) }
    , main :
        { parents : Lens (Main parentId parent creation update) (DictList parentId (Editing parent update))
        , parentCreation : Lens (Main parentId parent creation update) (Maybe creation)
        , searchString : Lens (Main parentId parent creation update) String
        , pagination : Lens (Main parentId parent creation update) Pagination
        }
    }
lenses =
    { initial =
        { parents = Lens .parents (\b a -> { a | parents = b })
        }
    , main =
        { parents = Lens .parents (\b a -> { a | parents = b })
        , parentCreation = Lens .parentCreation (\b a -> { a | parentCreation = b })
        , searchString = Lens .searchString (\b a -> { a | searchString = b })
        , pagination = Lens .pagination (\b a -> { a | pagination = b })
        }
    }


type LogicMsg parentId parent creation update
    = UpdateCreation (Maybe creation)
    | Create
    | GotCreateResponse (Result Error parent)
    | Edit update
    | SaveEdit parentId
    | GotSaveEditResponse (Result Error parent)
    | ToggleControls parentId
    | EnterEdit parentId
    | ExitEdit parentId
    | RequestDelete parentId
    | ConfirmDelete parentId
    | CancelDelete parentId
    | GotDeleteResponse parentId (Result Error ())
    | GotFetchResponse (Result Error (List parent))
    | Duplicate parentId
    | GotDuplicateTimestamp parentId DateUtil.Timestamp
    | GotDuplicateResponse (Result Error parent)
    | SetPagination Pagination
    | SetSearchString String
