# Single source of truth shared by the NixOS / nix-darwin / home-manager
# configurations and by the OpenTofu infrastructure (values land in tofu via
# the auto-loaded terraform.tfvars.json, regenerated with `nix run .#tofu-vars`).
{
  domain = "egrecho47.top";

  entra = {
    customDomain = "mse.egrecho47.top";
  };

  subdomains = {
    substore = "sub";
    azure = "azure";
    navidrome = "navi";
  };

  # Default NixOS state version. Hosts with a legacy value override this.
  stateVersion = "26.05";

  # Human identities. `home` carries the per-platform home directory.
  identity = {
    # Username granted sudo/admin access on managed NixOS hosts.
    adminUser = "luyan";

    users = {
      luyan = {
        fullName = "Luyan Zhou";
        email = "78394824+BlueQuantumx@users.noreply.github.com";
        signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINUPT6A9p1/DKyY0cvq2li9ytDDXEy2tr+1p1Q5R0XUF";
        home = {
          darwin = "/Users/luyan";
          linux = "/home/luyan";
        };
      };
    };
  };

  # Per-host registry, keyed by flake attribute name.
  #   hostname    - networking.hostName; null leaves it unset
  #   role        - free-form classification
  #   isRemote    - drives the VSCode remote (nix-ld) workaround
  #   adminKeys   - public keys allowed to log in as the admin user and root
  hosts = {
    azure = {
      hostname = "azure-nixos";
      role = "cloud-gateway";
      isRemote = false;
      adminKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG2BSb/TfSm+wIkr9Fu5pYjWP7wxf1F/vXnR0DcnTATi"
      ];
    };

    pascal-cloud-01 = {
      hostname = "pascal-cloud-01";
      role = "cloud-server";
      isRemote = false;
      adminKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA1Xuo9wlQL1lD9Bd2+XHe8U4MPfrmVucxzIu0VWjA77 luyan@bogon"
      ];
    };

    raspi = {
      hostname = "louis-raspi";
      role = "home-server";
      isRemote = true;
      adminKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIzJWcosx9QtM2tCiDzI3an5CLQZRPnhSOfaAxwnhtms luyan@Louis-MacBook-Pro.local"
      ];
    };

    digitalocean = {
      hostname = null;
      role = "cloud-server";
      isRemote = false;
      adminKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBre+3gxDeMI2dVeQetakBibFd54rLanEDrGLdLJM+AT luyan@Louis-MacBook-Pro-2024.local"
      ];
    };

    orbstack = {
      hostname = "nixos";
      role = "dev-container";
      isRemote = false;
      adminKeys = [ ];
    };

    macbook = {
      hostname = null;
      role = "workstation";
      isRemote = false;
      adminKeys = [ ];
    };

    "529-2" = {
      hostname = "529-2";
      role = "desktop";
      isRemote = false;
      # TODO(529-2): 填入允许登录 admin 用户与 root 的 SSH 公钥。
      adminKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA1Xuo9wlQL1lD9Bd2+XHe8U4MPfrmVucxzIu0VWjA77 luyan@bogon"
      ];
    };
  };

  azure = {
    namePrefix = "nixos-azure";
    location = "eastasia";
    vmSize = "Standard_B2ats_v2";
    adminUsername = "luyan";
    sshPublicKeyFile = "~/.ssh/azure.pub";
    sshPrivateKeyFile = "~/.ssh/azure";
    # Increment to rotate to a new static public IP (-> tofu terraform.tfvars.json).
    publicIpRevision = 1;
  };

  # EasyTier mesh, retained as an optional fallback. Disabled by default;
  # `tailnet` (Tailscale) is the active mesh. Flip `enable` to bring back the
  # EasyTier services, its sops secret and its NSG rules as a unit.
  easytier = {
    enable = false;
    meshIpv4 = "10.144.144.1/24";
    portalPort = 61013;
    tcpPorts = [ 61070 ];
    udpPorts = [
      61070
      61071
      61013
    ];

    raspi = {
      ipv4 = "10.144.144.2";
    };
  };

  # Tailscale tailnet. `magicDnsDomain` is the tailnet's MagicDNS suffix;
  # nodes are reached as <hostname>.<magicDnsDomain>.
  tailnet = {
    magicDnsDomain = "tail6338b8.ts.net";
  };
}
