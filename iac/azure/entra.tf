# Entra ID groups and the gateway's app registration (ADR-0002: identity is Entra ID;
# ADR-0003: virtual keys are mapped to Entra ID group entitlements). These three groups
# are illustrative consumer teams at Northgate Asset Management, standing in for the
# entitlement groups a real onboarding record would name.

data "azuread_client_config" "current" {}

resource "azuread_group" "research" {
  display_name     = "sg-panoptes-research"
  security_enabled = true
  description      = "Northgate research analysts entitled to call Panoptes for internal research summarisation."
}

resource "azuread_group" "client_reporting" {
  display_name     = "sg-panoptes-client-reporting"
  security_enabled = true
  description      = "Northgate client reporting team entitled to call Panoptes for client report drafting workloads."
}

resource "azuread_group" "platform" {
  display_name     = "sg-panoptes-platform"
  security_enabled = true
  description      = "Northgate AI Platform team administering the Panoptes control plane."
}

# The signed-in operator is the platform team, for now.
resource "azuread_group_member" "platform_current_user" {
  group_object_id  = azuread_group.platform.object_id
  member_object_id = data.azuread_client_config.current.object_id
}

# The app-role id must be a stable UUID, not regenerated on every plan; random_uuid
# only computes a new value if this resource is replaced.
resource "random_uuid" "gateway_consumer_role" {}

# This is the API the gateway validates tokens for. A consumer requests a token for
# api://panoptes-gateway and presents it to the gateway on every call; the gateway
# checks the token's group claims against the Entra groups above to decide entitlement.
resource "azuread_application" "gateway" {
  display_name     = "panoptes-gateway"
  identifier_uris  = ["api://panoptes-gateway"]
  sign_in_audience = "AzureADMyOrg"

  # Group membership shows up in the token as a claim, so the gateway can read
  # entitlement straight off it instead of calling back to Graph per request.
  group_membership_claims = ["SecurityGroup"]

  app_role {
    allowed_member_types = ["User", "Application"]
    description          = "Consumers entitled to call the Panoptes model gateway."
    display_name         = "Gateway Consumer"
    id                   = random_uuid.gateway_consumer_role.result
    value                = "Gateway.Consumer"
  }
}

resource "azuread_service_principal" "gateway" {
  client_id = azuread_application.gateway.client_id
}
