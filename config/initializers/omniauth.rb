require 'omniauth'
if ActiveRecord::Base.connection.table_exists? 'concerto_configs'
  # Concerto Configs are created if they don't exist already
  #   these are used to initialize and configure omniauth-cas
  # TODO: Finalize which settings are available
  ConcertoConfig.make_concerto_config("saml_idp_metadata", "https://example.com/auth/saml2/idp/metadata",
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

  ConcertoConfig.make_concerto_config("saml_admin_groups", "administrator group",
    :value_type => "string",
    :category => "SAML User Authentication",
    :seq_no => 9,
    :description => "Common name of groups, separated by comma, whose members should be granted administrator permission in Concerto")

  # Store omniauth config values from main application's ConcertoConfig
  idp_metadata_parser = OneLogin::RubySaml::Idp
  .new
  omniauth_config = idp_metadata_parser.parse_remote_to_hash(ConcertoConfig[:saml_idp_metadata])

  omniauth_config.merge(
    :issuer => ConcertoConfig[:saml_issuer],
    :uid_attribute => ConcertoConfig[:saml_uid_key],
    :attribute_statements => {
        :email => ConcertoConfig[:saml_email_key],
        :first_name => ConcertoConfig[:saml_first_name_key],
        :last_name => ConcertoConfig[:saml_last_name_key],
    },
    :member_of_key => ConcertoConfig[:saml_member_of_key],
    :admin_groups => ConcertoConfig[:saml_admin_groups]
    # :callback_url => "/auth/saml/callback"
  )

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
