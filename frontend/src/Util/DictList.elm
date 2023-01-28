module Util.DictList exposing (DictList, empty, filter, fromList, fromListWithKey, insert, remove, toList, values)

import Basics.Extra
import List.Extra


type DictList k v
    = DictList (List ( k, v ))


empty : DictList k v
empty =
    DictList []


fromList : List ( k, v ) -> DictList k v
fromList =
    DictList


toList : DictList k v -> List ( k, v )
toList (DictList kvs) =
    kvs


fromListWithKey : (v -> k) -> List v -> DictList k v
fromListWithKey keyOf =
    List.map (\v -> ( keyOf v, v )) >> fromList


insert : k -> v -> DictList k v -> DictList k v
insert key value =
    toList
        >> List.Extra.filterNot (\( k, _ ) -> k == key)
        >> (::) ( key, value )
        >> fromList


remove : k -> DictList k v -> DictList k v
remove key =
    toList
        >> List.Extra.filterNot (\( k, _ ) -> k == key)
        >> fromList


filter : (k -> v -> Bool) -> DictList k v -> DictList k v
filter p =
    toList
        >> List.filter (Basics.Extra.uncurry p)
        >> fromList


values : DictList k v -> List v
values =
    toList
        >> List.map Tuple.second
