require 'test/unit'
require 'ruby-debug'
require 'active_record'
require 'active_record/test_case'
require 'active_record/fixtures'

ROOT = File.dirname(File.dirname(File.dirname(__FILE__)))

require "#{ROOT}/rails/init"

class ActiveSupport::TestCase
  include ActiveRecord::TestFixtures

  self.fixture_path = "#{ROOT}/test/fixtures"
  self.use_instantiated_fixtures  = false
  self.use_transactional_fixtures = true

  def create_fixtures(*table_names, &block)
    Fixtures.create_fixtures(ActiveSupport::TestCase.fixture_path, table_names, {}, &block)
  end
end

ActiveRecord::Base.configurations = {'test' => {'adapter' => "sqlite3", 'database' => ":memory:"}}
ActiveRecord::Base.establish_connection('test')
ActiveRecord::Base.connection.instance_eval do
  eval File.read("#{ROOT}/test/schema/schema.rb")
end
Dir["#{ROOT}/test/models/*.rb"].each{|path| require path}
