module Pages.Util.Parent.Page exposing (..)

import Api.Auxiliary exposing (JWT)
import Monocle.Lens exposing (Lens)
import Pages.Util.DateUtil as DateUtil
import Pages.View.Tristate as Tristate
import Util.Editing as Editing exposing (Editing)
import Util.HttpUtil exposing (Error)


type alias Model parent update =
    Tristate.Model (Main parent update) (Initial parent)


type alias Main parent update =
    { jwt : JWT
    , parent : Editing parent update
    }


type alias Initial parent =
    { jwt : JWT
    , parent : Maybe parent
    }


initialWith : JWT -> Initial parent
initialWith jwt =
    { jwt = jwt
    , parent = Nothing
    }


initialToMain : Initial parent -> Maybe (Main parent update)
initialToMain i =
    i.parent
        |> Maybe.map
            (\parent ->
                { jwt = i.jwt
                , parent = parent |> Editing.asView
                }
            )


lenses :
    { initial :
        { parent : Lens (Initial parent) (Maybe parent)
        }
    , main :
        { parent : Lens (Main parent update) (Editing parent update)
        }
    }
lenses =
    { initial =
        { parent = Lens .parent (\b a -> { a | parent = b })
        }
    , main =
        { parent = Lens .parent (\b a -> { a | parent = b })
        }
    }


type LogicMsg parent update
    = GotFetchResponse (Result Error parent)
    | Edit update
    | SaveEdit
    | GotSaveEditResponse (Result Error parent)
    | EnterEdit
    | ExitEdit
    | RequestDelete
    | ConfirmDelete
    | CancelDelete
    | GotDeleteResponse (Result Error ())
    | Duplicate
    | GotDuplicationTimestamp DateUtil.Timestamp
    | GotDuplicateResponse (Result Error parent)
    | ToggleControls
