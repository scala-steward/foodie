module Addresses.Frontend exposing
    ( complexFoods
    , confirmRecovery
    , confirmRegistration
    , deleteAccount
    , ingredientEditor
    , login
    , mealEntryEditor
    , meals
    , overview
    , recipes
    , referenceEntries
    , referenceMaps
    , requestRecovery
    , requestRegistration
    , statisticsComplexFoodSearch
    , statisticsComplexFoodSelect
    , statisticsFoodSearch
    , statisticsFoodSelect
    , statisticsMealSearch
    , statisticsMealSelect
    , statisticsRecipeSearch
    , statisticsRecipeSelect
    , statisticsTime
    , userSettings
    )

import Addresses.StatisticsVariant as StatisticsVariant
import Api.Auxiliary exposing (ComplexFoodId, FoodId, JWT, MealId, RecipeId, ReferenceMapId)
import Api.Types.UserIdentifier exposing (UserIdentifier)
import Pages.Util.ParserUtil as ParserUtil exposing (AddressWithParser, with1, with1Multiple, with2)
import Url.Parser as Parser exposing ((</>), (<?>), Parser, s)
import Uuid exposing (Uuid)


requestRegistration : AddressWithParser () a a
requestRegistration =
    plain "request-registration"


requestRecovery : AddressWithParser () a a
requestRecovery =
    plain "request-recovery"


overview : AddressWithParser () a a
overview =
    plain "overview"


mealEntryEditor : AddressWithParser MealId (MealId -> a) a
mealEntryEditor =
    with1
        { step1 = "meal-entry-editor"
        , toString = Uuid.toString >> List.singleton
        , paramParser = ParserUtil.uuidParser
        }


recipes : AddressWithParser () a a
recipes =
    plain "recipes"


meals : AddressWithParser () a a
meals =
    plain "meals"


statisticsTime : AddressWithParser () a a
statisticsTime =
    plain "statistics"


statisticsFoodSearch : AddressWithParser () a a
statisticsFoodSearch =
    plainMultiple "statistics" [ StatisticsVariant.food ]


statisticsFoodSelect : AddressWithParser Int (FoodId -> b) b
statisticsFoodSelect =
    with1Multiple
        { steps = [ "statistics", StatisticsVariant.food ]
        , toString = String.fromInt >> List.singleton
        , paramParser = Parser.int
        }


statisticsComplexFoodSearch : AddressWithParser () a a
statisticsComplexFoodSearch =
    plainMultiple "statistics" [ StatisticsVariant.complexFood ]


statisticsComplexFoodSelect : AddressWithParser Uuid (ComplexFoodId -> b) b
statisticsComplexFoodSelect =
    with1Multiple
        { steps = [ "statistics", StatisticsVariant.complexFood ]
        , toString = Uuid.toString >> List.singleton
        , paramParser = ParserUtil.uuidParser
        }


statisticsRecipeSearch : AddressWithParser () a a
statisticsRecipeSearch =
    plainMultiple "statistics" [ StatisticsVariant.recipe ]


statisticsRecipeSelect : AddressWithParser Uuid (RecipeId -> b) b
statisticsRecipeSelect =
    with1Multiple
        { steps = [ "statistics", StatisticsVariant.recipe ]
        , toString = Uuid.toString >> List.singleton
        , paramParser = ParserUtil.uuidParser
        }


statisticsMealSearch : AddressWithParser () a a
statisticsMealSearch =
    plainMultiple "statistics" [ StatisticsVariant.meal ]


statisticsMealSelect : AddressWithParser Uuid (MealId -> b) b
statisticsMealSelect =
    with1Multiple
        { steps = [ "statistics", StatisticsVariant.meal ]
        , toString = Uuid.toString >> List.singleton
        , paramParser = ParserUtil.uuidParser
        }


referenceMaps : AddressWithParser () a a
referenceMaps =
    plain "reference-maps"


referenceEntries : AddressWithParser ReferenceMapId (ReferenceMapId -> a) a
referenceEntries =
    with1
        { step1 = "reference-nutrients"
        , toString = Uuid.toString >> List.singleton
        , paramParser = ParserUtil.uuidParser
        }


userSettings : AddressWithParser () a a
userSettings =
    plain "user-settings"


ingredientEditor : AddressWithParser RecipeId (RecipeId -> a) a
ingredientEditor =
    with1
        { step1 = "ingredient-editor"
        , toString = Uuid.toString >> List.singleton
        , paramParser = ParserUtil.uuidParser
        }


login : AddressWithParser () a a
login =
    plain "login"


confirmRegistration : AddressWithParser ( ( String, String ), JWT ) (UserIdentifier -> JWT -> a) a
confirmRegistration =
    confirm "confirm-registration"


deleteAccount : AddressWithParser ( ( String, String ), JWT ) (UserIdentifier -> JWT -> a) a
deleteAccount =
    confirm "delete-account"


confirmRecovery : AddressWithParser ( ( String, String ), JWT ) (UserIdentifier -> JWT -> a) a
confirmRecovery =
    confirm "recover-account"


complexFoods : AddressWithParser () a a
complexFoods =
    plain "complex-foods"


confirm : String -> AddressWithParser ( ( String, String ), JWT ) (UserIdentifier -> JWT -> a) a
confirm step1 =
    with2
        { step1 = step1
        , toString1 = ParserUtil.nicknameEmailParser.address
        , step2 = "token"
        , toString2 = List.singleton
        , paramParser1 = ParserUtil.nicknameEmailParser.parser |> Parser.map UserIdentifier
        , paramParser2 = Parser.string
        }


plain : String -> AddressWithParser () a a
plain string =
    { address = always [ string ]
    , parser = s string
    }


plainMultiple : String -> List String -> AddressWithParser () a a
plainMultiple string strings =
    { address = always strings
    , parser = ParserUtil.foldl1 string strings
    }
