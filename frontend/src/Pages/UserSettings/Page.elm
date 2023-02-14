module Pages.UserSettings.Page exposing (..)

import Api.Auxiliary exposing (JWT)
import Api.Types.Mode exposing (Mode)
import Api.Types.User exposing (User)
import Monocle.Lens exposing (Lens)
import Pages.Util.AuthorizedAccess exposing (AuthorizedAccess)
import Pages.Util.ComplementInput as ComplementInput exposing (ComplementInput)
import Pages.View.Tristate as Tristate
import Util.HttpUtil exposing (Error)


type alias Model =
    Tristate.Model Main Initial


type alias Main =
    { jwt : JWT
    , user : User
    , complementInput : ComplementInput
    , mode : Mode
    }


type alias Initial =
    { jwt : JWT
    , user : Maybe User
    }


initial : AuthorizedAccess -> Model
initial authorizedAccess =
    { jwt = authorizedAccess.jwt
    , user = Nothing
    }
        |> Tristate.createInitial authorizedAccess.configuration


initialToMain : Initial -> Maybe Main
initialToMain i =
    Maybe.map
        (\user ->
            { jwt = i.jwt
            , user = user
            , complementInput = ComplementInput.initial
            , mode = Regular
            }
        )
        i.user


lenses :
    { initial :
        { user : Lens Initial (Maybe User)
        }
    , main :
        { user : Lens Main User
        , complementInput : Lens Main ComplementInput
        , mode : Lens Main Mode
        }
    }
lenses =
    { initial = { user = Lens .user (\b a -> { a | user = b }) }
    , main =
        { user = Lens .user (\b a -> { a | user = b })
        , complementInput = Lens .complementInput (\b a -> { a | complementInput = b })
        , mode = Lens .mode (\b a -> { a | mode = b })
        }
    }


type Mode
    = Regular
    | RequestedDeletion


type alias Flags =
    { authorizedAccess : AuthorizedAccess
    }


type Msg
    = GotFetchUserResponse (Result Error User)
    | UpdatePassword
    | GotUpdatePasswordResponse (Result Error ())
    | UpdateSettings
    | GotUpdateSettingsResponse (Result Error User)
    | RequestDeletion
    | GotRequestDeletionResponse (Result Error ())
    | SetComplementInput ComplementInput
    | Logout Api.Types.Mode.Mode
    | GotLogoutResponse (Result Error ())
