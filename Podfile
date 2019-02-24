# Uncomment the next line to define a global platform for your project
platform :ios, '12.0'

target 'ReduxExampleCopy' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for ReduxExampleCopy
  pod 'SwiftLint'
  pod 'Alamofire'
  pod 'HTTPStatusCodes'
  pod 'GitHubAPI', :path => './iOS_architecture_samplecode/15/GitHubAPI', :version => '0.0.1'

  target 'API' do
    inherit! :search_paths
  end

  target 'ReduxExampleCopyTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'ReduxExampleCopyUITests' do
    inherit! :search_paths
    # Pods for testing
  end

end
