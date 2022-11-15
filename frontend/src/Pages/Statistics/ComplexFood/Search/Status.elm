module Pages.Statistics.ComplexFood.Search.Status exposing (..)

import Monocle.Lens exposing (Lens)


type alias Status =
    { complexFoods : Bool
    }


initial : Status
initial =
    { complexFoods = False
    }


isFinished : Status -> Bool
isFinished status =
    List.all identity [ status.complexFoods ]


lenses :
    { complexFoods : Lens Status Bool
    }
lenses =
    { complexFoods = Lens .complexFoods (\b a -> { a | complexFoods = b })
    }
