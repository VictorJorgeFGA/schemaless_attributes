$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "schemaless_attributes/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = "schemaless_attributes"
  spec.version     = SchemalessAttributes::VERSION
  spec.authors     = ["VictorJorgeFGA"]
  spec.email       = ["victor.eng.unb@gmail.com"]
  spec.homepage    = "https://github.com/VictorJorgeFGA/schemaless_attributes"
  spec.summary     = "\"Schemaless Attributes\" gem for Rails: Dynamically store model attributes in the database " \
                     "without rigid schema constraints using Active Storage attachments or JSONB fields."
  spec.description = "Empower your Rails application with \"Schemaless Attributes\", a gem that facilitates flexible " \
                     "storage of model attributes without predefined schema constraints. Seamlessly integrate with " \
                     "Active Storage attachments or opt for JSONB fields to manage dynamic attribute storage " \
                     "effortlessly. Simplify your database schema handling and embrace adaptability."
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", "~> 6.0.6", ">= 6.0.6.1"

  spec.add_development_dependency "sqlite3", "~> 1.4"
end
