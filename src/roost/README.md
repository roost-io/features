# Roost Cluster Creation

A feature to launch kubernetes cluster from Codespace using Roost.

## Example Usage

```json
"features": {
    "ghcr.io/roost-io/features/roost:1.0.0": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| roost_auth_token | Roost Authorization Token | string | - |
| email | User email address | string | - |
| alias | Alias name for cluster | string | - |
| k8s_version | Kubernetes version | string | 1.22.2 |
| cluster_expires_in_hours | Cluster expiry in Hrs | string | 1 |
| num_workers | Number of worker nodes | string | 1 |
| namespace | Default namespace | string | roost-codesapace |
| region | Aws region, to create cluster into | string | ap-northeast-1 |
| disk_size | Disk size in GB | string | 30 |
| instance_type | Instance type | string | t3.small |
| ami | AMI | string | ubuntu focal 20.04 |
| ent_server | Enterprise server IP | string | app.roost.ai |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/roost-io/features/blob/main/src/roost/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
