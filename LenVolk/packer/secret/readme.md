## Folder's golden rule exclude vulnerability files in gitignore

- Create files in packer/secret directory
- File containing password are ignored by any git push

## Secret files

- secret_init.json : Terraform SPN

  - Content sample ==>

  ```json
  {
    "tenant_id": "xxxx-xxxxx-xxxx-xxxx",
    "subscription_id": "xxxx-xxxxx-xxxx-xxxx",
    "client_id": "xxxx-xxxxx-xxxx-xxxx",
    "client_secret": "xxxx-xxxxx-xxxx-xxxx"
  }
  ```

- secret_packer.json : Packer SPN authentication to Azure Portal

  - Content sample ==>

  ```json
  {
    "clientid": "xxxx-xxxxx-xxxx-xxxx",
    "clientsecret": "xxxx-xxxxx-xxxx-xxxx",
    "tenantid": "xxxx-xxxxx-xxxx-xxxx",
    "subid": "xxxx-xxxxx-xxxx-xxxx",
    "winrm_password": "xxxx-xxxxx-xxxx-xxxx"
  }
  ```
