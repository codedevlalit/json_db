class Book < JsonRecord
    include ActiveModel::Model

    attr_accessor :name, :author
end
