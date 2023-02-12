module Util.LensUtil exposing (..)

import Basics.Extra exposing (flip)
import Monocle.Compose as Compose
import Monocle.Lens as Lens exposing (Lens)
import Monocle.Optional as Optional exposing (Optional)
import Util.DictList as DictList exposing (DictList)
import Util.Initialization as Initialization exposing (Initialization)



-- todo: Tidy up functions


dictByKey : key -> Optional (DictList key value) value
dictByKey k =
    { getOption = DictList.get k
    , set = DictList.insert k
    }

-- todo : Check use
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


updateByIdOptional : key -> Optional a (DictList key value) -> (value -> value) -> a -> a
updateByIdOptional id =
    Compose.optionalWithOptional (dictByKey id)
        >> Optional.modify


insertAtId : key -> Lens a (DictList key value) -> value -> a -> a
insertAtId id lens =
    DictList.insert id >> Lens.modify lens


deleteAtId : key -> Lens a (DictList key value) -> a -> a
deleteAtId id lens =
    DictList.remove id |> Lens.modify lens

