# frozen_string_literal: true

module Sanitize
  # exclude every invisible character, except those that are used to combine emojis
  INVISIBLE_CHARACTERS = /[\p{Cf}&&[^\u200C\u200D\u{E0020}-\u{E007F}]]/

  module_function

  def sanitize_text(text)
    text.to_s
      .scrub("")
      .gsub(INVISIBLE_CHARACTERS, "")
      .unicode_normalize(:nfc)
      .squish
  end
end
