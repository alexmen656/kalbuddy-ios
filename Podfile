require_relative '../../node_modules/@capacitor/ios/scripts/pods_helpers'

platform :ios, '16.0'
use_frameworks!

# workaround to avoid Xcode caching of Pods that requires
# Product -> Clean Build Folder after new Cordova plugins installed
# Requires CocoaPods 1.6 or newer
install! 'cocoapods', :disable_input_output_paths => true

def capacitor_pods
  pod 'Capacitor', :path => '../../node_modules/@capacitor/ios'
  pod 'CapacitorCordova', :path => '../../node_modules/@capacitor/ios'
  pod 'CapacitorCommunityInAppReview', :path => '../../node_modules/@capacitor-community/in-app-review'
  pod 'CapacitorMlkitBarcodeScanning', :path => '../../node_modules/@capacitor-mlkit/barcode-scanning'
  pod 'CapacitorCamera', :path => '../../node_modules/@capacitor/camera'
  pod 'CapacitorFilesystem', :path => '../../node_modules/@capacitor/filesystem'
  pod 'CapacitorLocalNotifications', :path => '../../node_modules/@capacitor/local-notifications'
  pod 'CapacitorPreferences', :path => '../../node_modules/@capacitor/preferences'
  pod 'CapacitorShare', :path => '../../node_modules/@capacitor/share'
  pod 'CapacitorSplashScreen', :path => '../../node_modules/@capacitor/splash-screen'
  pod 'CapacitorStatusBar', :path => '../../node_modules/@capacitor/status-bar'
  pod 'CapawesomeCapacitorTorch', :path => '../../node_modules/@capawesome/capacitor-torch'
  pod 'RevenuecatPurchasesCapacitor', :path => '../../node_modules/@revenuecat/purchases-capacitor'
  pod 'KaloriqBarcodeScanner', :path => '../../kaloriq-barcode-scanner'
  pod 'KaloriqHealthKit', :path => '../../kaloriq-health-kit'
end

target 'App' do
  capacitor_pods
  # Add your Pods here
end

post_install do |installer|
  assertDeploymentTarget(installer)

  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # Build for all architectures
      config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
      # Exclude arm64 architecture for the iOS simulator
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
    end
  end
end