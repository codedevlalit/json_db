class Supplier < JsonModel
    include ActiveModel::Model

    has_one :account, class_name: 'Account'
    has_one :account_history, class_name: "AccountHistory", through: :account

    attr_accessor :name

    
end
