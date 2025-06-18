class Book < JsonModel
    include ActiveModel::Model

    attr_accessor :name, :author
end
