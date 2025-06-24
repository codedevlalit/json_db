class Publisher < JsonModel
    include ActiveModel::Model

    attr_accessor :name
    has_many :authors, class_name: 'Author'
    
end
