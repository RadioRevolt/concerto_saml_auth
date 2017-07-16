Concerto SAML Auth
=====================

Authenticate Concerto users through your own [SAML](https://en.wikipedia.org/wiki/Security_Assertion_Markup_Language) deployment. 

Please note that this project is not affiliated with or endorsed by the Concerto Digital Signage project.

The aim of this project is to customize the Concerto CAS Auth plugin so it works with `omniauth-saml` instead of `omniauth-cas`.

Installing the plugin
----------------------

1. Log in using a system admin account in your Concerto deployment. You should have set up your Concerto installation already.
2. Click on the "plugins" button on the top navigation bar under the admin section.
3. On the right side of the page, click on the "new plugin" button.
4. With Ruby Gem selected as the source, write `concerto_saml_auth` as the Gem Name.
6. Since the SAML plugin is not configured yet, you can log back into your Concerto accounts by visiting the ```your.concerto.url/users/sign_in``` route, using
   any user that was not created through SAML login. Or continue using the user you're logged in as.
7. If the plugin was installed successfully, you will see a new "SAML User Authentication" settings tab under the "settings" page. This page can be found by clicking the "settings" button on the top navigation bar under the admin section.
8. Configure the plugin and restart the web server, as explained below.
9. Add your Service Provider's metadata to the Identity Provider. You can find your metadata at `your.concerto.url/auth/saml/metadata`.

Configuring the plugin
----------------------

**The details of how to configure this plugin are not finalized.**

1. Log in using a system admin account in your Concerto deployment
2. Click on the "settings" button on the top navigation bar under the admin section.
3. Click on the "SAML User Authentication" tab.
4. Configure the different values (see explanation below).
7. After saving these settings, you will need to restart your Concerto web server.
8. Your log in links at the top of the page should now point to your CAS authentication. 

Explanation of the configuration parameters:

**Saml Idp Metadata**: URL to the Identity Provider's metadata. For a simpleSAML installation, this could be `https://idp.example.com/simplesaml/saml2/idp/metadata.php`. All information about the Identity Provider is gathered through this.

**Saml Issuer**: Unique identification of this application, used by the Identity Provider to separate different Service Provider. It is normal to use an URL you control, so there is no chance of collision. Example: `https://concerto.example.com/saml2`.

The rest of the configuration items maps information received from the Identity Provider to fields in Concerto.

**Saml Uid Key**: Name of field containing user ID, used to map between users logging in and the local Concerto user they should log in as.

**Saml Email Key**: Name of field containing the user's email address.

**Saml First Name Key**: Name of field containing the user's first name.

**Saml Last Name Key**: Name of field containing the user's last name.

**Saml Member Of Key**: Name of fields containing the groups the user is a member of, as expressed by LDAP's memberOf field. You can leave this out to not synchronize groups.

**Saml Member Of Filter**: Comma-separated list of case-insensitive assertions. A group must match at least one of those assertions in order to be included in Concerto. You can use the common name to whitelist groups, like `CN=Administrators, CN=Graphics`.

**Saml Admin Groups**: Comma-separated case-insensitive list of groups whose members should be made admin when they log in through SAML.

note: This plugin is essentially a wrapper around [omniauth-saml](https://github.com/omniauth/omniauth-saml) with added logic for creating Concerto user accounts with the returned SAML information and synchronize privileges. Feel free to follow the omniauth-saml link and see a more detailed description of the configuration items. 

Known Issues
------------

* Localization is not a thing with this plugin. All error messages and changes made to interface are in English only.
* Somewhat specific: This plugin was made to fit the needs of Studentmediene i Trondheim AS. Some details of its operation may not be suitable for others.
