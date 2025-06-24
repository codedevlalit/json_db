class Author < JsonModel
    include ActiveModel::Model

    attr_accessor :publisher_id

    belongs_to :publisher, class_name: 'Publisher'
    has_many :books, class_name: 'Book'
end
