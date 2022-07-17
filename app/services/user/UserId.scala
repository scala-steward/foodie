package services.user

import utils.IdOf

sealed trait UserId

object UserId extends IdOf[UserId]
