class User < JsonRecord
    include ActiveModel::Model

    has_many :addresses, class_name: 'Address', foreign_key: 'user_id', dependent: :destroy
  
    attr_accessor :name, :email

    validates :name, presence: true
    validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }


    def update(attributes)
      self.class.update(id, attributes)
      attributes.each do |key, value|
      send("#{key}=", value) if respond_to?("#{key}=")
      end
      self.class.reload(id) # Ensure the updated user is captured correctly
    end

  end
  