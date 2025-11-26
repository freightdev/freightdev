// ============================================
// WEB SCRAPER MODULE
// ============================================
// Scrapes websites for contact info and company data

const axios = require("axios");
const cheerio = require("cheerio");

class WebScraper {
  constructor(engine) {
    this.engine = engine;
    this.name = "web_scraper";
  }

  // Main scrape method
  async scrape(source, campaign) {
    const leads = [];

    for (const url of source.target_urls) {
      try {
        console.log(`    🌐 Scraping: ${url}`);

        // Respect rate limits
        if (this.engine.config.engine.respect_rate_limits) {
          await this.delay(2000);
        }

        const pageLeads = await this.scrapePage(url, source);
        leads.push(...pageLeads);

        // If scrape_depth > 1, follow links
        if (source.scrape_depth > 1) {
          const childLinks = await this.extractLinks(url, source.scrape_depth);
          for (const link of childLinks.slice(0, 10)) {
            // Limit to 10 child pages
            try {
              const childLeads = await this.scrapePage(link, source);
              leads.push(...childLeads);
              await this.delay(2000);
            } catch (error) {
              console.error(`      ✗ Failed to scrape ${link}:`, error.message);
            }
          }
        }
      } catch (error) {
        console.error(`    ✗ Failed to scrape ${url}:`, error.message);
      }
    }

    return this.deduplicateLeads(leads);
  }

  async scrapePage(url, source) {
    const leads = [];

    try {
      const response = await axios.get(url, {
        timeout: 30000,
        headers: {
          "User-Agent":
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
        },
      });

      const $ = cheerio.load(response.data);
      const text = $("body").text();
      const html = response.data;

      // Extract emails
      const emails = this.extractEmails(html);

      // Extract phones
      const phones = this.extractPhones(text);

      // Extract company name (from title, h1, or domain)
      const companyName = this.extractCompanyName($, url);

      // For each email, create a lead entry
      for (const email of emails) {
        // Skip common non-person emails
        if (this.isGenericEmail(email)) continue;

        leads.push({
          email,
          company_name: companyName,
          phone: phones[0] || null,
          website: url,
          source_type: "web_scraper",
          source_url: url,
          raw_data: {
            all_phones: phones,
            page_title: $("title").text().trim(),
            meta_description: $('meta[name="description"]').attr("content"),
          },
        });
      }

      // If no emails found but we have company info, still create a lead
      if (emails.length === 0 && companyName) {
        leads.push({
          email: null,
          company_name: companyName,
          phone: phones[0] || null,
          website: url,
          source_type: "web_scraper",
          source_url: url,
          raw_data: {
            all_phones: phones,
            page_title: $("title").text().trim(),
            needs_email: true,
          },
        });
      }
    } catch (error) {
      throw error;
    }

    return leads;
  }

  extractEmails(html) {
    const emailRegex = /[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/g;
    const emails = html.match(emailRegex) || [];

    // Clean and deduplicate
    return [
      ...new Set(
        emails.map((e) => e.toLowerCase().trim()).filter((e) => e.length < 100), // Filter out suspiciously long emails
      ),
    ];
  }

  extractPhones(text) {
    // Match various phone formats
    const phoneRegex = /(\+?1[-.\s]?)?(\(?\d{3}\)?[-.\s]?)?\d{3}[-.\s]?\d{4}/g;
    const phones = text.match(phoneRegex) || [];

    return [
      ...new Set(
        phones
          .map((p) => p.replace(/[^\d+]/g, ""))
          .filter((p) => p.length >= 10),
      ),
    ];
  }

  extractCompanyName($, url) {
    // Try multiple methods to find company name

    // 1. From title tag
    let title = $("title").text().trim();
    if (title) {
      // Remove common suffixes
      title = title.replace(/\s*[-|–]\s*(Home|About|Contact|Services).*$/i, "");
      if (title.length > 3 && title.length < 100) {
        return title;
      }
    }

    // 2. From h1
    const h1 = $("h1").first().text().trim();
    if (h1 && h1.length < 100) {
      return h1;
    }

    // 3. From domain
    try {
      const domain = new URL(url).hostname.replace("www.", "");
      const name = domain.split(".")[0];
      return name.charAt(0).toUpperCase() + name.slice(1);
    } catch (error) {
      return "Unknown Company";
    }
  }

  isGenericEmail(email) {
    const genericPrefixes = [
      "info",
      "contact",
      "admin",
      "support",
      "sales",
      "hello",
      "noreply",
      "no-reply",
      "mail",
      "webmaster",
      "postmaster",
    ];

    const prefix = email.split("@")[0].toLowerCase();
    return genericPrefixes.some((g) => prefix.includes(g));
  }

  async extractLinks(baseUrl, maxDepth) {
    try {
      const response = await axios.get(baseUrl, {
        timeout: 15000,
        headers: {
          "User-Agent":
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
        },
      });

      const $ = cheerio.load(response.data);
      const links = [];
      const baseDomain = new URL(baseUrl).hostname;

      $("a[href]").each((i, elem) => {
        const href = $(elem).attr("href");
        if (!href) return;

        try {
          const absoluteUrl = new URL(href, baseUrl).href;
          const urlObj = new URL(absoluteUrl);

          // Only same domain
          if (urlObj.hostname === baseDomain) {
            // Filter out common non-content pages
            const path = urlObj.pathname.toLowerCase();
            if (
              !path.match(
                /(login|signin|signup|cart|checkout|terms|privacy|cookie)/,
              )
            ) {
              links.push(absoluteUrl);
            }
          }
        } catch (error) {
          // Invalid URL, skip
        }
      });

      return [...new Set(links)]; // Deduplicate
    } catch (error) {
      console.error(`Failed to extract links from ${baseUrl}:`, error.message);
      return [];
    }
  }

  deduplicateLeads(leads) {
    const seen = new Set();
    const unique = [];

    for (const lead of leads) {
      const key = lead.email || lead.website;
      if (key && !seen.has(key)) {
        seen.add(key);
        unique.push(lead);
      }
    }

    return unique;
  }

  delay(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }
}

module.exports = WebScraper;
