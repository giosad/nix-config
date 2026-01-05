# Nix Configuration

NixOS and macOS (nix-darwin) configuration using flakes.

## macOS (nix-darwin)

### Prerequisites

Install Determinate Nix:

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

### Configuration

Your host configuration (e.g., `hosts/workmbp/configuration.nix`) **must** include:

```nix
# Let Determinate Nix manage the daemon
nix.enable = false;

# Disable PAM management (SIP prevents modifying /etc/pam.d/)
# Required: bootstrap fails without this
security.pam.services.sudo_local.enable = false;
```

### Installation

Before first run, move the existing zshenv (created by Determinate Nix):

```bash
sudo mv /etc/zshenv /etc/zshenv.before-nix-darwin
```

First-time bootstrap:

```bash
sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake .#workmbp
```

### Usage

After first install:

```bash
darwin-rebuild switch --flake .#workmbp
```

## NixOS

```bash
sudo nixos-rebuild switch --flake .#nixos
```

## Maintenance

Garbage collect old generations:

```bash
nix-collect-garbage -d
```

## Structure

```
.
├── flake.nix              # Main flake configuration
├── flake.lock             # Locked dependencies
├── home/                  # Home-manager configurations
│   └── gena.nix
└── hosts/
    ├── nixos/             # NixOS host
    │   ├── configuration.nix
    │   └── hardware-configuration.nix
    └── workmbp/           # macOS host
        └── configuration.nix
```
