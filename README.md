⚠️ Azazel is currently in its early release stage. Numerous additional tools will be incorporated in the future, along with enhancements to the user interface and the introduction of compatibility for arch-based environments.

# Azazel

Azazel is a bash script used for domain enumeration and parameter discovery. It uses tools like Subfinder, Assetfinder, httpx and ParamSpider to perform various tasks.

## Features

- Performs domain enumeration and parameter discovery.
- Supports excluding specific domains/subdomains.
- The results are stored in an organized manner in the 'scan' directory.

## Usage
```
./azazel.sh -d target.com -x exclude.domain.com -e -p
```

## Options
```
./azazel.sh [options]

Options:
   -d domains    Set the target domains. This can be a single domain, a
                 comma-separated list of domains, or a path to a file with
                 one domain per line.
   -x exclude    Exclude specific domains/subdomains.
   -e            Perform subdomain enumeration.
   -p            Use ParamSpider for discovering parameters on live subdomains.
   -h            Display this help menu.
```

## Prerequisites
- subfinder
- assetfinder
- httpx
- ParamSpider

Make sure you have the necessary tools installed and available in your system before running this script.

## Options

**-d domains**: Set the target domains. This can be a single domain or a path to a file with one domain per line.

**-x exclude**: Exclude specific domains/subdomains.

**-p**: Use ParamSpider for discovering parameters on live subdomains.

**-h**: Display the help menu.

## Examples

Perform subdomain enumeration on a single domain:
```
./azazel.sh -d example.com -e
```

Perform subdomain enumeration using a file with domains:
```
./azazel.sh -d domains.txt -e
```
Exclude specific domains/subdomains:
```
./azazel.sh -d example.com -x excluded.txt -e
```

Use ParamSpider for discovering parameters on direct domain:
```
./azazel.sh -d example.com -p
```

Perform subdomain enumeration + paramspider using a file with domains:
```
./azazel.sh -d domains.txt -e -p
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

## Disclaimer
This script is provided as-is and without any warranty. Use it at your own risk and ensure compliance with applicable laws and regulations. The authors and contributors of this script are not responsible for any misuse or damage caused.
