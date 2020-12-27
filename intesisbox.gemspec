require_relative "lib/intesis_box/version"

Gem::Specification.new do |s|
  s.name = 'intesisbox'
  s.version = IntesisBox::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ["Cody Cutrer"]
  s.email = "cody@cutrer.com'"
  s.homepage = "https://github.com/ccutrer/intesisbox"
  s.summary = "Library for communication with IntesisBox"
  s.license = "MIT"

  s.executables = ['intesisbox_mqtt_bridge']
  s.files = Dir["{bin,lib}/**/*"]

  s.add_dependency 'homie-mqtt', "~> 1.0.1"

  s.add_development_dependency 'byebug', "~> 9.0"
  s.add_development_dependency 'rake', "~> 13.0"
end
