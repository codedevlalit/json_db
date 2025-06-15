class State < JsonRecord
    include ActiveModel::Model

    attr_accessor :name, :code
end
