#!/usr/bin/python
#
# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import google.auth

from google.cloud import secretmanager_v1beta1 as sm

"""
For a list of secret values, return a dictionary of keys and values from Secret
Manager (if such a service exists in the current context)
"""


def access_secrets(secret_keys):
    secrets = {}
    _, project = google.auth.default()

    if project:
        client = sm.SecretManagerServiceClient()

        for s in secret_keys:
            path = client.secret_version_path(project, s, "latest")
            payload = client.access_secret_version(path).payload.data.decode("UTF-8")
            secrets[s] = payload

    return secrets
