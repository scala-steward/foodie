module Util.LensUtil exposing (..)

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
    DictList.insert id >> Lens.modify lens


deleteAtId : key -> Lens a (DictList key value) -> a -> a
deleteAtId id lens =
    DictList.remove id |> Lens.modify lens
