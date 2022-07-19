package services.recipe

case class RecipeUpdate(
    id: RecipeId,
    name: String,
    description: Option[String]
)
