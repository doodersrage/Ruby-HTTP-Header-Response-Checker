# Ruby HTTP Header Response Checker

Checks HTTP response codes for a list of URLs and writes results to a TSV file. Follows redirects, records redirect chains, and reports response times.

## Requirements

- Ruby 2.7+ (tested on Ruby 3.4)

## Usage

Run with defaults (`pages.csv` input, `results.tsv` output):

```bash
ruby response_check.rb
```

### Options

```bash
ruby response_check.rb --help
```

| Option | Description |
|--------|-------------|
| `-o`, `--output FILE` | Output TSV file (default: `results.tsv`) |
| `-f`, `--input FILE` | Input URL list file (default: `pages.csv`) |
| `-r`, `--replace URL` | URL prefix to replace in the input list |
| `-n`, `--new-url URL` | Replacement URL prefix |
| `-t`, `--timeout SECONDS` | HTTP open/read timeout (default: 15) |
| `--redirect-limit COUNT` | Maximum redirects to follow (default: 10) |
| `--no-ssl-verify` | Disable SSL certificate verification |
| `-i`, `--interactive` | Prompt for file paths and URL replacement values |

### Examples

```bash
# Check URLs with a custom input file
ruby response_check.rb -f urls.txt -o report.tsv

# Interactive mode (original behavior)
ruby response_check.rb --interactive

# Verbose redirect logging
ruby -v response_check.rb
```

## Input format

One URL or hostname per line in the input file. Hostnames without a scheme are checked over `http://`. Lines starting with `//` are checked over `https://`.

## Output format

Tab-separated values with columns:

```
status  url  redirects  response_time
```

When a URL redirects, `status` contains the redirect response codes and `redirects` lists the target URLs.
