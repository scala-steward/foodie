module Main exposing (main)

import Addresses.Frontend
import Api.Auxiliary exposing (ComplexFoodId, FoodId, JWT, MealId, RecipeId, ReferenceMapId)
import Api.Types.LoginContent exposing (decoderLoginContent)
import Api.Types.UserIdentifier exposing (UserIdentifier)
import Basics.Extra exposing (flip)
import Browser exposing (UrlRequest)
import Browser.Navigation as Nav
import Configuration exposing (Configuration)
import Html exposing (Html, div, text)
import Jwt
import Maybe.Extra
import Monocle.Lens exposing (Lens)
import Pages.ComplexFoods.Handler
import Pages.ComplexFoods.Page
import Pages.ComplexFoods.View
import Pages.Deletion.Handler
import Pages.Deletion.Page
import Pages.Deletion.View
import Pages.Ingredients.Handler
import Pages.Ingredients.Page
import Pages.Ingredients.View
import Pages.Login.Handler
import Pages.Login.Page
import Pages.Login.View
import Pages.MealEntries.Handler
import Pages.MealEntries.Page
import Pages.MealEntries.View
import Pages.Meals.Handler
import Pages.Meals.Page
import Pages.Meals.View
import Pages.Overview.Handler
import Pages.Overview.Page
import Pages.Overview.View
import Pages.Recipes.Handler
import Pages.Recipes.Page
import Pages.Recipes.View
import Pages.Recovery.Confirm.Handler
import Pages.Recovery.Confirm.Page
import Pages.Recovery.Confirm.View
import Pages.Recovery.Request.Handler
import Pages.Recovery.Request.Page
import Pages.Recovery.Request.View
import Pages.ReferenceEntries.Handler
import Pages.ReferenceEntries.Page
import Pages.ReferenceEntries.View
import Pages.ReferenceMaps.Handler
import Pages.ReferenceMaps.Page
import Pages.ReferenceMaps.View
import Pages.Registration.Confirm.Handler
import Pages.Registration.Confirm.Page
import Pages.Registration.Confirm.View
import Pages.Registration.Request.Handler
import Pages.Registration.Request.Page
import Pages.Registration.Request.View
import Pages.Statistics.ComplexFood.Search.Handler
import Pages.Statistics.ComplexFood.Search.Page
import Pages.Statistics.ComplexFood.Search.View
import Pages.Statistics.ComplexFood.Select.Handler
import Pages.Statistics.ComplexFood.Select.Page
import Pages.Statistics.ComplexFood.Select.View
import Pages.Statistics.Food.Search.Handler
import Pages.Statistics.Food.Search.Page
import Pages.Statistics.Food.Search.View
import Pages.Statistics.Food.Select.Handler
import Pages.Statistics.Food.Select.Page
import Pages.Statistics.Food.Select.View
import Pages.Statistics.Meal.Search.Handler
import Pages.Statistics.Meal.Search.Page
import Pages.Statistics.Meal.Search.View
import Pages.Statistics.Meal.Select.Handler
import Pages.Statistics.Meal.Select.Page
import Pages.Statistics.Meal.Select.View
import Pages.Statistics.Recipe.Search.Handler
import Pages.Statistics.Recipe.Search.Page
import Pages.Statistics.Recipe.Search.View
import Pages.Statistics.Recipe.Select.Handler
import Pages.Statistics.Recipe.Select.Page
import Pages.Statistics.Recipe.Select.View
import Pages.Statistics.Time.Handler
import Pages.Statistics.Time.Page
import Pages.Statistics.Time.View
import Pages.UserSettings.Handler
import Pages.UserSettings.Page
import Pages.UserSettings.View
import Ports exposing (doFetchToken, fetchFoods, fetchMeasures, fetchNutrients, fetchToken)
import Url exposing (Url)
import Url.Parser as Parser exposing ((</>), Parser)


main : Program Configuration Model Msg
main =
    Browser.application
        { init = init
        , onUrlChange = ChangedUrl
        , onUrlRequest = ClickedLink
        , subscriptions = subscriptions
        , update = update
        , view = \model -> { title = titleFor model, body = [ view model ] }
        }


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ fetchToken FetchToken
        , fetchFoods FetchFoods
        , fetchMeasures FetchMeasures
        , fetchNutrients FetchNutrients
        , Ports.deleteToken DeleteToken
        ]


type alias Model =
    { key : Nav.Key
    , page : Page
    , configuration : Configuration
    , jwt : Maybe JWT
    , entryRoute : Maybe Route
    }


lenses :
    { jwt : Lens Model (Maybe JWT)
    , page : Lens Model Page
    , entryRoute : Lens Model (Maybe Route)
    }
lenses =
    { jwt = Lens .jwt (\b a -> { a | jwt = b })
    , page = Lens .page (\b a -> { a | page = b })
    , entryRoute = Lens .entryRoute (\b a -> { a | entryRoute = b })
    }


type Page
    = Login Pages.Login.Page.Model
    | Overview Pages.Overview.Page.Model
    | Recipes Pages.Recipes.Page.Model
    | Ingredients Pages.Ingredients.Page.Model
    | Meals Pages.Meals.Page.Model
    | MealEntries Pages.MealEntries.Page.Model
    | StatisticsTime Pages.Statistics.Time.Page.Model
    | StatisticsFoodSearch Pages.Statistics.Food.Search.Page.Model
    | StatisticsFoodSelect Pages.Statistics.Food.Select.Page.Model
    | StatisticsComplexFoodSearch Pages.Statistics.ComplexFood.Search.Page.Model
    | StatisticsComplexFoodSelect Pages.Statistics.ComplexFood.Select.Page.Model
    | StatisticsRecipeSearch Pages.Statistics.Recipe.Search.Page.Model
    | StatisticsRecipeSelect Pages.Statistics.Recipe.Select.Page.Model
    | StatisticsMealSearch Pages.Statistics.Meal.Search.Page.Model
    | StatisticsMealSelect Pages.Statistics.Meal.Select.Page.Model
    | ReferenceMaps Pages.ReferenceMaps.Page.Model
    | ReferenceEntries Pages.ReferenceEntries.Page.Model
    | RequestRegistration Pages.Registration.Request.Page.Model
    | ConfirmRegistration Pages.Registration.Confirm.Page.Model
    | UserSettings Pages.UserSettings.Page.Model
    | Deletion Pages.Deletion.Page.Model
    | RequestRecovery Pages.Recovery.Request.Page.Model
    | ConfirmRecovery Pages.Recovery.Confirm.Page.Model
    | ComplexFoods Pages.ComplexFoods.Page.Model
    | NotFound


type Msg
    = ClickedLink UrlRequest
    | ChangedUrl Url
    | FetchToken String
    | DeleteToken ()
    | FetchFoods String
    | FetchMeasures String
    | FetchNutrients String
    | LoginMsg Pages.Login.Page.Msg
    | OverviewMsg Pages.Overview.Page.Msg
    | RecipesMsg Pages.Recipes.Page.Msg
    | IngredientsMsg Pages.Ingredients.Page.Msg
    | MealsMsg Pages.Meals.Page.Msg
    | MealEntriesMsg Pages.MealEntries.Page.Msg
    | StatisticsTimeMsg Pages.Statistics.Time.Page.Msg
    | StatisticsFoodSearchMsg Pages.Statistics.Food.Search.Page.Msg
    | StatisticsFoodSelectMsg Pages.Statistics.Food.Select.Page.Msg
    | StatisticsComplexFoodSearchMsg Pages.Statistics.ComplexFood.Search.Page.Msg
    | StatisticsComplexFoodSelectMsg Pages.Statistics.ComplexFood.Select.Page.Msg
    | StatisticsRecipeSearchMsg Pages.Statistics.Recipe.Search.Page.Msg
    | StatisticsRecipeSelectMsg Pages.Statistics.Recipe.Select.Page.Msg
    | StatisticsMealSearchMsg Pages.Statistics.Meal.Search.Page.Msg
    | StatisticsMealSelectMsg Pages.Statistics.Meal.Select.Page.Msg
    | ReferenceMapsMsg Pages.ReferenceMaps.Page.Msg
    | ReferenceEntriesMsg Pages.ReferenceEntries.Page.Msg
    | RequestRegistrationMsg Pages.Registration.Request.Page.Msg
    | ConfirmRegistrationMsg Pages.Registration.Confirm.Page.Msg
    | UserSettingsMsg Pages.UserSettings.Page.Msg
    | DeletionMsg Pages.Deletion.Page.Msg
    | RequestRecoveryMsg Pages.Recovery.Request.Page.Msg
    | ConfirmRecoveryMsg Pages.Recovery.Confirm.Page.Msg
    | ComplexFoodsMsg Pages.ComplexFoods.Page.Msg


titleFor : Model -> String
titleFor model =
    let
        nickname =
            model.jwt
                |> Maybe.andThen
                    (Jwt.decodeToken decoderLoginContent
                        >> Result.toMaybe
                    )
                |> Maybe.Extra.unwrap "" (\u -> String.concat [ ": ", u.nickname ])
    in
    "Foodie" ++ nickname


init : Configuration -> Url -> Nav.Key -> ( Model, Cmd Msg )
init configuration url key =
    ( { page = NotFound
      , key = key
      , configuration = configuration
      , jwt = Nothing
      , entryRoute = parsePage url
      }
    , doFetchToken ()
    )


view : Model -> Html Msg
view model =
    case model.page of
        Login login ->
            Html.map LoginMsg (Pages.Login.View.view login)

        Overview overview ->
            Html.map OverviewMsg (Pages.Overview.View.view overview)

        Recipes recipes ->
            Html.map RecipesMsg (Pages.Recipes.View.view recipes)

        Ingredients ingredients ->
            Html.map IngredientsMsg (Pages.Ingredients.View.view ingredients)

        Meals meals ->
            Html.map MealsMsg (Pages.Meals.View.view meals)

        MealEntries mealEntries ->
            Html.map MealEntriesMsg (Pages.MealEntries.View.view mealEntries)

        StatisticsTime statisticsTime ->
            Html.map StatisticsTimeMsg (Pages.Statistics.Time.View.view statisticsTime)

        StatisticsFoodSearch statisticsFoodSearch ->
            Html.map StatisticsFoodSearchMsg (Pages.Statistics.Food.Search.View.view statisticsFoodSearch)

        StatisticsFoodSelect statisticsFoodSelect ->
            Html.map StatisticsFoodSelectMsg (Pages.Statistics.Food.Select.View.view statisticsFoodSelect)

        StatisticsComplexFoodSearch statisticsComplexFoodSearch ->
            Html.map StatisticsComplexFoodSearchMsg (Pages.Statistics.ComplexFood.Search.View.view statisticsComplexFoodSearch)

        StatisticsComplexFoodSelect statisticsComplexFoodSelect ->
            Html.map StatisticsComplexFoodSelectMsg (Pages.Statistics.ComplexFood.Select.View.view statisticsComplexFoodSelect)

        StatisticsRecipeSearch statisticsRecipeSearch ->
            Html.map StatisticsRecipeSearchMsg (Pages.Statistics.Recipe.Search.View.view statisticsRecipeSearch)

        StatisticsRecipeSelect statisticsRecipeSelect ->
            Html.map StatisticsRecipeSelectMsg (Pages.Statistics.Recipe.Select.View.view statisticsRecipeSelect)

        StatisticsMealSearch statisticsMealSearch ->
            Html.map StatisticsMealSearchMsg (Pages.Statistics.Meal.Search.View.view statisticsMealSearch)

        StatisticsMealSelect statisticsMealSelect ->
            Html.map StatisticsMealSelectMsg (Pages.Statistics.Meal.Select.View.view statisticsMealSelect)

        ReferenceMaps referenceMaps ->
            Html.map ReferenceMapsMsg (Pages.ReferenceMaps.View.view referenceMaps)

        ReferenceEntries referenceEntries ->
            Html.map ReferenceEntriesMsg (Pages.ReferenceEntries.View.view referenceEntries)

        RequestRegistration requestRegistration ->
            Html.map RequestRegistrationMsg (Pages.Registration.Request.View.view requestRegistration)

        ConfirmRegistration confirmRegistration ->
            Html.map ConfirmRegistrationMsg (Pages.Registration.Confirm.View.view confirmRegistration)

        UserSettings userSettings ->
            Html.map UserSettingsMsg (Pages.UserSettings.View.view userSettings)

        Deletion deletion ->
            Html.map DeletionMsg (Pages.Deletion.View.view deletion)

        RequestRecovery requestRecovery ->
            Html.map RequestRecoveryMsg (Pages.Recovery.Request.View.view requestRecovery)

        ConfirmRecovery confirmRecovery ->
            Html.map ConfirmRecoveryMsg (Pages.Recovery.Confirm.View.view confirmRecovery)

        ComplexFoods complexFoods ->
            Html.map ComplexFoodsMsg (Pages.ComplexFoods.View.view complexFoods)

        NotFound ->
            div [] [ text "Page not found" ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model.page ) of
        ( ClickedLink urlRequest, _ ) ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        ( ChangedUrl url, _ ) ->
            model
                |> lenses.entryRoute.set (url |> parsePage)
                |> followRoute

        ( LoginMsg loginMsg, Login login ) ->
            stepThrough steps.login model (Pages.Login.Handler.update loginMsg login)

        ( FetchToken token, _ ) ->
            model
                |> lenses.jwt.set (Maybe.Extra.filter (String.isEmpty >> not) (Just token))
                |> followRoute

        ( DeleteToken _, _ ) ->
            ( model |> lenses.jwt.set Nothing, Cmd.none )

        ( FetchFoods foods, Ingredients ingredients ) ->
            stepThrough steps.ingredients model (Pages.Ingredients.Handler.update (Pages.Ingredients.Page.UpdateFoods foods) ingredients)

        ( FetchFoods foods, StatisticsFoodSearch statisticsFoodSearch ) ->
            stepThrough steps.statisticsFoodSearch model (Pages.Statistics.Food.Search.Handler.update (Pages.Statistics.Food.Search.Page.UpdateFoods foods) statisticsFoodSearch)

        ( FetchMeasures measures, Ingredients ingredients ) ->
            stepThrough steps.ingredients model (Pages.Ingredients.Handler.update (Pages.Ingredients.Page.UpdateMeasures measures) ingredients)

        ( FetchNutrients nutrients, ReferenceEntries referenceEntries ) ->
            stepThrough steps.referenceEntries model (Pages.ReferenceEntries.Handler.update (Pages.ReferenceEntries.Page.UpdateNutrients nutrients) referenceEntries)

        ( OverviewMsg overviewMsg, Overview overview ) ->
            stepThrough steps.overview model (Pages.Overview.Handler.update overviewMsg overview)

        ( RecipesMsg recipesMsg, Recipes recipes ) ->
            stepThrough steps.recipes model (Pages.Recipes.Handler.update recipesMsg recipes)

        ( IngredientsMsg ingredientsMsg, Ingredients ingredients ) ->
            stepThrough steps.ingredients model (Pages.Ingredients.Handler.update ingredientsMsg ingredients)

        ( MealsMsg mealsMsg, Meals meals ) ->
            stepThrough steps.meals model (Pages.Meals.Handler.update mealsMsg meals)

        ( MealEntriesMsg mealEntryMsg, MealEntries mealEntry ) ->
            stepThrough steps.mealEntries model (Pages.MealEntries.Handler.update mealEntryMsg mealEntry)

        ( StatisticsTimeMsg statisticsTimeMsg, StatisticsTime statisticsTime ) ->
            stepThrough steps.statisticsTime model (Pages.Statistics.Time.Handler.update statisticsTimeMsg statisticsTime)

        ( StatisticsFoodSearchMsg statisticsFoodSearchMsg, StatisticsFoodSearch statisticsFoodSearch ) ->
            stepThrough steps.statisticsFoodSearch model (Pages.Statistics.Food.Search.Handler.update statisticsFoodSearchMsg statisticsFoodSearch)

        ( StatisticsFoodSelectMsg statisticsFoodSelectMsg, StatisticsFoodSelect statisticsFoodSelect ) ->
            stepThrough steps.statisticsFoodSelect model (Pages.Statistics.Food.Select.Handler.update statisticsFoodSelectMsg statisticsFoodSelect)

        ( StatisticsComplexFoodSearchMsg statisticsComplexFoodSearchMsg, StatisticsComplexFoodSearch statisticsComplexFoodSearch ) ->
            stepThrough steps.statisticsComplexFoodSearch model (Pages.Statistics.ComplexFood.Search.Handler.update statisticsComplexFoodSearchMsg statisticsComplexFoodSearch)

        ( StatisticsComplexFoodSelectMsg statisticsComplexFoodSelectMsg, StatisticsComplexFoodSelect statisticsComplexFoodSelect ) ->
            stepThrough steps.statisticsComplexFoodSelect model (Pages.Statistics.ComplexFood.Select.Handler.update statisticsComplexFoodSelectMsg statisticsComplexFoodSelect)

        ( StatisticsRecipeSearchMsg statisticsRecipeSearchMsg, StatisticsRecipeSearch statisticsRecipeSearch ) ->
            stepThrough steps.statisticsRecipeSearch model (Pages.Statistics.Recipe.Search.Handler.update statisticsRecipeSearchMsg statisticsRecipeSearch)

        ( StatisticsRecipeSelectMsg statisticsRecipeSelectMsg, StatisticsRecipeSelect statisticsRecipeSelect ) ->
            stepThrough steps.statisticsRecipeSelect model (Pages.Statistics.Recipe.Select.Handler.update statisticsRecipeSelectMsg statisticsRecipeSelect)

        ( StatisticsMealSearchMsg statisticsMealSearchMsg, StatisticsMealSearch statisticsMealSearch ) ->
            stepThrough steps.statisticsMealSearch model (Pages.Statistics.Meal.Search.Handler.update statisticsMealSearchMsg statisticsMealSearch)

        ( StatisticsMealSelectMsg statisticsMealSelectMsg, StatisticsMealSelect statisticsMealSelect ) ->
            stepThrough steps.statisticsMealSelect model (Pages.Statistics.Meal.Select.Handler.update statisticsMealSelectMsg statisticsMealSelect)

        ( ReferenceMapsMsg referenceMapsMsg, ReferenceMaps referenceMaps ) ->
            stepThrough steps.referenceMaps model (Pages.ReferenceMaps.Handler.update referenceMapsMsg referenceMaps)

        ( ReferenceEntriesMsg referenceEntriesMsg, ReferenceEntries referenceEntries ) ->
            stepThrough steps.referenceEntries model (Pages.ReferenceEntries.Handler.update referenceEntriesMsg referenceEntries)

        ( RequestRegistrationMsg requestRegistrationMsg, RequestRegistration requestRegistration ) ->
            stepThrough steps.requestRegistration model (Pages.Registration.Request.Handler.update requestRegistrationMsg requestRegistration)

        ( ConfirmRegistrationMsg confirmRegistrationMsg, ConfirmRegistration confirmRegistration ) ->
            stepThrough steps.confirmRegistration model (Pages.Registration.Confirm.Handler.update confirmRegistrationMsg confirmRegistration)

        ( UserSettingsMsg userSettingsMsg, UserSettings userSettings ) ->
            stepThrough steps.userSettings model (Pages.UserSettings.Handler.update userSettingsMsg userSettings)

        ( DeletionMsg deletionMsg, Deletion deletion ) ->
            stepThrough steps.deletion model (Pages.Deletion.Handler.update deletionMsg deletion)

        ( RequestRecoveryMsg requestRecoveryMsg, RequestRecovery requestRecovery ) ->
            stepThrough steps.requestRecovery model (Pages.Recovery.Request.Handler.update requestRecoveryMsg requestRecovery)

        ( ConfirmRecoveryMsg confirmRecoveryMsg, ConfirmRecovery confirmRecovery ) ->
            stepThrough steps.confirmRecovery model (Pages.Recovery.Confirm.Handler.update confirmRecoveryMsg confirmRecovery)

        ( ComplexFoodsMsg complexFoodsMsg, ComplexFoods complexFoods ) ->
            stepThrough steps.complexFoods model (Pages.ComplexFoods.Handler.update complexFoodsMsg complexFoods)

        _ ->
            ( model, Cmd.none )


type alias StepParameters model msg =
    { page : model -> Page
    , message : msg -> Msg
    }


steps :
    { login : StepParameters Pages.Login.Page.Model Pages.Login.Page.Msg
    , overview : StepParameters Pages.Overview.Page.Model Pages.Overview.Page.Msg
    , recipes : StepParameters Pages.Recipes.Page.Model Pages.Recipes.Page.Msg
    , ingredients : StepParameters Pages.Ingredients.Page.Model Pages.Ingredients.Page.Msg
    , mealEntries : StepParameters Pages.MealEntries.Page.Model Pages.MealEntries.Page.Msg
    , meals : StepParameters Pages.Meals.Page.Model Pages.Meals.Page.Msg
    , statisticsTime : StepParameters Pages.Statistics.Time.Page.Model Pages.Statistics.Time.Page.Msg
    , statisticsFoodSearch : StepParameters Pages.Statistics.Food.Search.Page.Model Pages.Statistics.Food.Search.Page.Msg
    , statisticsFoodSelect : StepParameters Pages.Statistics.Food.Select.Page.Model Pages.Statistics.Food.Select.Page.Msg
    , statisticsComplexFoodSearch : StepParameters Pages.Statistics.ComplexFood.Search.Page.Model Pages.Statistics.ComplexFood.Search.Page.Msg
    , statisticsComplexFoodSelect : StepParameters Pages.Statistics.ComplexFood.Select.Page.Model Pages.Statistics.ComplexFood.Select.Page.Msg
    , statisticsRecipeSearch : StepParameters Pages.Statistics.Recipe.Search.Page.Model Pages.Statistics.Recipe.Search.Page.Msg
    , statisticsRecipeSelect : StepParameters Pages.Statistics.Recipe.Select.Page.Model Pages.Statistics.Recipe.Select.Page.Msg
    , statisticsMealSearch : StepParameters Pages.Statistics.Meal.Search.Page.Model Pages.Statistics.Meal.Search.Page.Msg
    , statisticsMealSelect : StepParameters Pages.Statistics.Meal.Select.Page.Model Pages.Statistics.Meal.Select.Page.Msg
    , referenceMaps : StepParameters Pages.ReferenceMaps.Page.Model Pages.ReferenceMaps.Page.Msg
    , referenceEntries : StepParameters Pages.ReferenceEntries.Page.Model Pages.ReferenceEntries.Page.Msg
    , requestRegistration : StepParameters Pages.Registration.Request.Page.Model Pages.Registration.Request.Page.Msg
    , confirmRegistration : StepParameters Pages.Registration.Confirm.Page.Model Pages.Registration.Confirm.Page.Msg
    , userSettings : StepParameters Pages.UserSettings.Page.Model Pages.UserSettings.Page.Msg
    , deletion : StepParameters Pages.Deletion.Page.Model Pages.Deletion.Page.Msg
    , requestRecovery : StepParameters Pages.Recovery.Request.Page.Model Pages.Recovery.Request.Page.Msg
    , confirmRecovery : StepParameters Pages.Recovery.Confirm.Page.Model Pages.Recovery.Confirm.Page.Msg
    , complexFoods : StepParameters Pages.ComplexFoods.Page.Model Pages.ComplexFoods.Page.Msg
    }
steps =
    { login = StepParameters Login LoginMsg
    , overview = StepParameters Overview OverviewMsg
    , recipes = StepParameters Recipes RecipesMsg
    , ingredients = StepParameters Ingredients IngredientsMsg
    , mealEntries = StepParameters MealEntries MealEntriesMsg
    , meals = StepParameters Meals MealsMsg
    , statisticsTime = StepParameters StatisticsTime StatisticsTimeMsg
    , statisticsFoodSearch = StepParameters StatisticsFoodSearch StatisticsFoodSearchMsg
    , statisticsFoodSelect = StepParameters StatisticsFoodSelect StatisticsFoodSelectMsg
    , statisticsComplexFoodSearch = StepParameters StatisticsComplexFoodSearch StatisticsComplexFoodSearchMsg
    , statisticsComplexFoodSelect = StepParameters StatisticsComplexFoodSelect StatisticsComplexFoodSelectMsg
    , statisticsRecipeSearch = StepParameters StatisticsRecipeSearch StatisticsRecipeSearchMsg
    , statisticsRecipeSelect = StepParameters StatisticsRecipeSelect StatisticsRecipeSelectMsg
    , statisticsMealSearch = StepParameters StatisticsMealSearch StatisticsMealSearchMsg
    , statisticsMealSelect = StepParameters StatisticsMealSelect StatisticsMealSelectMsg
    , referenceMaps = StepParameters ReferenceMaps ReferenceMapsMsg
    , referenceEntries = StepParameters ReferenceEntries ReferenceEntriesMsg
    , requestRegistration = StepParameters RequestRegistration RequestRegistrationMsg
    , confirmRegistration = StepParameters ConfirmRegistration ConfirmRegistrationMsg
    , userSettings = StepParameters UserSettings UserSettingsMsg
    , deletion = StepParameters Deletion DeletionMsg
    , requestRecovery = StepParameters RequestRecovery RequestRecoveryMsg
    , confirmRecovery = StepParameters ConfirmRecovery ConfirmRecoveryMsg
    , complexFoods = StepParameters ComplexFoods ComplexFoodsMsg
    }


stepThrough : { page : model -> Page, message : msg -> Msg } -> Model -> ( model, Cmd msg ) -> ( Model, Cmd Msg )
stepThrough ps model ( subModel, cmd ) =
    ( { model | page = ps.page subModel }, Cmd.map ps.message cmd )


type Route
    = LoginRoute
    | OverviewRoute
    | RecipesRoute
    | IngredientRoute RecipeId
    | MealsRoute
    | MealEntriesRoute MealId
    | StatisticsTimeRoute
    | StatisticsFoodSearchRoute
    | StatisticsFoodSelectRoute FoodId
    | StatisticsComplexFoodSearchRoute
    | StatisticsComplexFoodSelectRoute ComplexFoodId
    | StatisticsRecipeSearchRoute
    | StatisticsRecipeSelectRoute RecipeId
    | StatisticsMealSearchRoute
    | StatisticsMealSelectRoute MealId
    | ReferenceMapsRoute
    | ReferenceEntriesRoute ReferenceMapId
    | RequestRegistrationRoute
    | ConfirmRegistrationRoute UserIdentifier JWT
    | UserSettingsRoute
    | DeletionRoute UserIdentifier JWT
    | RequestRecoveryRoute
    | ConfirmRecoveryRoute UserIdentifier JWT
    | ComplexFoodsRoute


plainRouteParser : Parser (Route -> a) a
plainRouteParser =
    Parser.oneOf
        [ route Addresses.Frontend.login.parser LoginRoute
        , route Addresses.Frontend.overview.parser OverviewRoute
        , route Addresses.Frontend.recipes.parser RecipesRoute
        , route Addresses.Frontend.ingredientEditor.parser IngredientRoute
        , route Addresses.Frontend.meals.parser MealsRoute
        , route Addresses.Frontend.mealEntryEditor.parser MealEntriesRoute
        , route Addresses.Frontend.statisticsTime.parser StatisticsTimeRoute
        , route Addresses.Frontend.statisticsFoodSearch.parser StatisticsFoodSearchRoute
        , route Addresses.Frontend.statisticsFoodSelect.parser StatisticsFoodSelectRoute
        , route Addresses.Frontend.statisticsComplexFoodSearch.parser StatisticsComplexFoodSearchRoute
        , route Addresses.Frontend.statisticsComplexFoodSelect.parser StatisticsComplexFoodSelectRoute
        , route Addresses.Frontend.statisticsRecipeSearch.parser StatisticsRecipeSearchRoute
        , route Addresses.Frontend.statisticsRecipeSelect.parser StatisticsRecipeSelectRoute
        , route Addresses.Frontend.statisticsMealSearch.parser StatisticsMealSearchRoute
        , route Addresses.Frontend.statisticsMealSelect.parser StatisticsMealSelectRoute
        , route Addresses.Frontend.referenceMaps.parser ReferenceMapsRoute
        , route Addresses.Frontend.referenceEntries.parser ReferenceEntriesRoute
        , route Addresses.Frontend.requestRegistration.parser RequestRegistrationRoute
        , route Addresses.Frontend.confirmRegistration.parser ConfirmRegistrationRoute
        , route Addresses.Frontend.userSettings.parser UserSettingsRoute
        , route Addresses.Frontend.deleteAccount.parser DeletionRoute
        , route Addresses.Frontend.requestRecovery.parser RequestRecoveryRoute
        , route Addresses.Frontend.confirmRecovery.parser ConfirmRecoveryRoute
        , route Addresses.Frontend.complexFoods.parser ComplexFoodsRoute
        ]


parsePage : Url -> Maybe Route
parsePage =
    fragmentToPath >> Parser.parse plainRouteParser


followRoute : Model -> ( Model, Cmd Msg )
followRoute model =
    case ( model.jwt, model.entryRoute ) of
        ( _, Nothing ) ->
            ( { model | page = NotFound }, Cmd.none )

        ( Nothing, Just _ ) ->
            Pages.Login.Handler.init { configuration = model.configuration } |> stepThrough steps.login model

        ( Just userJWT, Just entryRoute ) ->
            let
                authorizedAccess =
                    { configuration = model.configuration, jwt = userJWT }

                flags =
                    { authorizedAccess = authorizedAccess }
            in
            case entryRoute of
                LoginRoute ->
                    Pages.Login.Handler.init { configuration = model.configuration } |> stepThrough steps.login model

                OverviewRoute ->
                    Pages.Overview.Handler.init flags |> stepThrough steps.overview model

                RecipesRoute ->
                    Pages.Recipes.Handler.init flags |> stepThrough steps.recipes model

                IngredientRoute recipeId ->
                    Pages.Ingredients.Handler.init
                        { authorizedAccess = authorizedAccess
                        , recipeId = recipeId
                        }
                        |> stepThrough steps.ingredients model

                MealsRoute ->
                    Pages.Meals.Handler.init flags |> stepThrough steps.meals model

                MealEntriesRoute mealId ->
                    Pages.MealEntries.Handler.init
                        { authorizedAccess = authorizedAccess
                        , mealId = mealId
                        }
                        |> stepThrough steps.mealEntries model

                StatisticsTimeRoute ->
                    Pages.Statistics.Time.Handler.init
                        flags
                        |> stepThrough steps.statisticsTime model

                StatisticsFoodSearchRoute ->
                    Pages.Statistics.Food.Search.Handler.init
                        flags
                        |> stepThrough steps.statisticsFoodSearch model

                StatisticsFoodSelectRoute foodId ->
                    Pages.Statistics.Food.Select.Handler.init
                        { authorizedAccess = authorizedAccess
                        , foodId = foodId
                        }
                        |> stepThrough steps.statisticsFoodSelect model

                StatisticsComplexFoodSearchRoute ->
                    Pages.Statistics.ComplexFood.Search.Handler.init
                        flags
                        |> stepThrough steps.statisticsComplexFoodSearch model

                StatisticsComplexFoodSelectRoute complexFoodId ->
                    Pages.Statistics.ComplexFood.Select.Handler.init
                        { authorizedAccess = authorizedAccess
                        , complexFoodId = complexFoodId
                        }
                        |> stepThrough steps.statisticsComplexFoodSelect model

                StatisticsRecipeSearchRoute ->
                    Pages.Statistics.Recipe.Search.Handler.init
                        flags
                        |> stepThrough steps.statisticsRecipeSearch model

                StatisticsRecipeSelectRoute recipeId ->
                    Pages.Statistics.Recipe.Select.Handler.init
                        { authorizedAccess = authorizedAccess
                        , recipeId = recipeId
                        }
                        |> stepThrough steps.statisticsRecipeSelect model

                StatisticsMealSearchRoute ->
                    Pages.Statistics.Meal.Search.Handler.init
                        flags
                        |> stepThrough steps.statisticsMealSearch model

                StatisticsMealSelectRoute mealId ->
                    Pages.Statistics.Meal.Select.Handler.init
                        { authorizedAccess = authorizedAccess
                        , mealId = mealId
                        }
                        |> stepThrough steps.statisticsMealSelect model

                ReferenceMapsRoute ->
                    Pages.ReferenceMaps.Handler.init flags |> stepThrough steps.referenceMaps model

                ReferenceEntriesRoute referenceMapId ->
                    Pages.ReferenceEntries.Handler.init
                        { authorizedAccess = authorizedAccess
                        , referenceMapId = referenceMapId
                        }
                        |> stepThrough steps.referenceEntries model

                RequestRegistrationRoute ->
                    Pages.Registration.Request.Handler.init { configuration = model.configuration } |> stepThrough steps.requestRegistration model

                ConfirmRegistrationRoute userIdentifier jwt ->
                    Pages.Registration.Confirm.Handler.init
                        { configuration = authorizedAccess.configuration
                        , userIdentifier = userIdentifier
                        , registrationJWT = jwt
                        }
                        |> stepThrough steps.confirmRegistration model

                UserSettingsRoute ->
                    Pages.UserSettings.Handler.init flags |> stepThrough steps.userSettings model

                DeletionRoute userIdentifier jwt ->
                    Pages.Deletion.Handler.init
                        { configuration = authorizedAccess.configuration
                        , userIdentifier = userIdentifier
                        , deletionJWT = jwt
                        }
                        |> stepThrough steps.deletion model

                RequestRecoveryRoute ->
                    Pages.Recovery.Request.Handler.init { configuration = model.configuration } |> stepThrough steps.requestRecovery model

                ConfirmRecoveryRoute userIdentifier jwt ->
                    Pages.Recovery.Confirm.Handler.init
                        { configuration = authorizedAccess.configuration
                        , userIdentifier = userIdentifier
                        , recoveryJwt = jwt
                        }
                        |> stepThrough steps.confirmRecovery model

                ComplexFoodsRoute ->
                    Pages.ComplexFoods.Handler.init { authorizedAccess = authorizedAccess }
                        |> stepThrough steps.complexFoods model


fragmentToPath : Url -> Url
fragmentToPath url =
    { url | path = Maybe.withDefault "" url.fragment, fragment = Nothing }


route : Parser a b -> a -> Parser (b -> c) c
route =
    flip Parser.map
