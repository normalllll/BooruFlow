const DEFAULT_USER_AGENT: &str = "BooruFlow/1.0";
pub const BROWSER_USER_AGENT: &str = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36";

pub fn normalize_user_agent(value: &str) -> String {
    let value = value.trim();
    if value
        .get(.."BooruFlow".len())
        .is_some_and(|prefix| prefix.eq_ignore_ascii_case("BooruFlow"))
    {
        value.to_owned()
    } else if value.is_empty() {
        DEFAULT_USER_AGENT.to_owned()
    } else {
        format!("{DEFAULT_USER_AGENT} {value}")
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn user_agent_always_starts_with_product_name() {
        assert_eq!(normalize_user_agent(""), "BooruFlow/1.0");
        assert_eq!(normalize_user_agent("client/2"), "BooruFlow/1.0 client/2");
        assert_eq!(normalize_user_agent("BooruFlow/2"), "BooruFlow/2");
    }
}
