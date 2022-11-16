port module Ports exposing
    ( deleteToken
    , doDeleteToken
    , doFetchFoods
    , doFetchNutrients
    , doFetchToken
    , fetchFoods
    , fetchNutrients
    , fetchToken
    , storeFoods
    , storeNutrients
    , storeToken
    )


port storeToken : String -> Cmd msg


port doFetchToken : () -> Cmd msg


port fetchToken : (String -> msg) -> Sub msg


port doDeleteToken : () -> Cmd msg


port deleteToken : (() -> msg) -> Sub msg


port storeFoods : String -> Cmd msg


port doFetchFoods : () -> Cmd msg


port fetchFoods : (String -> msg) -> Sub msg


port storeNutrients : String -> Cmd msg


port doFetchNutrients : () -> Cmd msg


port fetchNutrients : (String -> msg) -> Sub msg
