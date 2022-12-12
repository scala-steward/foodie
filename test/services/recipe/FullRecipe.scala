package services.recipe

case class FullRecipe(
    recipe: Recipe,
    ingredients: List[Ingredient]
)
