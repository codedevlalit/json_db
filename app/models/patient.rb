class Patient < JsonModel
    include ActiveModel::Model
    has_many :doctors, class_name: 'Doctor', through: :appointments
    has_many :appointments, class_name: 'Appointment'

    attr_accessor :name, :problem
end
