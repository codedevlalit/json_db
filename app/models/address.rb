class Address < JsonModel
    include ActiveModel::Model  

    belongs_to :user, class_name: 'User'#, foreign_key: 'user_id', optional: true
    attr_accessor :line1, :line2, :city, :state, :zip_code, :country, :user_id
    # validates :user_id, presence: true
    # validates :line1, presence: true
    # validates :city, presence: true
    # validates :state, presence: true
    # validates :zip_code, presence: true, format: { with: /\A\d{5}(-\d{4})?\z/, message: "must be a valid ZIP code" }
    # validates :country, presence: true, inclusion: { in: %w[India USA Canada Mexico], message: "%{value} is not a valid country" }

    def full_address
        [line1, line2, city, state, zip_code, country].compact.join(', ')
    end

    def to_h
        {
            'line1' => line1,
            'line2' => line2,
            'city' => city,
            'state' => state,
            'zip_code' => zip_code,
            'country' => country
        }
    end

  end
  