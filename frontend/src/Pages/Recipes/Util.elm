module Pages.Recipes.Util exposing (..)

import Parser exposing ((|.), Parser)
import Result.Extra


gramsParser : Parser Float
gramsParser =
    Parser.float
        |. Parser.chompWhile ((==) ' ')
        |. Parser.symbol "g"
        |. Parser.end


isRescalableServingSize : String -> Bool
isRescalableServingSize =
    Parser.run gramsParser
        >> Result.Extra.isOk
