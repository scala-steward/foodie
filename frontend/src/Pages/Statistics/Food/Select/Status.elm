module Pages.Statistics.Food.Select.Status exposing (..)

import Monocle.Lens exposing (Lens)


type alias Status =
    { referenceTrees : Bool
    , foodInfo : Bool
    , foodStats : Bool
    }


initial : Status
initial =
    { referenceTrees = False
    , foodInfo = False
    , foodStats = False
    }


isFinished : Status -> Bool
isFinished status =
    List.all identity
        [ status.referenceTrees
        , status.foodInfo
        , status.foodStats
        ]


lenses :
    { referenceTrees : Lens Status Bool
    , foodInfo : Lens Status Bool
    , foodStats : Lens Status Bool
    }
lenses =
    { referenceTrees = Lens .referenceTrees (\b a -> { a | referenceTrees = b })
    , foodInfo = Lens .foodInfo (\b a -> { a | foodInfo = b })
    , foodStats = Lens .foodStats (\b a -> { a | foodStats = b })
    }
