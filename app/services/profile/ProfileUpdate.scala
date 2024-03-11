package services.profile

case class ProfileUpdate(
    name: String
)

object ProfileUpdate {

  def update(profile: Profile, profileUpdate: ProfileUpdate): Profile =
    profile.copy(
      name = profileUpdate.name.trim
    )

}
