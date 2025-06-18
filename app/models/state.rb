class State < JsonModel
    include ActiveModel::Model

    attr_accessor :name, :code
end
