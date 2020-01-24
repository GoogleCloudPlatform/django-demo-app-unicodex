# Generates singleton ACL items for berglas secrets and access control
# https://github.com/hashicorp/terraform-plugin-sdk/issues/174

value = """
#
# Defining secret "{0}"
resource berglas_secret {0} (
  bucket    = var.berglas_bucket
  key       = local.berglas_key
  name      = "{0}"
  plaintext = local.berglas_secrets_list.{0}
)
"""

acl = """
resource google_storage_object_access_control {0}_{1} (
  bucket = var.berglas_bucket
  object = berglas_secret.{0}.name
  role = "READER"
  entity = "user-$(local.{1})"

  depends_on = [{2}]
)
"""

def parse(s):
    return s.replace("(","{").replace(")","}")

for key in ["superuser","media_bucket", "superpass", "database_url",
        "secret_key"]:
    print(parse(value.format(key)))
    prev = ["berglas_secret.{0}".format(key)]
    for email in ["sa_email","sa_cb_email"]:
        print(parse(acl.format(key,email, ", ".join(prev))))
        prev.append("google_storage_object_access_control.{0}_{1}".format(key, email))

