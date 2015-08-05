$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "elasticsearch_model/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "elasticsearch_model"
  s.version     = ElasticsearchModel::VERSION
  s.authors     = ["Fellipe Fingoli"]
  s.email       = ["ffingoli@atheva.com.br"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of ElasticsearchModel."
  s.description = "TODO: Description of ElasticsearchModel."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails","<= 3.2.0"

  s.add_dependency "elasticsearch"
end
