package services.complex.ingredient

import org.scalacheck.Properties

object ComplexIngredientServiceProperties extends Properties("Complex ingredient service") {

  property("Fetch all") = ???
  property("Create (success)") = ???
  property("Create (failure)") = ???
  property("Update (success)") = ???
  property("Update (failure)") = ???
  property("Delete (existent)") = ???
  property("Delete (non-existent)") = ???

  property("Fetch all (wrong user)") = ???
  property("Create (wrong user)") = ???
  property("Update (wrong user)") = ???
  property("Delete (wrong user)") = ???

}
