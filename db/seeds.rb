puts "Seeding Super Admin..."

super_admin = User.find_or_initialize_by(email: "bilalahmedrafiqi@gmail.com")
super_admin.full_name = "Bilal Ahmed Rafiqi"
super_admin.password = "123QWE!@#"
super_admin.password_confirmation = "123QWE!@#" if super_admin.respond_to?(:password_confirmation)
super_admin.role = :super_admin
super_admin.save!

puts "Super Admin created/updated successfully!"