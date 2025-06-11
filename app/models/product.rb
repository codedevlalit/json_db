class Product < JsonDatabase
    include ActiveModel::Model
  
    attr_accessor :name, :price_region
    validates :name, presence: true
    validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  end
  