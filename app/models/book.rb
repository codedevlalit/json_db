class Book < JsonModel
    include ActiveModel::Model
    belongs_to :author, class_name: 'Author'
    has_one :publisher, class_name: 'Publisher', through: :author

    attr_accessor :title, :author
end
