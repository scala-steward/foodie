module Util.LensUtil exposing (..)

import Dict exposing (Dict)
import List.Extra
import Monocle.Compose as Compose
import Monocle.Lens as Lens exposing (Lens)
import Monocle.Optional as Optional exposing (Optional)
import Util.Initialization as Initialization exposing (Initialization)


dictByKey : comparable -> Optional (Dict comparable a) a
dictByKey k =
    { getOption = Dict.get k
    , set = Dict.insert k
    }



-- todo: The handling is inconsistent - is it sensible to unify the two cases?


firstSuch : (a -> Bool) -> Optional (List a) a
firstSuch p =
    { getOption = List.Extra.find p
    , set = List.Extra.setIf p
    }


initializationField : Lens model (Initialization status) -> Lens status Bool -> Optional model Bool
initializationField initializationLens subLens =
    initializationLens
        |> Compose.lensWithOptional Initialization.lenses.loading
        |> Compose.optionalWithLens subLens


identityLens : Lens a a
identityLens =
    Lens identity always


updateById : (b -> Bool) -> Lens a (List b) -> (b -> b) -> a -> a
updateById p =
    Compose.lensWithOptional (firstSuch p)
        >> Optional.modify


insert : Lens a (List b) -> b -> a -> a
insert lens =
    Lens.modify lens << (::)


deleteAtId : (b -> k) -> k -> Lens a (List b) -> a -> a
deleteAtId keyOf id lens =
    Lens.modify lens <| List.Extra.filterNot (\b -> keyOf b == id)
