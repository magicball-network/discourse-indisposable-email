# frozen_string_literal: true

def die_file_fixture(*path)
  File.new(
    Rails.root.join(
      "plugins",
      "discourse-indisposable-email",
      "spec",
      "fixtures",
      *path
    )
  )
end
