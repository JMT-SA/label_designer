# Basic changeset to use for ROM creates.
# This mixes in the creating of +created_at+ and +updated_at+ values.
class NewChangeset < ROM::Changeset::Create
  map do
    add_timestamps
  end
end
