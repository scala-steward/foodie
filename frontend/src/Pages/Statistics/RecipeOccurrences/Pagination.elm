module Pages.Statistics.RecipeOccurrences.Pagination exposing (..)

import Monocle.Lens exposing (Lens)
import Pages.Util.PaginationSettings as PaginationSettings exposing (PaginationSettings)


type alias Pagination =
    { recipeOccurrences : PaginationSettings
    }


initial : Pagination
initial =
    { recipeOccurrences = PaginationSettings.initial
    }


lenses :
    { recipeOccurrences : Lens Pagination PaginationSettings
    }
lenses =
    { recipeOccurrences = Lens .recipeOccurrences (\b a -> { a | recipeOccurrences = b })
    }
