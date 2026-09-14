# Agent Playbook: Using MyNixOS to Look Up Settings

## Scenario
When you need to explain, verify, or tweak any NixOS/Home Manager option (for example `services.ollama`), use MyNixOS as the primary reference. This guide keeps the steps consistent.

## Workflow
1. **Open the reference**: https://mynixos.com/options for system modules, https://mynixos.com/home-manager/options for Home Manager, and https://mynixos.com/packages when you need to inspect package metadata (version, maintainer, description).
2. **Search quickly**: Use the page search bar; type the module path (e.g., `services.ollama`) or a keyword like `firewall`.
3. **Inspect the option entry**:
   - Read the description to understand behavior and defaults.
   - Note the exact attribute name (e.g., `services.ollama.environmentVariables`).
   - Check type requirements, default values, and whether it’s `mkOption` or enum-restricted.
4. **Cross-link**: Each entry links to the Nixpkgs/manual source. Follow it when deeper context (examples, caveats) is needed.
5. **Document for the user**: When relaying info back, cite the relevant option names and summarize what each field controls. Mention if an option lives under `system` vs. `home-manager`.
6. **Validate locally**: After adjusting configuration files, suggest running `sudo nixos-option <option>` or `home-manager options <option>` to confirm the value.

## Tips
- If multiple hits appear, prefer the `nixpkgs` variant for system configs unless the user explicitly mentions Home Manager.
- Some options (like `openFirewall`) can replace manual firewall rules; call that out to reduce redundant config.
- When environment variables are exposed (e.g., `services.<svc>.environmentVariables`), prefer them instead of hand-editing `systemd.services`.
- Keep answers concise but include the exact option names so the user can search or grep later.

Use this checklist whenever someone asks, “Where’s the setting for …?”—MyNixOS almost always has it indexed.
