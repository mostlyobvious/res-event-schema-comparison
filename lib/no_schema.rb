require "ruby_event_store"

module NoSchema
  OrderPlaced = Class.new(RubyEventStore::Event)
end
