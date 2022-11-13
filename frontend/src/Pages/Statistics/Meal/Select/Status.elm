module Pages.Statistics.Meal.Select.Status exposing (..)

import Monocle.Lens exposing (Lens)


type alias Status =
    { referenceTrees : Bool
    , meal : Bool
    , mealStats : Bool
    }


initial : Status
initial =
    { referenceTrees = False
    , meal = False
    , mealStats = False
    }


isFinished : Status -> Bool
isFinished status =
    List.all identity
        [ status.referenceTrees
        , status.meal
        , status.mealStats
        ]


lenses :
    { referenceTrees : Lens Status Bool
    , meal : Lens Status Bool
    , mealStats : Lens Status Bool
    }
lenses =
    { referenceTrees = Lens .referenceTrees (\b a -> { a | referenceTrees = b })
    , meal = Lens .meal (\b a -> { a | meal = b })
    , mealStats = Lens .mealStats (\b a -> { a | mealStats = b })
    }
