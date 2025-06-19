class Account < JsonModel
    include ActiveModel::Model

    attr_accessor :name, :supplier_id

    belongs_to :supplier, class_name: 'Supplier'
    has_one :account_history, class_name: 'AccountHistory'
end
