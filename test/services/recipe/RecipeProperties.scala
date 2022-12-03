package services.recipe

import org.scalacheck.Properties

object RecipeProperties extends Properties("Recipe service") {

  property("Creation") = ???
  property("Read single") = ???
  property("Read all") = ???
  property("Update") = ???
  property("Delete") = ???

  property("Add ingredient") = ???
  property("Read ingredients") = ???
  property("Update ingredient") = ???
  property("Delete ingredient") = ???

  property("Creation (wrong user)") = ???
  property("Read single (wrong user)") = ???
  property("Read all (wrong user)") = ???
  property("Update (wrong user)") = ???
  property("Delete (wrong user)") = ???

  property("Add ingredient (wrong user)") = ???
  property("Read ingredients (wrong user)") = ???
  property("Update ingredient (wrong user)") = ???
  property("Delete ingredient (wrong user)") = ???
}
