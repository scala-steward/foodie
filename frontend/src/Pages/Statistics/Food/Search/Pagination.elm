module Pages.Statistics.Food.Search.Pagination exposing (..)

import Monocle.Lens exposing (Lens)
import Pages.Util.PaginationSettings as PaginationSettings exposing (PaginationSettings)


type alias Pagination =
    { foods : PaginationSettings
    }


initial : Pagination
initial =
    { foods = PaginationSettings.initial
    }


lenses :
    { foods : Lens Pagination PaginationSettings
    }
lenses =
    { foods = Lens .foods (\b a -> { a | foods = b })
    }
