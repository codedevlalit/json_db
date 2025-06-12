require 'json'
require 'ostruct'
require 'active_support/core_ext/string'

class JsonModel

    def self.has_many(association_name, class_name:, foreign_key: nil, dependent: nil)
        define_method(association_name) do
            key = foreign_key || "#{self.class.name.underscore}_id"
            class_name.constantize.all.select { |record| record.send(key) == self.id }
        end

        if dependent == :destroy
            define_method("destroy_#{association_name}") do
                send(association_name).each(&:destroy)
            end
        end
    end

    def self.belongs_to(association_name, class_name:, foreign_key: nil, optional: false)
        define_method(association_name) do
            key = foreign_key || "#{association_name}_id"
            id = self.send(key)
            return nil if optional && id.nil?
            class_name.constantize.find(id)
        end
    end
    
    def self.file_path
        "db/#{name.underscore}.json"
    end

    def self.setup
        Dir.mkdir('db') unless Dir.exist?('db')
        File.write(file_path, '[]') unless File.exist?(file_path)
    end

    def self.all
        JSON.parse(File.read(file_path)).map { |record| self.new(record) } rescue []
    end

    def self.find(id)
        all.find { |record| record.id == id }
    end

    def self.find_by(attributes)
        all.find { |record| attributes.all? { |key, value| record.send(key) == value } }
    end

    # Define the attributes dynamically based on the attr_accessor methods
    def self.attribute_accessors
        @attribute_accessors ||= self.instance_methods(false).grep(/=$/).map { |method| method.to_s.chomp('=') }
    end

    # Define the attributes for validation
    def self.attributes
        self.instance_methods(false).grep(/=$/).map { |method| method.to_s.chomp('=') }
    end

    def self.new(attributes = {})
        default_attributes = { 'id' => nil, 'created_at' => nil, 'updated_at' => nil }

        attribute_accessors = self.attribute_accessors || []
        
        merged_attributes = attribute_accessors.each_with_object({}) { |key, hash| hash[key.to_s] = nil }
        Record.new(default_attributes.merge(merged_attributes).merge(attributes))
    end

    def self.create(attributes)
        attributes = { 'id' => next_id(all.map(&:to_h) ) }.merge(attributes)
        data = all.map(&:to_h)
        timestamp = Time.now.to_s
        new_record = attributes.merge('created_at' => timestamp, 'updated_at' => timestamp)
        data << new_record
        save(data)
        Record.new(new_record)
    end

    def self.update(id, attributes)
        # binding.pry
        data = JSON.parse(File.read(file_path)) rescue []
        record = data.find { |r| r['id'] == id }
        return nil unless record

        attributes.each_key do |key|
            record[key.to_s] = attributes[key] # if record.key?(key.to_s)
        end
        record['updated_at'] = Time.now.to_s

        File.write(file_path, JSON.pretty_generate(data))
        Record.new(record)
    end

    def self.destroy(id)
        data = all.map(&:to_h)
        data.reject! { |record| record['id'] == id }
        save(data)
    end

    def self.first
        all.first
    end

    def self.last
        all.last
    end

    def self.count
        all.size
    end

    def self.update_all(attributes)
        timestamp = Time.now.to_s
        data = all.map(&:to_h).map do |record|
            attributes.each do |key, value|
                record[key.to_s] = value if record.key?(key.to_s)
            end
            record.merge('updated_at' => timestamp)
        end
        save(data)
    end

    def self.destroy_all
        save([])
    end

    private

    def self.save(data)
        File.write(file_path, JSON.pretty_generate(data))
    end

    def self.next_id(data)
        data.map { |record| record['id'] }.max.to_i + 1
    end

    class Record
        def initialize(attributes)
            @attributes = attributes
        end

        def method_missing(method_name, *args, &block)
            if @attributes.key?(method_name.to_s)
                @attributes[method_name.to_s]
            else
                super
            end
        end

        def respond_to_missing?(method_name, include_private = false)
            @attributes.key?(method_name.to_s) || super
        end

        def to_h
            @attributes
        end

        def update(attributes)
            binding.pry
            
        end

        # def update(attributes)
        #     attributes.each do |key, value|
        #         if @attributes.key?(key.to_s)
        #             @attributes[key.to_s] = value
        #         else
        #             raise NoMethodError, "undefined method `#{key}` for #{self.class.name}"
        #         end
        #     end
        #     @attributes['updated_at'] = Time.now.to_s
        #     JsonModel.send(:save, JsonModel.all.map(&:to_h))
        #     self
        # end

        # def update(id, attributes)
        #     record = JsonModel.find(id)
        #     return nil unless record
        #     record.update(attributes)
        # end

        # # Destroy the record by removing it from the JSON file
        # # It finds the record by id, removes it from the data array, and saves the updated data back to the file.
        # # Returns the destroyed record instance.
        # def destroy
        #     data = JsonModel.all.map(&:to_h)
        #     data.reject! { |record| record['id'] == @attributes['id'] }
        #     JsonModel.send(:save, data)
        #     self
        # end

        # def id
        #     @attributes['id']
        # end
        # def created_at
        #     @attributes['created_at']
        # end
        # def updated_at
        #     @attributes['updated_at']
        # end
        # def to_json(*_args)
        #     @attributes.to_json
        # end
        # def to_s
        #     @attributes.to_s
        # end
        # def inspect
        #     @attributes.inspect
        # end
        # def ==(other)
        #     return false unless other.is_a?(Record)
        #     @attributes['id'] == other.id && @attributes == other.to_h
        # end
        # def eql?(other)
        #     return false unless other.is_a?(Record)
        #     @attributes['id'] == other.id && @attributes.eql?(other.to_h)
        # end
        # def hash
        #     @attributes['id'].hash ^ @attributes.hash
        # end
        # def self.create(attributes)
        #     new_record = JsonModel.new(attributes)
        #     new_record.save
        #     new_record
        # end
        
        # def self.find(id)
        #     record = JsonModel.find(id)
        #     return nil unless record
        #     new(record.to_h)
        # end

        # def self.where(conditions)
        #     JsonModel.all.select do |record|
        #         conditions.all? { |key, value| record.send(key) == value }
        #     end.map(&:to_h).map { |attrs| new(attrs) }
        # end
        # def self.all
        #     JsonModel.all.map(&:to_h).map { |attrs| new(attrs) }
        # end

        # def self.first
        #     record = JsonModel.first
        #     return nil unless record
        #     new(record.to_h)
        # end

        # def self.last
        #     record = JsonModel.last
        #     return nil unless record
        #     new(record.to_h)
        # end

        # def self.count
        #     JsonModel.count
        # end
        # def self.destroy(id)
        #     record = JsonModel.find(id)
        #     return nil unless record
        #     record.destroy
        # end

        # def self.destroy_all
        #     JsonModel.destroy_all
        # end
        # def self.update_all(attributes)
        #     JsonModel.update_all(attributes)
        # end

        # def self.reload(id)
        #     record = JsonModel.find(id)
        #     return nil unless record
        #     new(record.to_h)
        # end

        # def self.save_all(records)  
        #     data = records.map(&:to_h)
        #     JsonModel.send(:save, data)
        # end

        # def self.next_id
        #     JsonModel.send(:next_id, JsonModel.all.map(&:to_h))
        # end

        # def self.setup
        #     JsonModel.send(:setup)
        # end

        # Save the record to the JSON file
        # If the record has an id, it updates the existing record
        # If the record does not have an id, it creates a new record

        def save
            if @attributes['id'].nil?
                # Create new record
                @attributes['id'] = JsonModel.send(:next_id, JsonModel.all.map(&:to_h))
                @attributes['created_at'] = Time.now.to_s
                @attributes['updated_at'] = Time.now.to_s
                data = JsonModel.all.map(&:to_h)
                data << @attributes
                JsonModel.send(:save, data)
            else
                # Update existing record
                @attributes['updated_at'] = Time.now.to_s
                data = JsonModel.all.map(&:to_h)
                record = data.find { |r| r['id'] == @attributes['id'] }
                record.merge!(@attributes)
                JsonModel.send(:save, data)
            end
            self
        end
    end
end
