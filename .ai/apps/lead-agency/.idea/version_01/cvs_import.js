// ============================================
// CSV IMPORT SCRAPER
// ============================================
// Imports leads from CSV files you create manually

const fs = require("fs");
const csv = require("csv-parser");
const path = require("path");

class CSVImportScraper {
  constructor(engine) {
    this.engine = engine;
    this.name = "csv_import";
  }

  async scrape(source, campaign) {
    console.log(`    📄 Importing CSV: ${source.csv_path}`);

    if (!fs.existsSync(source.csv_path)) {
      console.error(`    ✗ CSV file not found: ${source.csv_path}`);
      return [];
    }

    const leads = await this.parseCSV(source.csv_path);
    console.log(`    ✓ Imported ${leads.length} leads from CSV`);

    return leads;
  }

  async parseCSV(csvPath) {
    const leads = [];

    return new Promise((resolve, reject) => {
      fs.createReadStream(csvPath)
        .pipe(csv())
        .on("data", (row) => {
          // Flexible column mapping - tries common variations
          const lead = {
            email: this.getValue(row, [
              "email",
              "Email",
              "Email Address",
              "email_address",
            ]),
            first_name: this.getValue(row, [
              "first_name",
              "First Name",
              "FirstName",
              "fname",
            ]),
            last_name: this.getValue(row, [
              "last_name",
              "Last Name",
              "LastName",
              "lname",
            ]),
            full_name: this.getValue(row, [
              "full_name",
              "Full Name",
              "Name",
              "name",
            ]),
            company_name: this.getValue(row, [
              "company",
              "Company",
              "Company Name",
              "company_name",
            ]),
            job_title: this.getValue(row, [
              "job_title",
              "Job Title",
              "Title",
              "Position",
              "position",
            ]),
            phone: this.getValue(row, [
              "phone",
              "Phone",
              "Phone Number",
              "phone_number",
            ]),
            website: this.getValue(row, ["website", "Website", "URL", "url"]),
            linkedin_url: this.getValue(row, [
              "linkedin",
              "LinkedIn",
              "linkedin_url",
              "LinkedIn URL",
            ]),
            source_type: "csv_import",
            source_url: csvPath,
            raw_data: row, // Store all original data
          };

          // Only add if we have at least email or company name
          if (lead.email || lead.company_name) {
            // Build full_name if not provided
            if (!lead.full_name && (lead.first_name || lead.last_name)) {
              lead.full_name =
                `${lead.first_name || ""} ${lead.last_name || ""}`.trim();
            }

            leads.push(lead);
          }
        })
        .on("end", () => {
          console.log(`    ✓ Parsed ${leads.length} valid leads`);
          resolve(leads);
        })
        .on("error", (error) => {
          console.error(`    ✗ CSV parsing error:`, error);
          reject(error);
        });
    });
  }

  // Helper to find value from multiple possible column names
  getValue(row, possibleKeys) {
    for (const key of possibleKeys) {
      if (row[key] !== undefined && row[key] !== null && row[key] !== "") {
        return String(row[key]).trim();
      }
    }
    return null;
  }

  // Create example CSV template
  static createTemplate(outputPath = "/data/lead_template.csv") {
    const template = `email,first_name,last_name,company_name,job_title,phone,website,linkedin_url,notes
john@example.com,John,Doe,Example Trucking,CEO,555-1234,https://example.com,https://linkedin.com/in/johndoe,Found via referral
jane@acme.com,Jane,Smith,Acme Logistics,Operations Manager,555-5678,https://acme.com,,Met at conference
`;

    fs.writeFileSync(outputPath, template);
    console.log(`✓ CSV template created: ${outputPath}`);
  }
}

module.exports = CSVImportScraper;
