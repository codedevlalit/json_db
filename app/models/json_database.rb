require 'json'
require 'ostruct'
require 'active_support/core_ext/string'

class JsonDatabase

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
        JSON.parse(File.read(file_path)).map { |record| Record.new(record) } rescue []
    end

    def self.find(id)
        all.find { |record| record.id == id }
    end

    def self.find_by(attributes)
        all.find { |record| attributes.all? { |key, value| record.send(key) == value } }
    end

    def self.new(attributes = {})
        default_attributes = { 'id' => nil, 'created_at' => nil, 'updated_at' => nil }
        attribute_accessors = self.instance_variable_get(:@attribute_accessors) || []
        merged_attributes = attribute_accessors.each_with_object({}) { |key, hash| hash[key.to_s] = nil }
        Record.new(default_attributes.merge(merged_attributes).merge(attributes))
    end

    def self.create(attributes)
        data = all.map(&:to_h)
        timestamp = Time.now.to_s
        new_record = attributes.merge('id' => next_id(data), 'created_at' => timestamp, 'updated_at' => timestamp)
        data << new_record
        save(data)
        Record.new(new_record)
    end

    def self.update(id, attributes)
        data = all.map(&:to_h)
        record = data.find { |r| r['id'] == id }
        return unless record

        record.merge!(attributes.merge('updated_at' => Time.now.to_s))
        save(data)
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
        data = all.map(&:to_h).map { |record| record.merge(attributes).merge('updated_at' => timestamp) }
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

        def save
            if @attributes['id'].nil?
                # Create new record
                @attributes['id'] = JsonDatabase.send(:next_id, JsonDatabase.all.map(&:to_h))
                @attributes['created_at'] = Time.now.to_s
                @attributes['updated_at'] = Time.now.to_s
                data = JsonDatabase.all.map(&:to_h)
                data << @attributes
                JsonDatabase.send(:save, data)
            else
                # Update existing record
                @attributes['updated_at'] = Time.now.to_s
                data = JsonDatabase.all.map(&:to_h)
                record = data.find { |r| r['id'] == @attributes['id'] }
                record.merge!(@attributes)
                JsonDatabase.send(:save, data)
            end
            self
        end
    end
end
