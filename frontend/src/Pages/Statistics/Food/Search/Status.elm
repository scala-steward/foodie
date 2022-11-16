module Pages.Statistics.Food.Search.Status exposing (..)

import Monocle.Lens exposing (Lens)


type alias Status =
    { foods : Bool
    }


initial : Status
initial =
    { foods = False
    }


isFinished : Status -> Bool
isFinished status =
    List.all identity [ status.foods ]


lenses :
    { foods : Lens Status Bool
    }
lenses =
    { foods = Lens .foods (\b a -> { a | foods = b })
    }
