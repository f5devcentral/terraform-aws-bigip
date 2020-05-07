# copyright: 2018, The Authors

title "3-nic example tests"

require_controls 'inspec-bigip' do
  control 'bigip-connectivity'
  control 'bigip-declarative-onboarding'
  control 'bigip-declarative-onboarding-version'
  control 'bigip-application-services'
  control 'bigip-application-services-version'
  control 'bigip-telemetry-streaming'
  control 'bigip-telemetry-streaming-version'
  control 'bigip-licensed'
end