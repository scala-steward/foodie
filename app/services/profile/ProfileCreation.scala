package services.profile

import db.ProfileId

case class ProfileCreation(
    name: String
)

object ProfileCreation {

  def create(profileId: ProfileId, profileCreation: ProfileCreation): Profile =
    Profile(
      id = profileId,
      name = profileCreation.name.trim
    )

}
