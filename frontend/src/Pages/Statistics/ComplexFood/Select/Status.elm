module Pages.Statistics.ComplexFood.Select.Status exposing (..)

import Monocle.Lens exposing (Lens)


type alias Status =
    { referenceTrees : Bool
    , complexFood : Bool
    , complexFoodStats : Bool
    }


initial : Status
initial =
    { referenceTrees = False
    , complexFood = False
    , complexFoodStats = False
    }


isFinished : Status -> Bool
isFinished status =
    List.all identity
        [ status.referenceTrees
        , status.complexFood
        , status.complexFoodStats
        ]


lenses :
    { referenceTrees : Lens Status Bool
    , complexFood : Lens Status Bool
    , complexFoodStats : Lens Status Bool
    }
lenses =
    { referenceTrees = Lens .referenceTrees (\b a -> { a | referenceTrees = b })
    , complexFood = Lens .complexFood (\b a -> { a | complexFood = b })
    , complexFoodStats = Lens .complexFoodStats (\b a -> { a | complexFoodStats = b })
    }
