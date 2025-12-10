use anyhow::Result;
use std::net::Ipv4Addr;

/// Allocate Nebula IP for a dispatcher
/// Dispatchers get the .1 address in their own /24 subnet
/// Format: 10.42.X.1 where X is determined by dispatcher count
pub fn allocate_dispatcher_ip(dispatcher_count: usize) -> Result<String> {
    // Each dispatcher gets their own /24 subnet
    // 10.42.1.0/24 -> Dispatcher 1
    // 10.42.2.0/24 -> Dispatcher 2
    // ...
    // 10.42.255.0/24 -> Dispatcher 255

    let subnet_id = (dispatcher_count + 1) as u8;
    if subnet_id == 0 {
        anyhow::bail!("Dispatcher count overflow");
    }

    let ip = Ipv4Addr::new(10, 42, subnet_id, 1);
    Ok(ip.to_string())
}

/// Allocate Nebula IP for a driver
/// Drivers get .2-.254 addresses in their dispatcher's subnet
/// Format: 10.42.X.Y where X is dispatcher's subnet, Y is 2-254
pub fn allocate_driver_ip(dispatcher_ip: &str, driver_count: usize) -> Result<String> {
    // Parse dispatcher IP to get subnet
    let parts: Vec<&str> = dispatcher_ip.split('.').collect();
    if parts.len() != 4 {
        anyhow::bail!("Invalid dispatcher IP format");
    }

    let subnet_id: u8 = parts[2].parse()?;

    // Drivers get IPs from .2 to .254 (253 max drivers per dispatcher)
    let host_id = (driver_count + 2) as u8; // +2 because .1 is dispatcher, start at .2
    if host_id >= 255 {
        anyhow::bail!("Driver count exceeds subnet capacity (max 253 per dispatcher)");
    }

    let ip = Ipv4Addr::new(10, 42, subnet_id, host_id);
    Ok(ip.to_string())
}

/// Parse Nebula IP to determine if it's a dispatcher or driver
pub fn parse_nebula_ip(ip: &str) -> Result<(String, bool)> {
    let parts: Vec<&str> = ip.split('.').collect();
    if parts.len() != 4 {
        anyhow::bail!("Invalid IP format");
    }

    let host_id: u8 = parts[3].parse()?;
    let is_dispatcher = host_id == 1;

    Ok((ip.to_string(), is_dispatcher))
}

/// Get dispatcher IP from driver IP
pub fn get_dispatcher_ip_from_driver(driver_ip: &str) -> Result<String> {
    let parts: Vec<&str> = driver_ip.split('.').collect();
    if parts.len() != 4 {
        anyhow::bail!("Invalid IP format");
    }

    let subnet_id: u8 = parts[2].parse()?;
    let dispatcher_ip = format!("10.42.{}.1", subnet_id);

    Ok(dispatcher_ip)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_allocate_dispatcher_ip() {
        assert_eq!(allocate_dispatcher_ip(0).unwrap(), "10.42.1.1");
        assert_eq!(allocate_dispatcher_ip(1).unwrap(), "10.42.2.1");
        assert_eq!(allocate_dispatcher_ip(254).unwrap(), "10.42.255.1");
    }

    #[test]
    fn test_allocate_driver_ip() {
        assert_eq!(allocate_driver_ip("10.42.1.1", 0).unwrap(), "10.42.1.2");
        assert_eq!(allocate_driver_ip("10.42.1.1", 1).unwrap(), "10.42.1.3");
        assert_eq!(allocate_driver_ip("10.42.1.1", 252).unwrap(), "10.42.1.254");
    }

    #[test]
    fn test_parse_nebula_ip() {
        let (ip, is_dispatcher) = parse_nebula_ip("10.42.1.1").unwrap();
        assert_eq!(ip, "10.42.1.1");
        assert!(is_dispatcher);

        let (ip, is_dispatcher) = parse_nebula_ip("10.42.1.2").unwrap();
        assert_eq!(ip, "10.42.1.2");
        assert!(!is_dispatcher);
    }

    #[test]
    fn test_get_dispatcher_ip() {
        assert_eq!(get_dispatcher_ip_from_driver("10.42.1.2").unwrap(), "10.42.1.1");
        assert_eq!(get_dispatcher_ip_from_driver("10.42.5.100").unwrap(), "10.42.5.1");
    }
}
