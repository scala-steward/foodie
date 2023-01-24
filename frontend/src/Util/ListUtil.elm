module Util.ListUtil exposing (..)

import List.Extra
import Maybe.Extra


exists : (a -> Bool) -> List a -> Bool
exists p =
    List.Extra.find p >> Maybe.Extra.isJust
