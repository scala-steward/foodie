package db

case class DbIngredient(name: String,
                        nutrients: Iterable[DbNutrientEntry]) {

}
