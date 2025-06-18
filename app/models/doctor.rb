class Doctor < JsonModel
    include ActiveModel::Model
    has_many :patients, class_name: 'Patient', through: :appointments
    has_many :appointments, class_name: 'Appointment'
    attr_accessor :name, :specialization
end
