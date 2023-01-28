module Util.LensUtil exposing (..)

import Basics.Extra exposing (flip)

import List.Extra
import Monocle.Compose as Compose
import Monocle.Lens as Lens exposing (Lens)
import Monocle.Optional as Optional exposing (Optional)
import Util.DictList as DictList exposing (DictList)
import Util.Initialization as Initialization exposing (Initialization)


dictByKey : key -> Optional (DictList key value) value
dictByKey k =
    { getOption = DictList.get k
    , set = DictList.insert k
    }


set : List value -> (value -> key) -> Lens model (DictList key value) -> model -> model
set xs idOf lens md =
    xs
        |> DictList.fromListWithKey idOf
        |> flip lens.set md


initializationField : Lens model (Initialization status) -> Lens status Bool -> Optional model Bool
initializationField initializationLens subLens =
    initializationLens
        |> Compose.lensWithOptional Initialization.lenses.loading
        |> Compose.optionalWithLens subLens


identityLens : Lens a a
identityLens =
    Lens identity always


updateById : key -> Lens a (DictList key value) -> (value -> value) -> a -> a
updateById id =
    Compose.lensWithOptional (dictByKey id)
        >> Optional.modify


insertAtId : key -> Lens a (DictList key value) -> value -> a -> a
insertAtId id lens =
    Lens.modify lens << DictList.insert id


deleteAtId : key -> Lens a (DictList key value) -> a -> a
deleteAtId id lens =
    Lens.modify lens <| DictList.remove id
