class AccountHistory < JsonModel
    include ActiveModel::Model

    attr_accessor :purpose, :time, :amount, :behaviour, :account_id

    belongs_to :account, class_name: 'Account'
end
