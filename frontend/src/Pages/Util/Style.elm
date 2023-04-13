module Pages.Util.Style exposing (..)

import Html exposing (Attribute)
import Html.Attributes exposing (class, id)


classes :
    { addElement : Attribute msg
    , addView : Attribute msg
    , button :
        { add : Attribute msg
        , alternative : Attribute msg
        , cancel : Attribute msg
        , confirm : Attribute msg
        , delete : Attribute msg
        , edit : Attribute msg
        , editor : Attribute msg
        , error : Attribute msg
        , logout : Attribute msg
        , menu : Attribute msg
        , navigation : Attribute msg
        , nutrients : Attribute msg
        , overview : Attribute msg
        , pager : Attribute msg
        , rescale : Attribute msg
        , select : Attribute msg
        }
    , choices : Attribute msg
    , choiceTable : Attribute msg
    , confirm : Attribute msg
    , controlsGroup : Attribute msg
    , controls : Attribute msg
    , date : Attribute msg
    , descriptionColumn : Attribute msg
    , disabled : Attribute msg
    , editable : Attribute msg
    , editing : Attribute msg
    , editLine : Attribute msg
    , elements : Attribute msg
    , elementsWithControlsTable : Attribute msg
    , elementEditTable : Attribute msg
    , ellipsis : Attribute msg
    , incomplete : Attribute msg
    , info : Attribute msg
    , intervalSelection : Attribute msg
    , mealEditTable : Attribute msg
    , meals : Attribute msg
    , numberCell : Attribute msg
    , numberLabel : Attribute msg
    , nutrients : Attribute msg
    , pagination : Attribute msg
    , partialStatistics : Attribute msg
    , rating :
        { low : Attribute msg
        , exact : Attribute msg
        , high : Attribute msg
        }
    , request : Attribute msg
    , recipeEditTable : Attribute msg
    , referenceMapEditTable : Attribute msg
    , search :
        { area : Attribute msg
        , field : Attribute msg
        }
    , sortControls : Attribute msg
    , tableHeader : Attribute msg
    , time : Attribute msg
    , toggle : Attribute msg
    }
classes =
    { addElement = class "add-element"
    , addView = class "add-view"
    , button =
        { add = class "add-button"
        , alternative = class "alternative-button"
        , cancel = class "cancel-button"
        , confirm = class "confirm-button"
        , delete = class "delete-button"
        , edit = class "edit-button"
        , editor = class "editor-button"
        , error = class "error-button"
        , logout = class "logout-button"
        , menu = class "menu-button"
        , navigation = class "navigation-button"
        , nutrients = class "nutrients-button"
        , overview = class "overview-button"
        , pager = class "pager-button"
        , rescale = class "rescale-button"
        , select = class "select-button"
        }
    , choices = class "choices"
    , choiceTable = class "choice-table"
    , confirm = class "confirm"
    , controlsGroup = class "controls-group"
    , controls = class "controls"
    , date = class "date"
    , descriptionColumn = class "description-column"
    , disabled = class "disabled"
    , editable = class "editable"
    , editing = class "editing"
    , editLine = class "edit-line"
    , elements = class "elements"
    , elementEditTable = class "element-edit-table"
    , elementsWithControlsTable = class "elements-with-controls-table"
    , ellipsis = class "ellipsis"
    , incomplete = class "incomplete"
    , info = class "info"
    , intervalSelection = class "interval-section"
    , mealEditTable = class "meal-edit-table"
    , meals = class "meals"
    , numberCell = class "number-cell"
    , numberLabel = class "number-label"
    , nutrients = class "nutrients"
    , pagination = class "pagination"
    , partialStatistics = class "partial-statistics"
    , rating =
        { low = class "low"
        , exact = class "exact"
        , high = class "high"
        }
    , request = class "request"
    , recipeEditTable = class "recipe-edit-table"
    , referenceMapEditTable = class "reference-map-edit-table"
    , search =
        { area = class "search-area"
        , field = class "search-field"
        }
    , sortControls = class "sort-controls"
    , tableHeader = class "table-header"
    , time = class "time"
    , toggle = class "toggle"
    }


ids :
    { add : Attribute msg
    , addMealView : Attribute msg
    , addRecipeView : Attribute msg
    , addReferenceMapView : Attribute msg
    , complexFoodEditor : Attribute msg
    , error : Attribute msg
    , ingredientEditor : Attribute msg
    , mealEntryEditor : Attribute msg
    , navigation : Attribute msg
    , overviewMain : Attribute msg
    , referenceEntryEditor : Attribute msg
    , statistics :
        { food : Attribute msg
        , complexFood : Attribute msg
        , meal : Attribute msg
        , recipe : Attribute msg
        , time : Attribute msg
        , recipeOccurrence : Attribute msg
        }
    }
ids =
    { add = id "add"
    , addMealView = id "add-meal-view"
    , addRecipeView = id "add-recipe-view"
    , addReferenceMapView = id "add-reference-map-view"
    , complexFoodEditor = id "complex-food-editor"
    , error = id "error"
    , ingredientEditor = id "ingredient-editor"
    , mealEntryEditor = id "meal-entry-editor"
    , navigation = id "navigation"
    , overviewMain = id "overview-main"
    , referenceEntryEditor = id "reference-entry-editor"
    , statistics =
        { food = id "statistics-food"
        , complexFood = id "statistics-complex-food"
        , meal = id "statistics-meal"
        , recipe = id "statistics-recipe"
        , time = id "statistics"
        , recipeOccurrence = id "statistics-recipe-occurrence"
        }
    }
