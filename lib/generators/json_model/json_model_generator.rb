# /home/codedev/ror_json/json_db/lib/generators/json_model/json_model_generator.rb

require 'rails/generators'

class JsonModelGenerator < Rails::Generators::Base
    source_root File.expand_path('templates', __dir__)
    argument :model_name, type: :string
    argument :attributes, type: :array, default: [], banner: "attribute attribute"

    def create_model_file
        file_path = File.join('app/models', "#{model_name.underscore}.rb")
        processed_attributes = attributes.map do |attr|
            if attr.end_with?(':references')
                attr_name = attr.split(':').first
                "#{attr_name}_id"
            else
                attr
            end
        end

        associations = attributes.select { |attr| attr.end_with?(':references') }.map do |attr|
            attr_name = attr.split(':').first
            "belongs_to :#{attr_name}, class_name: '#{attr_name.camelize}'"
        end

        create_file file_path, <<~FILE_CONTENT
            class #{model_name.camelize} < JsonModel
                include ActiveModel::Model

                attr_accessor #{processed_attributes.map { |attr| ":#{attr}" }.join(', ')}

                #{associations.join("\n    ")}
            end
        FILE_CONTENT
    end
end

# Example usage:
# To generate a new JSON model, run the following command in your terminal:
# rails generate json_model ModelName attribute1 attribute2 attribute3

# For example:
# rails generate json_model User name email age

# This will create a file `app/models/user.rb` with the following content:
# class User < JsonModel
#   include ActiveModel::Model
#
#   attr_accessor :name, :email, :age
# end