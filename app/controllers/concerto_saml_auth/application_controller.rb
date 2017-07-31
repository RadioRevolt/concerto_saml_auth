module ConcertoSamlAuth
  class ApplicationController < ::ApplicationController

    # Used to map a user id with a corresponding authentication provider in the
    #   database (in this case it's SAML)
    require 'concerto_identity'

    # Find or create a new user based on values returned by the SAML callback
    def find_from_omniauth(saml_hash)
      # Get configuration options for customized SAML return value identifiers
      omniauth_config = ConcertoSamlAuth::Engine.config.omniauth_config
      uid = saml_hash[:uid]
      uid = uid.downcase

      # Check if an identity records exists for the user attempting to sign in
      if identity = ConcertoIdentity::Identity.find_by_external_id(uid)
        # Return the matching user record
        user_existed = true
        user = identity.user
      else
        # Add a new user via omniauth SAML details
        user_existed = false
        user = User.new
      end

      # Set user attributes

      # First name is required for user validation
      if !saml_hash[:info][:first_name].nil?
        user.first_name = saml_hash[:info][:first_name]
      else
        user.first_name = uid
      end

      if !saml_hash[:info][:last_name].nil?
        user.last_name = saml_hash[:info][:last_name]
      end

      # Email is required for user validation
      if saml_hash[:info][:email].nil?
        flash.notice = "No email was provided by the identity provider"
        return nil
      else
        user.email = saml_hash[:info][:email]
      end


      # Set user password and confirmation to random tokens
      user.password,user.password_confirmation=Devise.friendly_token

      # Attempt to save our new user
      if user.save
        # Saved

        if omniauth_config[:member_of_key].present?
          synchronize_group_membership(user, saml_hash, omniauth_config)
        end

        if omniauth_config[:admin_groups].present?
          synchronize_is_admin(user, saml_hash, omniauth_config)
        end

        user.save!

        if !user_existed
          # Create a matching identity to track our new user for future
          #   sessions and return our new user record
          ConcertoIdentity::Identity.create(provider: "saml",
                                            external_id: uid,
                                            user_id: user.id)
        end

        return {user: user, existed: user_existed}
      else
        # User save failed, an error occurred
        flash.notice = "Failed to sign in with SAML.
          #{user.errors.full_messages.to_sentence}."
        return nil
      end
    end

    def synchronize_group_membership(user, saml_hash, omniauth_config)
      desired_group_names = find_user_groups(saml_hash, omniauth_config)
      existing_group_memberships = Membership.where(user: user)
      existing_group_names = existing_group_memberships.map do |membership|
        membership.group.name
      end
      groups_to_add = desired_group_names - existing_group_names
      groups_to_remove = existing_group_names - desired_group_names
      add_user_to(groups_to_add, user)
      remove_user_from(groups_to_remove, user)
    end

    def find_user_groups(saml_hash, omniauth_config)
      member_of_mapping = create_member_of_mapping(omniauth_config[:member_of_mapping])
      Rails.logger.debug member_of_mapping

      common_names = find_cn_from_member_of(saml_hash, omniauth_config)

      # Apply the mapping
      concerto_groups = []
      member_of_mapping.each do |concerto_group_name, ldap_group_names|
        common_group_names = ldap_group_names & common_names
        if common_group_names
          # This user is a member of a group associated with this Concerto group.
          concerto_groups.push(concerto_group_name)
        end
      end
      concerto_groups
    end

    def find_cn_from_member_of(saml_hash, omniauth_config)
      member_of_key = omniauth_config[:member_of_key]

      member_of_lines = saml_hash[:extra][:response_object].attributes.multi(member_of_key)
      if member_of_lines.nil?
        Rails.logger.debug "No user groups found"
        return nil
      end
      # Go from array of "CN=Broadcast Engineer,OU=Commission,OU=Groups,DC=example,DC=com"
      # to array of ["CN=Broadcast Engineer", "OU=Commission", "OU=Groups", "DC=example", "DC=com"]
      groups_splitted = member_of_lines.map do |single_member_of_line|
        single_member_of_line.split(",")
      end
      # Downcase every string
      groups_splitted.map! do |single_splitted_group|
        single_splitted_group.map do |group_part|
          group_part.downcase
        end
      end
      Rails.logger.debug "Interpreting the memberOf field:"
      Rails.logger.debug groups_splitted
      # Go to array of {:cn => ["broadcast engineer"], :ou => ["commission", "groups"], :dc => ["example", "com"]}
      group_hashes = groups_splitted.map do |single_splitted_group|
        # Create a hash which returns new Arrays for missing entries
        resulting_group_hash = Hash.new{|h,k| h[k] = []}
        single_splitted_group.each do |single_group_attribute|
          key_and_value = single_group_attribute.split("=")
          key = key_and_value.first
          value = key_and_value.second
          resulting_group_hash[key].push(value)
        end
        resulting_group_hash
      end
      Rails.logger.debug group_hashes
      # Go to array of "broadcast engineer", but ensure all CNs are included
      common_names = []
      group_hashes.each do |single_group_hash|
        single_group_hash["cn"].each do |group_name|
          common_names.push(group_name)
        end
      end
      common_names
    end

    def create_member_of_mapping(member_of_mapping_str)
      member_of_mapping_str.strip!
      group_statements = member_of_mapping_str.split(';')
      group_statements.map! {|s| s.strip }
      mapping = {}
      group_statements.each do |statement|
        parts = statement.split('=')
        if parts.count <= 1
          return nil
        end
        concerto_group_name = parts[0]

        ldap_groups_str = parts[1]
        ldap_groups_str.downcase!
        ldap_group_names = ldap_groups_str.split(',')
        ldap_group_names.map! {|s| s.strip }

        mapping[concerto_group_name] = ldap_group_names
      end
      mapping
    end

    def add_user_to(all_groups, user)
      all_groups.each do |group_name|
        group = Group.where(:name => group_name).first_or_create!
        membership = Membership.create!(:user_id => user.id, :group_id => group.id, :level => Membership::LEVELS[:regular])
        membership.perms[:screen] = :all
        membership.perms[:feed] = :all
        membership.save!
      end
    end

    def remove_user_from(all_groups, user)
      all_groups.each do |group_name|
        group = Group.where(:name => group_name).first!
        Membership.where(:user_id => user.id, :group_id => group.id).destroy_all
      end
    end

    def synchronize_is_admin(user, saml_hash, omniauth_config)
      admin_group_string = omniauth_config[:admin_groups]
      admin_group_names = admin_group_string.split(",")
      admin_group_names.map! do |group|
        (group.strip).downcase
      end

      user_group_names = find_cn_from_member_of(saml_hash, omniauth_config)
      should_be_admin = admin_group_names & user_group_names
      user.is_admin = !should_be_admin.empty?
    end

  end
end
