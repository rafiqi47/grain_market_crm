puts "Seeding Super Admin..."

super_admin = User.find_or_initialize_by(email: "bilalahmedrafiqi@gmail.com")
super_admin.full_name = "Bilal Ahmed Rafiqi"
super_admin.password = "123QWE!@#"
super_admin.password_confirmation = "123QWE!@#" if super_admin.respond_to?(:password_confirmation)
super_admin.role = :super_admin
super_admin.save!

puts "Super Admin created/updated successfully!"

puts "Seeding Organization: Akbar Spry Scenter..."

organization = Organization.find_or_initialize_by(name: "Akbar Spry Scenter", urdu_name: "ماسٹر ایم اکبر کارپوریشن اینڈ سپرے سنٹر")
organization.name = "Master M. Akabr Corporation And Spry Center"
organization.save! if organization.new_record?

owner = organization.users.find_or_initialize_by(email: "faheemakbar1@gmail.com")
owner.full_name = "Faheem Akbar"
owner.phone = "03015705457"
owner.role = :owner
owner.password = "Faheem@319"
owner.password_confirmation = "Faheem@319" if owner.respond_to?(:password_confirmation)

if owner.new_record?
  begin
    owner.save!
    puts "Owner created: #{owner.email}"
  rescue Resend::Error => e
    puts "Owner record saved, but password-setup email failed to send: #{e.message}"
    puts "(This is expected until a verified sending domain is configured with Resend.)"
  end
else
  owner.save!
  puts "Owner already existed, updated: #{owner.email}"
end

puts "Organization + Owner seeding complete!"



organization = Organization.find_or_initialize_by(name: "Atif Spry Center", urdu_name: "عاطف سپرے سنٹر")
organization.save! if organization.new_record?

owner = organization.users.find_or_initialize_by(email: "atifwaseem2211@gmail.com")
owner.full_name = "Atif"
owner.phone = "03367927937"
owner.role = :owner
owner.password = "Atif@319"
owner.password_confirmation = "Atif@319" if owner.respond_to?(:password_confirmation)

if owner.new_record?
  begin
    owner.save!
    puts "Owner created: #{owner.email}"
  rescue Resend::Error => e
    puts "Owner record saved, but password-setup email failed to send: #{e.message}"
    puts "(This is expected until a verified sending domain is configured with Resend.)"
  end
else
  owner.save!
  puts "Owner already existed, updated: #{owner.email}"
end

puts "Organization + Owner seeding complete!"
