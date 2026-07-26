Rails.application.configure do
  MissionControl::Jobs.http_basic_auth_user = "super_admin"
  MissionControl::Jobs.http_basic_auth_password = "123QWE!@#"
end