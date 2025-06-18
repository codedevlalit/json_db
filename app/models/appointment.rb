class Appointment < JsonModel
    include ActiveModel::Model

    attr_accessor :doctor_id, :patient_id

    belongs_to :doctor, class_name: 'Doctor'
    belongs_to :patient, class_name: 'Patient'
end
