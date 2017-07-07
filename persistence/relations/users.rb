class Users < ROM::Relation[:sql]
  schema(infer: true)
  # schema(infer: true) do
  #   attribute :user_name, Types::String, read: Types.Constructor(Symbol, &:to_sym)
  # end
  def index
    select { [id.qualified, user_name.qualified] }
    # where { (id < 10) | (id > 150) }
  end
end
