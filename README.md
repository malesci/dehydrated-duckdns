# Dehydrated DuckDNS

## Solution inspired by the official [Home Assistant Add-on addon: DuckDNS](https://github.com/home-assistant/addons/tree/master/duckdns#home-assistant-add-on-duckdns) and [dehydrated-io](https://github.com/dehydrated-io/dehydrated#dehydrated-) projects

## This installation is stand-alone and allows you to use Dehydrated as a client for signing certificates and DuckDNS

## How to use

1. Visit [DuckDNS.org](https://www.duckdns.org/) and create an account by logging in through any of the available account services (Google, Github, Twitter, Persona, Reddit).
2. In the `Domains` section, type the name of the subdomain you wish to register and click `add domain`.
3. If registration was a success, the subdomain is listed in the `Domains` section along with `current ip` being the public IP address of the device you are currently using to access `duckdns.org`. The IP address will be updated by the DuckDNS add-on.
4. In the DuckDNS add-on configuration, perform the following:
    - Copy the DuckDNS token (listed at the top of the page where account details are displayed) from `duckdns.org` and paste into the `token` option.
    - Update the `domains` option with the full domain name you registered. E.g., `my-domain.duckdns.org`.

## Docker sample usage
```docker
docker run -d -it --name dehydrated-duckdns --restart unless-stopped -v ${PWD}/dehydrated-duckdns/data/:/data alescim/dehydrated-duckdns
```

## Docker-compose sample usage
```yaml
version: '3'

services:  
  dehydrated-duckdns:
    container_name: dehydrated-duckdns
    image: alescim/dehydrated-duckdns
    volumes:
      - "${PWD}/dehydrated-duckdns/data/:/data"
    restart: unless-stopped
```

## Configuration

Make a copy of `dehydrated-duckdns/data/options.example.json` file as `dehydrated-duckdns/data/options.json`

options.json configuration:

```json
{
  "lets_encrypt": {
    "accept_terms": true,
    "certfile": "fullchain.pem",
    "keyfile": "privkey.pem",
    "algo": "rsa"
  },
  "token": "<<YOUR DUCKDNS TOKEN>>",
  "domains": [
    "<<YOUR DUCKDNS DOMAIN>>"
  ],
  "aliases": [],
  "seconds": 600,
  "ipv4": "<<YOUR DUCKDNS IP>>"
}
```

### Option group `lets_encrypt`

The following options are for the option group: `lets_encrypt`. These settings
only apply to Let's Encrypt SSL certificates.

#### Option `lets_encrypt.accept_terms`

Once you have read and accepted the Let's Encrypt[Subscriber Agreement](https://letsencrypt.org/repository/), change value to `true` in order to use Let's Encrypt services.

#### Option `lets_encrypt.certfile`

The name of the certificate file generated by Let's Encrypt. The file is used for SSL by Home Assistant add-ons and is recommended to keep the filename as-is (`fullchain.pem`) for compatibility.

**Note**: _The file is stored in `/data/ssl/`, which is the default for Home Assistant_

#### Option `lets_encrypt.keyfile`

The name of the private key file generated by Let's Encrypt. The private key file is used for SSL by Home Assistant add-ons and is recommended to keep the filename as-is (`privkey.pem`) for compatibility.

**Note**: _The file is stored in `/data/ssl/`, which is the default for Home Assistant_

#### Option `lets_encrypt.algo`

Public key algorithm that will be used.

Supported values: `rsa`, `prime256v1` and `secp384r1`. 

The default is `rsa`


### Option: `ipv4` (optional)

By default, Duck DNS will auto detect your IPv4 address and use that.
This option allows you to override the auto-detection and specify an
IPv4 address manually.

If you specify a URL here, contents of the resource it points to will be
fetched and used as the address. This enables getting the address using
a service like https://api.ipify.org/ or https://ipv4.text.wtfismyip.com

### Option: `ipv6` (optional)

By default, Duck DNS will auto detect your IPv6 address and use that.
This option allows you to override the auto-detection and specify an
IPv6 address manually.

If you specify a URL here, contents of the resource it points to will be
fetched and used as the address. This enables getting the address using
a service like https://api6.ipify.org/ or https://ipv6.text.wtfismyip.com

### Option: `token`

The DuckDNS authentication token found at the top of the DuckDNS account landing page. The token is required to make any changes to the subdomains registered to your account.

### Option: `domains`

A list of DuckDNS subdomains registered under your account. An acceptable naming convention is `my-domain.duckdns.org`.

### Option: `aliases` (optional)

A list aliases of domains configured on the `domains` option.
This is useful in cases where you would like to use your own domain.
Create a CNAME record to point at the DuckDNS subdomain and set this value accordingly.

For example:

```json
{
  "domains": [
    "my-domain.duckdns.org"
  ],
  "aliases": [
    {
      "domain": "ha.my-domain.com",
      "alias": "my-domain.duckdns.org"
    }
  ]
}
```

Don't add your custom domain name to the `domains` array. For certificate creation, all unique domains and aliases are used.

Also, don't forget to make sure the dns-01 challenge can reach Duckdns. It might be required to add a specific CNAME for that:

```
CNAME _acme-challenge.<own-domain>    _acme-challenge.<domain>.duckdns.org
CNAME                 <own-domain>                    <domain>.duckdns.org
```

### Option: `seconds`

The number of seconds to wait before updating DuckDNS subdomains and renewing Let's Encrypt certificates.

## Known issues and limitations

- To log in, DuckDNS requires a free account from any of the following services: Google, Github, Twitter, Persona or Reddit.
- A free DuckDNS account is limited to five subdomains.
- At time of writing, Duck DNS' own IPv6 autodetection
  [does not actually work][duckdns-faq], but you can use the URL option
  for `ipv6` to get around this, read on.
