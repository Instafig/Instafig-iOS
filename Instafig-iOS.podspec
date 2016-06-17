Pod::Spec.new do |s|

  s.name         = "Instafig-iOS"
  s.version      = "0.0.4"
  s.summary      = "iOS SDK for Instafig"

  s.description  = <<-DESC
                    Instafig is kind of IOS SDK whitch can slect available server host and recieve configuration.
                   DESC

  s.homepage     = "https://github.com/Instafig/Instafig-iOS"

  s.license      = "MIT"

  s.author             = { "Instafig" => "shihengying901@gmail.com" }

  s.platform     = :ios, "7.0"

  s.source       = { :git => "https://github.com/Instafig/Instafig-iOS.git", :tag => "0.0.4" }

  s.source_files  = "InstafigSDK", "InstafigSDK/**/*.{h,m}"
  s.exclude_files = "Classes/Exclude"
  s.requires_arc = true
end
