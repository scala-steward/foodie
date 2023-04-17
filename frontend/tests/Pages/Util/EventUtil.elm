module Pages.Util.EventUtil exposing (..)

import Json.Decode
import Json.Encode


enter : ( String, Json.Decode.Value )
enter =
    ( "keyup"
    , Json.Encode.object
        [ ( "keyCode", Json.Encode.int 13 )
        ]
    )
