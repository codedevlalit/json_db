class User < JsonDatabase
    include ActiveModel::Model

    has_many :addresses, class_name: 'Address', foreign_key: 'user_id', dependent: :destroy
  
    attr_accessor :name, :email
    validates :name, presence: true
    validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  end
  