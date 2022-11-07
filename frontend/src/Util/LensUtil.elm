module Util.LensUtil exposing (..)

import Basics.Extra exposing (flip)
import Dict exposing (Dict)
import Monocle.Compose as Compose
import Monocle.Lens as Lens exposing (Lens)
import Monocle.Optional as Optional exposing (Optional)
import Util.Initialization as Initialization exposing (Initialization)


dictByKey : comparable -> Optional (Dict comparable a) a
dictByKey k =
    { getOption = Dict.get k
    , set = Dict.insert k
    }


set : List a -> (a -> comparable) -> Lens model (Dict comparable a) -> model -> model
set xs idOf lens md =
    xs
        |> List.map (\m -> ( idOf m, m ))
        |> Dict.fromList
        |> flip lens.set md


initializationField : Lens model (Initialization status) -> Lens status Bool -> Optional model Bool
initializationField initializationLens subLens =
    initializationLens
        |> Compose.lensWithOptional Initialization.lenses.loading
        |> Compose.optionalWithLens subLens


identityLens : Lens a a
identityLens =
    Lens identity always


updateById : comparable -> Lens a (Dict comparable b) -> (b -> b) -> a -> a
updateById id =
    Compose.lensWithOptional (dictByKey id)
        >> Optional.modify


insertAtId : comparable -> Lens a (Dict comparable b) -> b -> a -> a
insertAtId id lens =
    Lens.modify lens << Dict.insert id


deleteAtId : comparable -> Lens a (Dict comparable b) -> a -> a
deleteAtId id lens =
    Lens.modify lens <| Dict.remove id
