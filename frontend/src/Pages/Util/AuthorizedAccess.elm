module Pages.Util.AuthorizedAccess exposing (..)

import Api.Auxiliary exposing (JWT)
import Configuration exposing (Configuration)


type alias AuthorizedAccess =
    { configuration : Configuration
    , jwt : JWT
    }
