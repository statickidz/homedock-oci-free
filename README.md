# HomeDock on Oracle Cloud Infrastructure (OCI) Free Tier

![HomeDock Logo](doc/homedock-logo.png)

Deploy **HomeDock** - an open-source deployment platform - on Oracle Cloud Infrastructure using the Free Tier. This Terraform project sets up a complete HomeDock environment with proper networking and security configurations.

[![Deploy to Oracle Cloud](https://oci-resourcemanager-plugin.plugins.oci.oraclecloud.com/latest/deploy-to-oracle-cloud.svg)](https://cloud.oracle.com/resourcemanager/stacks/create?zipUrl=https://github.com/statickidz/homedock-oci-free/archive/refs/heads/main.zip)

## 🚀 Quick Start

1. **Click "Deploy to Oracle Cloud"** above
2. **Configure your deployment** with the required parameters
3. **Wait 5-10 minutes** for HomeDock to install
4. **Access your HomeDock dashboard** using the provided URL and credentials

![HomeDock Screenshot](doc/homedock-screenshot.webp)

## 📋 Prerequisites

Before deploying, ensure you have:

- ✅ **OCI Account**: An Oracle Cloud Infrastructure account with Free Tier access
- ✅ **SSH Key Pair**: Generate an SSH key pair for secure instance access
- ✅ **Compartment ID**: Your OCI compartment identifier
- ✅ **Ubuntu Image ID**: Ubuntu 22.04 image OCID for your region

## 🏗️ What Gets Deployed

This Terraform configuration creates:

- **1 HomeDock Instance**: VM.Standard.A1.Flex with 24GB RAM and 4 OCPUs
- **Virtual Cloud Network (VCN)**: Complete networking infrastructure
- **Security Lists**: Configured for HomeDock access
- **Internet Gateway**: For external connectivity
- **Subnet**: Properly configured for the HomeDock instance

## ⚙️ Configuration Parameters

When deploying, you'll need to provide:

| Parameter                  | Description             | Example                                   |
| -------------------------- | ----------------------- | ----------------------------------------- |
| `ssh_authorized_keys`      | Your SSH public key     | `ssh-rsa AAEAAAA...3R ssh-key-2024-09-03` |
| `compartment_id`           | OCI compartment OCID    | `ocid1.compartment.oc1..aaaa...`          |
| `source_image_id`          | Ubuntu 22.04 image OCID | `ocid1.image.oc1.eu-frankfurt-1...`       |
| `availability_domain_main` | Availability domain     | `WBJv:EU-FRANKFURT-1-AD-1`                |

### Finding Your Values

#### SSH Public Key

```bash
# Generate a new key pair
ssh-keygen -t rsa -b 4096 -C "your-email@example.com"

# Display your public key
cat ~/.ssh/id_rsa.pub
```

#### Compartment ID

1. Go to [OCI Console](https://cloud.oracle.com)
2. Navigate to **Profile** → **Tenancy: [your-username]**
3. Click **Tenancy Information**
4. Copy the **OCID** value

#### Ubuntu Image ID

1. Visit [Oracle Linux Images](https://docs.oracle.com/en-us/iaas/images/image/128dbc42-65a9-4ed0-a2db-be7aa584c726/index.htm)
2. Find Ubuntu 22.04 for your region
3. Copy the **OCID** value

#### Availability Domain

1. In OCI Console, go to **Core Infrastructure** → **Compute** → **Instances**
2. Click **Create Instance**
3. Note the availability domain from the dropdown (e.g., `WBJv:EU-FRANKFURT-1-AD-1`)

## 🔧 Post-Deployment Setup

### 1. Access HomeDock Dashboard

After deployment completes (5-10 minutes), you'll receive:

- **Dashboard URL**: `http://[YOUR_INSTANCE_IP]`
- **Default Credentials**:
  - Username: `user`
  - Password: `passwd`

**⚠️ Important**: Change the default password immediately after first login!

### 2. Deploy your first app

1. From the HomeDock dashboard, click "App Store"
2. Choose from the app catalog
3. Click "Install" and wait for the installation
4. Access your app

## 📚 HomeDock Documentation

For detailed HomeDock usage instructions:

- **Official Website**: [homedock.cloud](https://www.homedock.cloud/)
- **Documentation**: [docs.homedock.cloud](https://docs.homedock.cloud/)
- **GitHub**: [github.com/BansheeTech/HomeDockOS](https://github.com/BansheeTech/HomeDockOS)

## 🔍 Troubleshooting

### Common Issues

**"Out of Capacity" Error**

- Free Tier instances have limited availability
- Solution: Upgrade to a paid account (keeps free tier benefits)

**HomeDock Not Accessible**

- Wait 5-10 minutes for installation to complete
- Check instance status in OCI Console
- Verify security list allows HTTP traffic

**SSH Connection Issues**

- Ensure your SSH key is correctly added
- Use `root` as the username
- Check instance is running and has public IP

### Logs & Debugging

SSH into your instance to check logs:

```bash
ssh root@[YOUR_INSTANCE_IP]
tail -f /var/log/homedock-install.log
```

## 🏗️ Project Structure

```
homedock-oci-free/
├── bin/
│   └── homedock-main.sh          # HomeDock installation script
├── doc/
│   ├── homedock-logo.webp        # HomeDock logo
│   └── homedock-screenshot.png   # Dashboard screenshot
├── main.tf                       # Main instance configuration
├── network.tf                    # VCN, subnet, security configuration
├── variables.tf                  # Input variables
├── locals.tf                     # Local values and configurations
├── output.tf                     # Output values (URLs, credentials)
├── providers.tf                  # OCI provider configuration
├── helper.tf                     # Helper resources
└── README.md                     # This file
```

## 💰 OCI Free Tier Limits

This deployment uses:

- **VM.Standard.A1.Flex**: 24GB RAM, 4 OCPUs
- **Storage**: Included with instance
- **Networking**: VCN, subnet, internet gateway

**Note**: Free Tier resources are subject to availability. Consider upgrading to a paid account for production use.

## 🤝 Contributing

Found an issue or have a suggestion? Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

---

**Happy Deploying! 🚀**

For support, visit [homedock.cloud](https://www.homedock.cloud/) or join the [HomeDock community](https://github.com/BansheeTech/HomeDockOS).
