Concerto SAML Auth
=====================

Authenticate Concerto users through your own [SAML](https://en.wikipedia.org/wiki/Security_Assertion_Markup_Language) deployment. 

Please note that this project is not affiliated with or endorsed by the Concerto Digital Signage project.

The aim of this project is to customize the Concerto CAS Auth plugin so it works with `omniauth-saml` instead of `omniauth-cas`.

Installing the plugin
----------------------

**This plugin is not yet available to install with the following method.**

1. Log in using a system admin account in your Concerto deployment
2. Click on the "plugins" button on the top navigation bar under the admin section.
3. On the right side of the page, click on the "new plugin" button.
4. With RubyGems selected as the source, add the gem concerto_saml_auth in the text field. 
5. Click save, you will now stop your Concerto web server, run the ```bundle``` command, and start your web server again.
6. Since the CAS plugin is not configured yet, you can log back into your Concerto accounts by visiting the ```your.concerto.url/users/sign_in``` route. 
7. If the plugin was installed successfully, you will see a new CAS User Authentication settings tab under the "settings" page. This page can be found by clicking the "settings" button on the top navigation bar under the admin section.

Configuring the plugin
----------------------

**The details of how to configure this plugin are not finalized.**

1. Log in using a system admin account in your Concerto deployment
2. Click on the "settings" button on the top navigation bar under the admin section.
3. Click on the "SAML User Authentication" tab.
4. Configure the SAML URL to point towards your SAML deployment. For example, https://saml-auth.rpi.edu/saml. 
5. The SAML uid key will be used as a unique identifier for each account. This will be returned by your SAML server upon authentication.
6. The SAML email key is required and will be used to access the email address returned by your SAML server upon authentication.
7. After saving these settings, you will need to restart your Concerto web server.
8. Your log in links at the top of the page should now point to your CAS authentication. 

note: This plugin is essentially a wrapper around [omniauth-saml](https://github.com/omniauth/omniauth-saml) with added logic for creating Concerto user accounts with the returned SAML information and synchronize privileges. Feel free to follow the omniauth-saml link and see a more detailed description of the configuration items. 
