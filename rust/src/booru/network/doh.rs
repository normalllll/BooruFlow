use crate::api::booru_models::RouteProvider;
use base64::Engine;
use std::collections::BTreeSet;
use std::net::{IpAddr, Ipv4Addr, Ipv6Addr, SocketAddr};
use std::time::Duration;

pub async fn resolve(provider: RouteProvider, host: &str) -> Result<Vec<String>, String> {
    let (name, addresses): (&str, &[&str]) = match provider {
        RouteProvider::UncensoredDns => (
            "anycast.uncensoreddns.org",
            &["91.239.100.100", "2001:67c:28a4::"],
        ),
        RouteProvider::DohSb => (
            "doh.sb",
            &["185.222.222.222", "45.11.45.11", "2a09::", "2a11::"],
        ),
    };
    let addresses: Vec<_> = addresses
        .iter()
        .map(|address| SocketAddr::new(address.parse().unwrap(), 443))
        .collect();
    // Bootstrap explicitly: resolving the DNS service never uses system DNS.
    // DoH keeps normal TLS validation and HTTP/2, independently of source bypass.
    let client = super::tls::client_builder()
        .no_proxy()
        .resolve_to_addrs(name, &addresses)
        .https_only(true)
        .redirect(reqwest::redirect::Policy::none())
        .timeout(Duration::from_secs(8))
        .build()
        .map_err(|e| e.to_string())?;
    let query = |kind| query(&client, name, host, kind);
    let (v4, v6) = tokio::join!(query(1), query(28));
    // A transport/protocol failure must remain visible, even if the other
    // record family succeeded. Empty AAAA with RCODE 0 is valid.
    let mut ips = BTreeSet::new();
    ips.extend(v4?);
    ips.extend(v6?);
    if ips.is_empty() {
        return Err("DNS returned no public A/AAAA addresses".into());
    }
    Ok(ips.into_iter().take(8).collect())
}

async fn query(
    client: &reqwest::Client,
    endpoint: &str,
    host: &str,
    kind: u16,
) -> Result<Vec<String>, String> {
    let packet = encode_query(host, kind)?;
    let encoded = base64::engine::general_purpose::URL_SAFE_NO_PAD.encode(&packet);
    let response = client
        .get(format!("https://{endpoint}/dns-query?dns={encoded}"))
        .header("Accept", "application/dns-message")
        .send()
        .await
        .map_err(|e| {
            if e.is_timeout() {
                "DNS request timed out (8s)".into()
            } else {
                format!("DNS TLS/connection failed: {e}")
            }
        })?;
    if !response.status().is_success() {
        return Err(format!("DNS HTTP {}", response.status().as_u16()));
    }
    if response
        .headers()
        .get("content-type")
        .and_then(|v| v.to_str().ok())
        .is_none_or(|v| v.split(';').next().unwrap_or("").trim() != "application/dns-message")
    {
        return Err("DNS response is not application/dns-message".into());
    }
    let bytes = response.bytes().await.map_err(|e| e.to_string())?;
    decode_answer(&bytes, &packet, kind)
}

fn encode_query(host: &str, kind: u16) -> Result<Vec<u8>, String> {
    if host.len() > 253 || !host.is_ascii() {
        return Err("Invalid DNS name".into());
    }
    let mut packet = vec![0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0];
    for label in host.trim_end_matches('.').split('.') {
        if label.is_empty() || label.len() > 63 {
            return Err("Invalid DNS label".into());
        }
        packet.push(label.len() as u8);
        packet.extend_from_slice(label.as_bytes());
    }
    packet.push(0);
    packet.extend_from_slice(&kind.to_be_bytes());
    packet.extend_from_slice(&1_u16.to_be_bytes());
    Ok(packet)
}

fn word(bytes: &[u8], offset: usize) -> Result<u16, String> {
    Ok(u16::from_be_bytes(
        bytes
            .get(offset..offset + 2)
            .ok_or("Truncated DNS response")?
            .try_into()
            .unwrap(),
    ))
}

fn skip_name(bytes: &[u8], mut offset: usize) -> Result<usize, String> {
    for _ in 0..128 {
        let len = *bytes.get(offset).ok_or("Truncated DNS name")?;
        offset += 1;
        if len == 0 {
            return Ok(offset);
        }
        if len & 0xc0 == 0xc0 {
            let low = *bytes.get(offset).ok_or("Truncated DNS pointer")?;
            let target = (usize::from(len & 0x3f) << 8) | usize::from(low);
            if target >= offset - 1 {
                return Err("Invalid DNS pointer".into());
            }
            return Ok(offset + 1);
        }
        if len > 63 {
            return Err("Invalid DNS label".into());
        }
        offset += usize::from(len);
    }
    Err("Invalid DNS name".into())
}

fn decode_answer(bytes: &[u8], query: &[u8], kind: u16) -> Result<Vec<String>, String> {
    let flags = word(bytes, 2)?;
    if word(bytes, 0)? != 0 || flags & 0x8000 == 0 || flags & 0x7a00 != 0 {
        return Err("Invalid or truncated DNS response".into());
    }
    if flags & 15 != 0 {
        return Err(format!("DNS RCODE {}", flags & 15));
    }
    if word(bytes, 4)? != 1 || bytes.get(12..query.len()) != query.get(12..) {
        return Err("DNS question mismatch".into());
    }
    let mut offset = query.len();
    let mut ips = Vec::new();
    for _ in 0..word(bytes, 6)? {
        offset = skip_name(bytes, offset)?;
        let record_type = word(bytes, offset)?;
        let class = word(bytes, offset + 2)?;
        let length = usize::from(word(bytes, offset + 8)?);
        offset += 10;
        let data = bytes
            .get(offset..offset + length)
            .ok_or("Truncated DNS record")?;
        if class == 1 && record_type == kind {
            let ip = match (record_type, length) {
                (1, 4) => Some(IpAddr::V4(Ipv4Addr::from(
                    <[u8; 4]>::try_from(data).unwrap(),
                ))),
                (28, 16) => Some(IpAddr::V6(Ipv6Addr::from(
                    <[u8; 16]>::try_from(data).unwrap(),
                ))),
                (1 | 28, _) => return Err("Invalid DNS address length".into()),
                _ => None,
            };
            if let Some(ip) = ip {
                if !super::route_cache::is_public_ip(ip) {
                    return Err(format!("DNS returned a non-public address: {ip}"));
                }
                ips.push(ip.to_string());
            }
        }
        offset += length;
    }
    Ok(ips)
}

#[cfg(test)]
mod tests {
    use super::*;
    fn reply(ip: [u8; 4]) -> (Vec<u8>, Vec<u8>) {
        let query = encode_query("yande.re", 1).unwrap();
        let mut response = query.clone();
        response[2] = 0x81;
        response[3] = 0x80;
        response[7] = 1;
        response.extend([0xc0, 12, 0, 1, 0, 1, 0, 0, 0, 60, 0, 4]);
        response.extend(ip);
        (query, response)
    }
    #[test]
    fn validates_wire_answers_and_rejects_poisoned_or_truncated_packets() {
        let (q, mut r) = reply([198, 251, 89, 183]);
        assert_eq!(decode_answer(&r, &q, 1).unwrap(), vec!["198.251.89.183"]);
        r.pop();
        assert!(decode_answer(&r, &q, 1).is_err());
        let (q, r) = reply([127, 0, 0, 1]);
        assert!(decode_answer(&r, &q, 1).unwrap_err().contains("non-public"));
        let (q, mut r) = reply([8, 8, 8, 8]);
        r[3] = 0x83;
        assert!(decode_answer(&r, &q, 1).unwrap_err().contains("RCODE 3"));
    }
    #[test]
    fn empty_successful_record_family_is_valid() {
        let q = encode_query("yande.re", 28).unwrap();
        let mut r = q.clone();
        r[2] = 0x81;
        r[3] = 0x80;
        assert!(decode_answer(&r, &q, 28).unwrap().is_empty());
    }
}
