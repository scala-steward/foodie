module Pages.Util.DictUtil exposing (..)

import Dict exposing (Dict)
import Dict.Extra
import Maybe.Extra


existsValue : (v -> Bool) -> Dict comparable v -> Bool
existsValue p =
    Dict.Extra.any (always p)


firstSuch : (v -> Bool) -> Dict comparable v -> Maybe v
firstSuch p =
    Dict.Extra.find (always p)
        >> Maybe.map Tuple.second


nameOrEmpty : Dict comparable { a | name : String } -> comparable -> String
nameOrEmpty map id =
    Dict.get id map |> Maybe.Extra.unwrap "" .name
