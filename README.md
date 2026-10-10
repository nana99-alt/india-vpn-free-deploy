# IndiaVPN Free Deploy

An elegant responsive web dashboard for Render, plus a WireGuard helper script for a **real Ubuntu VPS located in India**.

## What works immediately?

- The dashboard can be deployed as a free Render web service.
- `/health` provides a health check.
- The site clearly states that it is not itself a VPN tunnel.

## What does not work without a VPS?

This project does **not** change the phone's public IP by itself. Render free web services are for web apps and do not provide a WireGuard exit server. To get an India IP, you must obtain a VPS whose public IP is located in India, install WireGuard there, and connect with the official WireGuard Android app.

Oracle Cloud Always Free is one possible option, but free capacity is not guaranteed and compute resources are restricted to your account's home region. You must check whether India is available before choosing a home region. Do not choose a different region expecting it to provide an India IP.

## Deploy dashboard to Render

1. Create a GitHub repository, e.g. `india-vpn-free-deploy`.
2. Upload every file/folder from this project to the repository root.
3. Open Render Dashboard and choose **New + → Blueprint**.
4. Connect your repository. Render should detect `render.yaml`.
5. Review the service and deploy.
6. When deployed, open the Render URL. The page is only the control panel.

Alternative: create a Render Web Service manually with:
- Build command: `npm install`
- Start command: `npm start`
- Plan: Free

## Try Oracle Cloud for a free India VPS

1. Visit https://www.oracle.com/cloud/free/
2. During signup, check the offered Home Region options. Choose an India region only if it is actually offered and you are sure; the home region cannot normally be changed later.
3. After signup, create an Ubuntu VM only if the console marks the chosen compute shape/resources as Always Free eligible.
4. If India is not offered, this route cannot give you an India exit IP under that account's home region. Do not assume a nearby region is India.
5. Keep track of resource labels and billing. Avoid creating paid resources.

Free capacity may be unavailable, and account signup may require identity/payment-card verification depending on Oracle's current checks.

## Install WireGuard on the VPS

**Only run this script on a normal Ubuntu Server VPS you own and administer. Do not run it inside Termux Ubuntu/PRoot.** It requires systemd, kernel networking support, routing, and firewall access.

1. SSH into the India VPS.
2. Upload `scripts/install-wireguard-server.sh`.
3. Run:

   ```bash
   chmod +x install-wireguard-server.sh
   sudo ./install-wireguard-server.sh
   ```

4. In the cloud firewall/security list, allow inbound **UDP 51820**. If UFW is enabled, run `sudo ufw allow 51820/udp`.
5. Securely transfer `/etc/wireguard/clients/android.conf` to your phone. Do not commit it to GitHub.
6. Install the official WireGuard Android app: https://play.google.com/store/apps/details?id=com.wireguard.android
7. Import the profile and connect. Verify the public IP and country at https://ipinfo.io/.

## Security

- Never upload `.conf`, private keys, SSH keys, passwords, or QR codes to a public repository.
- The helper script creates one client profile. It is a starter, not a multi-user VPN management system.
- Confirm your VPS provider permits VPN use and confirm the IP geolocation shows India.
- If the script cannot detect the public IPv4, replace `REPLACE_WITH_VPS_PUBLIC_IPV4` in the generated client configuration with the real public IP.
- Test for DNS leaks and IPv6 leaks. This basic profile tunnels IPv4 traffic only; it does not configure IPv6 routing.
- The script is not guaranteed to work unchanged on every VPS image/firewall configuration. Review output and provider networking rules.

## Project tree

```text
india-vpn-free-deploy/
├── public/
│   ├── index.html
│   └── style.css
├── scripts/
│   └── install-wireguard-server.sh
├── .gitignore
├── package.json
├── render.yaml
├── server.js
└── README.md
```
