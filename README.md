# Azazel

Azazel is a Bash script designed to perform subdomain enumeration and reconnaissance on target domains. It utilizes various tools and options to collect subdomains, identify live subdomains, and potentially capture screenshots or discover parameters on the live subdomains.

## Usage
```
./azazel.sh -d target.com -x exclude.domain.com -s
```

## Prerequisites
- Bash
- subfinder
- assetfinder
- httpx
- ParamSpider (optional)
- Eyewitness (optional)

Make sure you have the necessary tools installed and available in your system before running this script.

## Usage
```
./azazel.sh [options]
```

## Options

**-d domains**: Set the target domains. This can be a single domain, a comma-separated list of domains, or a path to a file with one domain per line.

**-x exclude**: Exclude specific domains/subdomains.

**-s**: Capture screenshots on live subdomains.

**-p**: Use ParamSpider for discovering parameters on live subdomains.

**-h**: Display the help menu.

## Examples

Perform subdomain enumeration on a single domain:
```
./azazel.sh -d example.com
```
Perform subdomain enumeration on multiple domains:
```
./azazel.sh -d example.com,example.org,example.net
```
Perform subdomain enumeration using a file with domains:
```
./azazel.sh -d domains.txt
```
Exclude specific domains/subdomains:
```
./azazel.sh -d example.com -x excluded.txt
```
Capture screenshots on live subdomains:
```
./azazel.sh -d example.com -s
```
Use ParamSpider for discovering parameters on live subdomains:
```
./azazel.sh -d example.com -p
```
## Output
The script will create a directory named scan with a subdirectory for each target domain and a timestamped subdirectory for each scan. The output directory structure will be as follows:

```
scan/
  ├─ example.com/
  │   └─ 202301011200/
  │         ├─ subdomains.txt
  │         ├─ livesubdomains.txt
  │         └─ paramspider/
  │               └─ subdomain.txt
  └─ example.org/
        └─ ...
```

**subs.txt**: Raw subdomains obtained from subfinder.
**asset.txt**: Raw subdomains obtained from assetfinder.
**subdomains.txt**: Consolidated list of unique subdomains.
**livesubdomains.txt**: List of active/live subdomains.
**paramspider**: Directory containing ParamSpider output files (if ParamSpider option is selected).
**eyewitness_report**: Directory containing Eyewitness report files (if screenshots option is selected).

## Disclaimer
This script is provided as-is and without any warranty. Use it at your own risk and ensure compliance with applicable laws and regulations. The authors and contributors of this script are not responsible for any misuse or damage caused.
