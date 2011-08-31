module InverseOf
  class InverseOfAssociationNotFoundError < ActiveRecord::ActiveRecordError #:nodoc:
    def initialize(reflection, associated_class = nil)
      super("Could not find the inverse association for #{reflection.name} (#{reflection.options[:inverse_of].inspect} in #{associated_class.nil? ? reflection.class_name : associated_class.name})")
    end
  end

  module Reflection
    def self.included(base)
      base::AssociationReflection.send :include, AssociationReflection
      base::ThroughReflection.send :include, ThroughReflection
    end

    module AssociationReflection
      def self.included(base)
        base.alias_method_chain :check_validity!, :inverse_of
      end

      def check_validity_with_inverse_of!
        check_validity_of_inverse!
        check_validity_without_inverse_of!
      end

      def check_validity_of_inverse!
        unless options[:polymorphic]
          if has_inverse? && inverse_of.nil?
            raise InverseOfAssociationNotFoundError.new(self)
          end
        end
      end

      def has_inverse?
        !@options[:inverse_of].nil?
      end

      def inverse_of
        if has_inverse?
          @inverse_of ||= klass.reflect_on_association(options[:inverse_of])
        end
      end

      def polymorphic_inverse_of(associated_class)
        if has_inverse?
          if inverse_relationship = associated_class.reflect_on_association(options[:inverse_of])
            inverse_relationship
          else
            raise InverseOfAssociationNotFoundError.new(self, associated_class)
          end
        end
      end
    end

    module ThroughReflection
      def self.included(base)
        base.alias_method_chain :check_validity!, :inverse_of
      end

      def check_validity_with_inverse_of!
        check_validity_of_inverse!
        check_validity_without_inverse_of!
      end
    end
  end

  module Associations
    module AssociationCollection
      def self.included(base)
        base.alias_method_chain :find_target, :inverse_of
        base.alias_method_chain :add_record_to_target_with_callbacks, :inverse_of
      end

      def find_target_with_inverse_of
        records = find_target_without_inverse_of
        records.each do |record|
          set_inverse_instance(record, @owner)
        end
        records
      end

      def add_record_to_target_with_callbacks_with_inverse_of(record, &block)
        record = add_record_to_target_with_callbacks_without_inverse_of(record, &block)
        set_inverse_instance(record, @owner)
        record
      end
    end

    module AssociationProxy
      def self.included(base)
        base.alias_method_chain :initialize, :inverse_of
      end

      def initialize_with_inverse_of(owner, reflection)
        reflection.check_validity!
        initialize_without_inverse_of(owner, reflection)
      end

      private

      def set_inverse_instance(record, instance)
        return if record.nil? || !we_can_set_the_inverse_on_this?(record)
        inverse_relationship = @reflection.inverse_of
        unless inverse_relationship.nil?
          record.send(:"set_#{inverse_relationship.name}_target", instance)
        end
      end

      # Override in subclasses
      def we_can_set_the_inverse_on_this?(record)
        false
      end
    end

    module BelongsToAssociation
      def self.included(base)
        base.alias_method_chain :replace, :inverse_of
        base.alias_method_chain :find_target, :inverse_of
      end

      def replace_with_inverse_of(record)
        replace_without_inverse_of(record)
        set_inverse_instance(record, @owner)
        record
      end

      def find_target_with_inverse_of
        target = find_target_without_inverse_of and
          set_inverse_instance(target, @owner)
        target
      end

      # NOTE - for now, we're only supporting inverse setting from belongs_to back onto
      # has_one associations.
      def we_can_set_the_inverse_on_this?(record)
        @reflection.has_inverse? && @reflection.inverse_of.macro == :has_one
      end
    end

    module BelongsToPolymorphicAssociation
      def self.included(base)
        base.alias_method_chain :replace, :inverse_of
        base.alias_method_chain :find_target, :inverse_of
      end

      def replace_with_inverse_of(record)
        replace_without_inverse_of(record)
        set_inverse_instance(record, @owner)
        record
      end

      def find_target_with_inverse_of
        target = find_target_without_inverse_of
        set_inverse_instance(target, @owner)
        target
      end

      # NOTE - for now, we're only supporting inverse setting from belongs_to back onto
      # has_one associations.
      def we_can_set_the_inverse_on_this?(record)
        if @reflection.has_inverse?
          inverse_association = @reflection.polymorphic_inverse_of(record.class)
          inverse_association && inverse_association.macro == :has_one
        else
          false
        end
      end

      def set_inverse_instance(record, instance)
        return if record.nil? || !we_can_set_the_inverse_on_this?(record)
        inverse_relationship = @reflection.polymorphic_inverse_of(record.class)
        unless inverse_relationship.nil?
          record.send(:"set_#{inverse_relationship.name}_target", instance)
        end
      end
    end

    module HasManyAssociation
      def we_can_set_the_inverse_on_this?(record)
        inverse = @reflection.inverse_of
        return !inverse.nil?
      end
    end

    module HasManyThroughAssociation
      def initialize(owner, reflection)
        super
      end

      # NOTE - not sure that we can actually cope with inverses here
      def we_can_set_the_inverse_on_this?(record)
        false
      end
    end

    module HasOneAssociation
      def self.included(base)
        base.alias_method_chain :find_target, :inverse_of
        base.alias_method_chain :new_record, :inverse_of
        base.alias_method_chain :replace, :inverse_of
      end

      def find_target_with_inverse_of
        target = find_target_without_inverse_of
        set_inverse_instance(target, @owner)
        target
      end

      def replace_with_inverse_of(record, dont_save = false)
        value = replace_without_inverse_of(record, dont_save)
        set_inverse_instance(record, @owner)
        value
      end

      private

      def new_record_with_inverse_of(replace_existing, &block)
        record = new_record_without_inverse_of(replace_existing, &block)
        set_inverse_instance(record, @owner) unless replace_existing
        record
      end

      def we_can_set_the_inverse_on_this?(record)
        inverse = @reflection.inverse_of
        return !inverse.nil?
      end
    end

    module ClassMethods
      module JoinDependency
        def self.included(base)
          base.alias_method_chain :construct_association, :inverse_of
        end

        def construct_association_with_inverse_of(record, join, row)
          association = construct_association_without_inverse_of(record, join, row) or
            return nil
          association_proxy = record.send(join.reflection.name)
          association_proxy.__send__(:set_inverse_instance, association, record)
          return association
        end
      end
    end
  end

  module AssociationPreload
    def self.included(base)
      base.extend ClassMethods
      base.metaclass.alias_method_chain :add_preloaded_records_to_collection, :inverse_of
      base.metaclass.alias_method_chain :set_association_single_records, :inverse_of
    end

    module ClassMethods
      def add_preloaded_records_to_collection_with_inverse_of(parent_records, reflection_name, associated_record)
        value = add_preloaded_records_to_collection_without_inverse_of(parent_records, reflection_name, associated_record)
        parent_records.each do |parent_record|
          association_proxy = parent_record.send(reflection_name)
          association_proxy.__send__(:set_inverse_instance, associated_record, parent_record)
        end
        value
      end

      def set_association_single_records_with_inverse_of(id_to_record_map, reflection_name, associated_records, key)
        value = set_association_single_records_without_inverse_of(id_to_record_map, reflection_name, associated_records, key)
        associated_records.each do |associated_record|
          mapped_records = id_to_record_map[associated_record[key].to_s]
          mapped_records.each do |mapped_record|
            association_proxy = mapped_record.send(reflection_name)
            association_proxy.__send__(:set_inverse_instance, associated_record, mapped_record)
          end
        end
        value
      end
    end
  end
end

ActiveRecord::InverseOfAssociationNotFoundError = InverseOf::InverseOfAssociationNotFoundError
ActiveRecord::Associations::AssociationCollection.send :include, InverseOf::Associations::AssociationCollection
ActiveRecord::Associations::AssociationProxy.send :include, InverseOf::Associations::AssociationProxy
ActiveRecord::Associations::BelongsToAssociation.send :include, InverseOf::Associations::BelongsToAssociation
ActiveRecord::Associations::BelongsToPolymorphicAssociation.send :include, InverseOf::Associations::BelongsToPolymorphicAssociation
ActiveRecord::Associations::HasManyAssociation.send :include, InverseOf::Associations::HasManyAssociation
ActiveRecord::Associations::HasManyThroughAssociation.send :include, InverseOf::Associations::HasManyThroughAssociation
ActiveRecord::Associations::HasOneAssociation.send :include, InverseOf::Associations::HasOneAssociation
ActiveRecord::Associations::ClassMethods::JoinDependency.send :include, InverseOf::Associations::ClassMethods::JoinDependency
ActiveRecord::Reflection.send :include, InverseOf::Reflection
ActiveRecord::Base.send :include, InverseOf::AssociationPreload

module ActiveRecord::Associations::ClassMethods
  @@valid_keys_for_has_many_association << :inverse_of
  @@valid_keys_for_has_one_association << :inverse_of
  @@valid_keys_for_belongs_to_association << :inverse_of
end
