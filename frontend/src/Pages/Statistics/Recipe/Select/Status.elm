module Pages.Statistics.Recipe.Select.Status exposing (..)

import Monocle.Lens exposing (Lens)


type alias Status =
    { referenceTrees : Bool
    , recipe : Bool
    , recipeStats : Bool
    }


initial : Status
initial =
    { referenceTrees = False
    , recipe = False
    , recipeStats = False
    }


isFinished : Status -> Bool
isFinished status =
    List.all identity
        [ status.referenceTrees
        , status.recipe
        , status.recipeStats
        ]


lenses :
    { referenceTrees : Lens Status Bool
    , recipe : Lens Status Bool
    , recipeStats : Lens Status Bool
    }
lenses =
    { referenceTrees = Lens .referenceTrees (\b a -> { a | referenceTrees = b })
    , recipe = Lens .recipe (\b a -> { a | recipe = b })
    , recipeStats = Lens .recipeStats (\b a -> { a | recipeStats = b })
    }
