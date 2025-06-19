require 'json'
require 'ostruct'
require 'active_support/core_ext/string'

class JsonRecord
    
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

    def self.has_many(association_name, class_name:, foreign_key: nil, dependent: nil, through: nil)
        if through
            define_method(association_name) do
                through_records = send(through)
                ids = through_records.map { |record| record.send("#{class_name.underscore}_id") }
                class_name.constantize.all.select { |record| ids.include?(record.id) }
            end
        else
            define_method(association_name) do
                key = foreign_key || "#{self.class.name.underscore}_id"
                class_name.constantize.all.select do |record|
                    record.send(key) == self.id
                end
            end
        end

        if dependent == :destroy
            define_method("destroy_#{association_name}") do
                send(association_name).each(&:destroy)
            end
        end

        JsonRecord::Record.define_method(association_name) do
            if through
                through_records = send(through)
                ids = through_records.map { |record| record.send("#{class_name.underscore}_id") }
                class_name.constantize.all.select { |record| ids.include?(record.id) }
            else
                key = foreign_key || "#{self._class.constantize.name.underscore}_id"
                class_name.constantize.all.select do |record|
                    record.send(key) == self.id
                end
            end
        end
    end

    def self.has_one(association_name, class_name:, foreign_key: nil, optional: false, through: nil)
        if through
            define_method(association_name) do
                through_records = send(through)
                ids = through_records.map { |record| record.send("#{class_name.underscore}_id") }
                class_name.constantize.all.select { |record| ids.include?(record.id) }
            end
        else
            define_method(association_name) do
                key = foreign_key || "#{self.class.name.underscore}_id"
                class_name.constantize.all.select do |record|
                    record.send(key) == self.id
                end
            end
        end

        if dependent == :destroy
            define_method("destroy_#{association_name}") do
                send(association_name).each(&:destroy)
            end
        end

        JsonRecord::Record.define_method(association_name) do
            if through
                through_records = send(through)
                ids = through_records.map { |record| record.send("#{class_name.underscore}_id") }
                class_name.constantize.all.select { |record| ids.include?(record.id) }
            else
                key = foreign_key || "#{self._class.constantize.name.underscore}_id"
                class_name.constantize.all.select do |record|
                    record.send(key) == self.id
                end
            end
        end
    end

    def self.belongs_to(association_name, class_name:, foreign_key: nil, optional: false)
        define_method(association_name) do
            key = foreign_key || "#{association_name}_id"
            id = self.send(key)
            return nil if optional && id.nil?
            class_name.constantize.all.find { |record| record.id == id }
        end

        JsonRecord::Record.define_method(association_name) do
            key = foreign_key || "#{association_name}_id"
            id = self.send(key)
            return nil if optional && id.nil?
            class_name.constantize.all.find { |record| record.id == id }
        end
    end

    
    def self.new(attributes = {})
        default_attributes = { 'id' => nil, 'created_at' => nil, 'updated_at' => nil, '_class' => self.name }
        attribute_accessors = self.attribute_accessors || []
        merged_attributes = attribute_accessors.each_with_object({}) { |key, hash| hash[key.to_s] = nil }
        normalized_attributes = attributes.transform_keys(&:to_s)
        Record.new(default_attributes.merge(merged_attributes).merge(normalized_attributes))
    end

    def self.create(attributes)
        attributes = { 'id' => next_id(all.map(&:to_h)), '_class' => self.name }.merge(attributes)
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

    def self.pluck(*attributes)
        self.all.map do |record|
            attributes.size == 1 ? record.send(attributes.first) : attributes.map { |attr| record.send(attr) }
        end
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

        # def update(attributes)
        #     binding.pry
        # end

        def update(attributes)
            attributes.each do |key, value|
            if @attributes.key?(key.to_s)
                @attributes[key.to_s] = value
            else
                raise NoMethodError, "undefined method `#{key}` for #{self.class.name}"
            end
            end
            @attributes['updated_at'] = Time.now.to_s

            data = JSON.parse(File.read(self._class.constantize.file_path)) rescue []
            record = data.find { |r| r['id'] == @attributes['id'] }
            return nil unless record

            record.merge!(@attributes)
            File.write(self._class.constantize.file_path, JSON.pretty_generate(data))
            self
        end

        def destroy
            # Remove dependent records if any associations have dependent: :destroy
            self._class.constantize.instance_methods(false).grep(/^destroy_/).each do |dependent_method|
                association_name = dependent_method.to_s.sub('destroy_', '')
                foreign_key = "#{self._class.constantize.name.underscore}_id"
                association_class = association_name.to_s.singularize.camelize.constantize
                dependent_records = association_class.all.select { |record| record.send(foreign_key) == self.id }
                dependent_records.each(&:destroy)
            end

            # Remove the record itself
            data = self._class.constantize.all.map(&:to_h)
            data.reject! { |record| record['id'] == @attributes['id'] }
            self._class.constantize.send(:save, data)
            File.write(self._class.constantize.file_path, JSON.pretty_generate(data))
            self
        end

        # def update(id, attributes)
        #     record = JsonRecord.find(id)
        #     return nil unless record
        #     record.update(attributes)
        # end

        # # Destroy the record by removing it from the JSON file
        # # It finds the record by id, removes it from the data array, and saves the updated data back to the file.
        # # Returns the destroyed record instance.
        # def destroy
        #     data = JsonRecord.all.map(&:to_h)
        #     data.reject! { |record| record['id'] == @attributes['id'] }
        #     JsonRecord.send(:save, data)
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
        #     new_record = JsonRecord.new(attributes)
        #     new_record.save
        #     new_record
        # end
        
        # def self.find(id)
        #     record = JsonRecord.find(id)
        #     return nil unless record
        #     new(record.to_h)
        # end

        # def self.where(conditions)
        #     JsonRecord.all.select do |record|
        #         conditions.all? { |key, value| record.send(key) == value }
        #     end.map(&:to_h).map { |attrs| new(attrs) }
        # end
        # def self.all
        #     JsonRecord.all.map(&:to_h).map { |attrs| new(attrs) }
        # end

        # def self.first
        #     record = JsonRecord.first
        #     return nil unless record
        #     new(record.to_h)
        # end

        # def self.last
        #     record = JsonRecord.last
        #     return nil unless record
        #     new(record.to_h)
        # end

        # def self.count
        #     JsonRecord.count
        # end
        # def self.destroy(id)
        #     record = JsonRecord.find(id)
        #     return nil unless record
        #     record.destroy
        # end

        # def self.destroy_all
        #     JsonRecord.destroy_all
        # end
        # def self.update_all(attributes)
        #     JsonRecord.update_all(attributes)
        # end

        # def self.reload(id)
        #     record = JsonRecord.find(id)
        #     return nil unless record
        #     new(record.to_h)
        # end

        # def self.save_all(records)  
        #     data = records.map(&:to_h)
        #     JsonRecord.send(:save, data)
        # end

        # def self.next_id
        #     JsonRecord.send(:next_id, JsonRecord.all.map(&:to_h))
        # end

        # def self.setup
        #     JsonRecord.send(:setup)
        # end

        # Save the record to the JSON file
        # If the record has an id, it updates the existing record
        # If the record does not have an id, it creates a new record

        def save
            if @attributes['id'].nil?
                # Create new record
                @attributes['id'] = self._class.constantize.send(:next_id, self._class.constantize.all.map(&:to_h))
                @attributes['created_at'] = Time.now.to_s
                @attributes['updated_at'] = Time.now.to_s
                data = self._class.constantize.all.map(&:to_h)
                data << @attributes
                self._class.constantize.send(:save, data)
            else
                # Update existing record
                @attributes['updated_at'] = Time.now.to_s
                data = self._class.constantize.all.map(&:to_h)
                record = data.find { |r| r['id'] == @attributes['id'] }
                record.merge!(@attributes)
                self._class.constantize.send(:save, data)
            end
            self
        end
    end
end
