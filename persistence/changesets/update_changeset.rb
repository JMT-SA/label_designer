# Basic changeset to use for ROM updates.
# This mixes in the touching of the +updated_at+ field.
class UpdateChangeset < ROM::Changeset::Update
  map do
    touch :updated_at
  end
end
