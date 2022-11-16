module Pages.Statistics.ComplexFood.Search.Pagination exposing (..)

import Monocle.Lens exposing (Lens)
import Pages.Util.PaginationSettings as PaginationSettings exposing (PaginationSettings)


type alias Pagination =
    { complexFoods : PaginationSettings
    }


initial : Pagination
initial =
    { complexFoods = PaginationSettings.initial
    }


lenses :
    { complexFoods : Lens Pagination PaginationSettings
    }
lenses =
    { complexFoods = Lens .complexFoods (\b a -> { a | complexFoods = b })
    }
