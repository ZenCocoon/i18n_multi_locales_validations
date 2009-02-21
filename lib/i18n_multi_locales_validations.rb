module ActiveRecord
  class Errors
    def add_on_blank(attributes, custom_message = nil, locales = nil)
      locales = I18n.available_locales if locales == :all
      locales ||= []
      locales = [].push(locales) unless locales.kind_of?(Array)
      for attr in [attributes].flatten
        if locales.empty?
          value = @base.respond_to?(attr.to_s) ? @base.send(attr.to_s) : @base[attr.to_s]
          add(attr, :blank, :default => custom_message) if value.blank?
        else
          locales.each do |locale|
            value = @base.respond_to?(attr.to_s) ? @base.send(attr.to_s, locale) : @base[attr.to_s]
            add(attr, :blank, :default => custom_message) if value.blank?
          end
        end
      end
    end
  end
  
  module Validations
    module ClassMethods
      def validates_each(*attrs)
        options = attrs.extract_options!.symbolize_keys
        options[:locale] = I18n.available_locales if options[:locale] == :all
        options[:locale] ||= []
        options[:locale] = [].push(options[:locale]) unless options[:locale].kind_of?(Array) 
        attrs = attrs.flatten
       
        # Declare the validation.
        send(validation_method(options[:on] || :save), options) do |record|
          attrs.each do |attr|
            if options[:locale].empty?
              value = record.send(attr)
              next if (value.nil? && options[:allow_nil]) || (value.blank? && options[:allow_blank])
              yield record, attr, value
            else
              options[:locale].each do |locale|
                value = record.send(attr, locale)
                next if (value.nil? && options[:allow_nil]) || (value.blank? && options[:allow_blank])
                yield record, attr, value
              end
            end
          end
        end
      end

      def validates_presence_of(*attr_names)
        configuration = { :on => :save }
        configuration.update(attr_names.extract_options!)
       
        # can't use validates_each here, because it cannot cope with nonexistent attributes,
        # while errors.add_on_blank can
        send(validation_method(configuration[:on]), configuration) do |record|
          record.errors.add_on_blank(attr_names, configuration[:message], configuration[:locale])
        end
      end
    end
  end
end