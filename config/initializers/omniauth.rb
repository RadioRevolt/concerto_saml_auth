require 'omniauth'
if ActiveRecord::Base.connection.table_exists? 'concerto_configs'
  # Concerto Configs are created if they don't exist already
  #   these are used to initialize and configure omniauth-cas
  # TODO: Finalize which settings are available
  default_saml_idp_metadata = "https://example.com/auth/saml2/idp/metadata"
  ConcertoConfig.make_concerto_config("saml_idp_metadata", default_saml_idp_metadata,
    :value_type => "string",
    :category => "SAML User Authentication",
    :seq_no => 1,
    :description =>"URL at which the Identity Provider's metadata can be found.")

  ConcertoConfig.make_concerto_config("saml_issuer", "https://concerto.example.com/SAML2",
    :value_type => "string",
    :category => "SAML User Authentication",
    :seq_no => 2,
    :description => "A unique identifier used by this application to identify itself to the identity provider.")

  ConcertoConfig.make_concerto_config("saml_uid_key", "uid",
    :value_type => "string",
    :category => "SAML User Authentication",
    :seq_no => 3,
    :description => "SAML field name containing user login names")

  ConcertoConfig.make_concerto_config("saml_email_key", "email",
    :value_type => "string",
    :category => "SAML User Authentication",
    :seq_no => 4,
    :description => "SAML field name containing user email addresses. Leave blank if using email_suffix below")

  ConcertoConfig.make_concerto_config("saml_first_name_key", "first_name",
    :value_type => "string",
    :category => "SAML User Authentication",
    :seq_no => 6,
    :description => "SAML field name containing first name")

  ConcertoConfig.make_concerto_config("saml_last_name_key", "last_name",
    :value_type => "string",
    :category => "SAML User Authentication",
    :seq_no => 7,
    :description => "SAML field name containing last name")

  ConcertoConfig.make_concerto_config("saml_member_of_key", "memberOf",
    :value_type => "string",
    :category => "SAML User Authentication",
    :seq_no => 8,
    :description => "SAML field name containing the memberOf attribute, as retrieved from LDAP")

  ConcertoConfig.make_concerto_config("saml_member_of_filter", "OU=Access control",
    :value_type => "string",
    :category => "SAML User Authentication",
    :seq_no => 9,
    :description => "Filter determining which groups are made in Concerto. At least one of the assertions provided here, separated by comma, must match a memberOf field for it to be included.")

  ConcertoConfig.make_concerto_config("saml_admin_groups", "administrator group",
    :value_type => "string",
    :category => "SAML User Authentication",
    :seq_no => 10,
    :description => "Common name of groups, separated by comma, whose members should be granted administrator permission in Concerto")

  # Store omniauth config values from main application's ConcertoConfig
  saml_idp_metadata = ConcertoConfig[:saml_idp_metadata]
  if saml_idp_metadata.present? && saml_idp_metadata != default_saml_idp_metadata

    idp_metadata_parser = OneLogin::RubySaml::IdpMetadataParser.new
    begin
      omniauth_config = idp_metadata_parser.parse_remote_to_hash(saml_idp_metadata)
    rescue
      Rails.logger.error "Failed to fetch or parse IDP metadata. Error message: #{$!}"
      omniauth_config = {}
    end
  else
    omniauth_config = {}
    Rails.logger.warn "No URL (or default URL) defined for IDP metadata, SAML authentication will not be working."
  end

  request_attributes = []
  if ConcertoConfig[:saml_email_key].present?
    request_attributes.push({:name => ConcertoConfig[:saml_email_key], :friendly_name => "Email", :is_required => true})
  end
  if ConcertoConfig[:saml_first_name_key].present?
    request_attributes.push({:name => ConcertoConfig[:saml_first_name_key], :friendly_name => "First Name", :is_required => true})
  end
  if ConcertoConfig[:saml_last_name_key].present?
    request_attributes.push({:name => ConcertoConfig[:saml_last_name_key], :friendly_name => "Last Name", :is_required => true})
  end
  if ConcertoConfig[:saml_member_of_key].present?
    request_attributes.push({:name => ConcertoConfig[:saml_member_of_key], :friendly_name => "Member Of", :is_required => true})
  end

  request_attributes.map! do |attr|
    attr[:name_format] = "urn:oasis:names:tc:SAML:2.0:attrname-format:basic"
    attr
  end

  omniauth_config.merge!(
    :issuer => ConcertoConfig[:saml_issuer],
    :uid_attribute => ConcertoConfig[:saml_uid_key],
    :attribute_statements => {
        :email => [ConcertoConfig[:saml_email_key]],
        :first_name => [ConcertoConfig[:saml_first_name_key]],
        :last_name => [ConcertoConfig[:saml_last_name_key]],
    },
    :request_attributes => request_attributes,
    :member_of_key => ConcertoConfig[:saml_member_of_key],
    :member_of_filter => ConcertoConfig[:saml_member_of_filter],
    :admin_groups => ConcertoConfig[:saml_admin_groups],
    # :callback_url => "/auth/saml/callback"
  )

  Rails.logger.debug omniauth_config

  # configure omniauth-cas gem based on specified yml configs
  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :saml, omniauth_config
  end

  # save omniauth configuration for later use in application
  #  to reference any unique identifiers for extra CAS options
  ConcertoSamlAuth::Engine.configure do
     config.omniauth_config = omniauth_config
  end
end
