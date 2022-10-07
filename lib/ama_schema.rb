require "active_model"

module AmaSchema
  class Schema 
    include ActiveModel::Attributes

    def initialize(data)
      super()
      attribute_names.each do |name| 
        public_send("#{name}=", data.fetch(name.to_sym))
      end
    end

    def to_h 
      attributes.symbolize_keys
    end
  end

  module ClassMethods
    extend Forwardable
    def_delegators :schema, :attribute

    def schema
      @schema ||= Class.new(Schema)
    end
  end

  module Initializer 
    def initialize(event_id: SecureRandom.uuid, metadata: nil, data: {})
      by_schema = self.class.schema.new(data).to_h
      super(event_id:, metadata:, data: data.merge(by_schema))
    end
  end

  class OrderPlaced < RubyEventStore::Event 
    extend  ClassMethods 
    include Initializer

    attribute :order_id, :string
    attribute :placed_at, :date
    attribute :total_amount, :decimal
  end
end
