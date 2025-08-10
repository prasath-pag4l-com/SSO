




resource "random_uuid" "Adobe_Creative_Cloud_SSO_id" {}
resource "random_uuid" "Adobe_Creative_Cloud_SSO_id2" {}
resource "random_uuid" "Adobe_Creative_Cloud_SSO_id3" {}

resource "azuread_group" "SSO_Adobe_Creative_Cloud" {
	display_name     = "SSO_Adobe_Creative_Cloud"
	owners = [for user in data.azuread_user.owners : user.object_id]
	security_enabled = true
}

resource "azuread_application" "Adobe_Creative_Cloud_SSO" {
  display_name    = "Adobe_Creative_Cloud"
    identifier_uris = ["https://federatedid-na1.services.adobe.com/federated/saml/metadata/alias/8a4aba31-d975-4a21-a2f3-a2efcb769a58"]
  api {
    known_client_applications      = []
    mapped_claims_enabled          = false
    requested_access_token_version = 1
	
	    oauth2_permission_scope {
        admin_consent_description  = "Allow the application to access Adobe_Creative_Cloud_SSO on behalf of the signed-in user."
        admin_consent_display_name = "Access Adobe_Creative_Cloud_SSO"
        enabled                    = true
        id                         = random_uuid.Adobe_Creative_Cloud_SSO_id.result
        type                       = "User"
        user_consent_description   = "Allow the application to access Adobe_Creative_Cloud_SSO on your behalf."
        user_consent_display_name  = "Access Adobe_Creative_Cloud_SSO"
        value                      = "user_impersonation"
            }
        }
        logo_image         = filebase64("${path.module}/Adobe_Creative_Cloud.png")
  		app_role {
			allowed_member_types = ["User"]
			description          = "User"
			display_name         = "User"
			enabled              = true
			id                   = random_uuid.Adobe_Creative_Cloud_SSO_id2.result
		}
		app_role {
			allowed_member_types = ["User"]
			description          = "msiam_access"
			display_name         = "msiam_access"
			enabled              = true
			id                   = random_uuid.Adobe_Creative_Cloud_SSO_id3.result
		}
  web {
    redirect_uris = ["https://federatedid-na1.services.adobe.com/federated/saml/SSO/alias/8a4aba31-d975-4a21-a2f3-a2efcb769a58"]

    implicit_grant {
		access_token_issuance_enabled = false
		id_token_issuance_enabled     = true
	}
  }
}

resource "azuread_service_principal" "Adobe_Creative_Cloud_Enterprise" {
  client_id                    = azuread_application.Adobe_Creative_Cloud_SSO.client_id
  app_role_assignment_required = true
  notification_email_addresses = ["ctct-sysadminit@constantcontact.com"]
  preferred_single_sign_on_mode = "saml"
  tags = ["WindowsAzureActiveDirectoryCustomSingleSignOnApplication","WindowsAzureActiveDirectoryIntegratedApp"]
  login_url = "https://federatedid-na1.services.adobe.com/federated/saml/SSO/alias/8a4aba31-d975-4a21-a2f3-a2efcb769a58"
}

resource "azuread_app_role_assignment" "Adobe_Creative_Cloud_user_assignment" {
  principal_object_id = azuread_group.SSO_Adobe_Creative_Cloud.object_id
  app_role_id         = random_uuid.Adobe_Creative_Cloud_SSO_id2.result
  resource_object_id  = azuread_service_principal.Adobe_Creative_Cloud_Enterprise.object_id
}

resource "azuread_service_principal_token_signing_certificate" "Adobe_Creative_Cloud_Enterprise_Cert" {
  service_principal_id = azuread_service_principal.Adobe_Creative_Cloud_Enterprise.id
}

output "Adobe_Creative_Cloud_saml_metadata_url" {

  value = "https://login.microsoftonline.com/102895b1-70e4-43d8-8c36-de1779847932/federationmetadata/2007-06/federationmetadata.xml?appid=${azuread_application.Adobe_Creative_Cloud_SSO.client_id}"
}

resource "azuread_claims_mapping_policy" "Adobe_Creative_Cloud_policy" { 
 definition = [
  jsonencode(
  {
   ClaimsMappingPolicy = {
    ClaimsSchema = [
     {
       ID = "mail"
       JwtClaimType = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier"
       SamlClaimType = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier"
       Source = "user"
     },
     {
       ID = "mail"
       JwtClaimType = "email"
       SamlClaimType = "email"
       Source = "user"
     },
     {
       ID = "fname"
       JwtClaimType = "FirstName"
       SamlClaimType = "FirstName"
       Source = "user"
     },
     {
       ID = "lname"
       JwtClaimType = "LastName"
       SamlClaimType = "LastName"
       Source = "user"
     },
    ]
    IncludeBasicClaimSet = "false"
    Version              = 1
   }
  }
 ),
 ]
display_name = "Adobe_Creative_Cloud_policy"
}
resource "azuread_service_principal_claims_mapping_policy_assignment" "Adobe_Creative_Cloud_Enterprise" {
  claims_mapping_policy_id = azuread_claims_mapping_policy.Adobe_Creative_Cloud_policy.id
  service_principal_id     = azuread_service_principal.Adobe_Creative_Cloud_Enterprise.id
}

