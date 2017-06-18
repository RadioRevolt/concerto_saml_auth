namespace :concerto_saml_auth do
  desc "Creates identities from existing user emails"
  task :identity_from_email => :environment do
    User.all.each do |u|
      identity = ConcertoIdentity::Identity.new(
        user_id: u.id,
        external_id: u.email[/[^@]+/],
        provider: "saml"
      )

      if identity.save
        puts "Created Identity: #{identity.external_id} -> #{identity.user_id}"
      else
        puts "Error creating Identity for User #{identity.user_id}"
      end
    end
  end
end
