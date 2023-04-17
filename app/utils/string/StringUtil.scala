package utils.string

import java.util.Base64

object StringUtil {

  def toBase64String(bytes: Array[Byte]): String =
    Base64.getEncoder.encodeToString(bytes)

  object syntax {

    implicit class ByteArrayToBase64String(val bytes: Array[Byte]) extends AnyVal {
      def asBase64String: String = toBase64String(bytes)
    }

  }

}
