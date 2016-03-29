
Pod::Spec.new do |s|

  s.name         = "Injineer"
  s.version      = "1.0.1"
  s.summary      = "A dependency injection framework for Objective-C"
  s.description  = "Injineer is simpler than other DI frameworks for Objective-C but just as powerful. The framework introduces no dependencies in your code, so using it is almost completely transparent."
  s.homepage     = "https://github.com/vangelov/Injineer"
  s.license      = { :type => "ISC", :file => "LICENSE" }
  s.author             = { "Vladimir Angelov" => "vlady.angelov@gmail.com" }
  s.source       = { :git => "https://github.com/vangelov/Injineer.git", :tag => "1.0.1" }
  s.source_files  = "Injineer", "Injineer/**/*.{h,m}"
  s.requires_arc = true
  s.ios.deployment_target = "7.0"
  s.osx.deployment_target = "10.7"

end
