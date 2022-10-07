require "ruby_event_store/profiler"
require "active_support"
require "active_support/notifications"
require "json"

require_relative "lib/no_schema"
require_relative "lib/dry_schema"
require_relative "lib/ama_schema"


instrumenter = ActiveSupport::Notifications
profiler = RubyEventStore::Profiler.new(instrumenter)

experiments = [
  ["no-schema", NoSchema::OrderPlaced],
  ["dry-struct", DrySchema::OrderPlaced],
  ["active-model-attributes", AmaSchema::OrderPlaced]
]

sample_data = {
  order_id: "dummy",
  placed_at: Time.now, 
  total_amount: BigDecimal("100.99")
}

count = 1000

mk_event_store = lambda do
  RubyEventStore::Client.new(
    mapper:
      RubyEventStore::Mappers::InstrumentedMapper.new(
        RubyEventStore::Mappers::Default.new,
        instrumenter
      ),
    repository:
      RubyEventStore::InstrumentedRepository.new(
        RubyEventStore::InMemoryRepository.new,
        instrumenter
      )
  )
end

def simulate_lossy_storage_transform(data)
  JSON.parse(JSON.dump(data), symbolize_names: true)
end

experiments.each do |name, event_klass|
  puts name
  puts
  event_store = mk_event_store.call
  event_store.append(count.times.map { event_klass.new(data: simulate_lossy_storage_transform(sample_data)) })
  profiler.measure do
    event_store.read.to_a
  end
  puts
  puts
end
