$ORIGIN unwiredin.com.
$TTL 3600 ; Default Time-To-Live for records (1 hour)

@       IN  SOA ns.unwiredin.com. admin.unwiredin.com. (
        2025052402  ; Serial (YYYYMMDDNN - IMPORTANT: Increment with each change!)
        7200        ; Refresh (2 hours)
        3600        ; Retry (1 hour)
        1209600     ; Expire (2 weeks)
        3600        ; Minimum TTL / Negative Cache TTL (1 hour)
)

; Nameserver(s) for unwiredin.com (authoritative for this internal view)
@       IN  NS      ns.unwiredin.com.             ; Declares ns.unwiredin.com as a nameserver

; Glue record for the internal nameserver (points to your CoreDNS server)
ns      IN  A       10.10.1.2                     ; IP of your CoreDNS LXC

; Records for Caddy Reverse Proxy and services it handles
caddy   IN  A       10.10.1.3                     ; A record for your Caddy server
whoami  IN  CNAME   caddy.unwiredin.com.          ; 'whoami' service, served via Caddy
unraid  IN  CNAME   unraid.unwiredin.com.         ; Unraid VM
auth    IN  CNAME   auth.unwiredin.com.           ; Authelia LXC 

; Wildcard for all other undefined subdomains in this internal zone
; Points to your Caddy server to handle them as default
* IN  A       10.10.1.3

; No A record for the apex '@' as it's handled by Cloudflare externally.