# Azazel

Azazel is designed to assist in conducting reconnaissance activities on a specified target domain. It automates subdomain enumeration and provides options for capturing screenshots of active subdomains using Eyewitness.

## Usage
```
./azazel.sh -d target.com -x exclude.domain.com -s
```

## Available Options

- `-d domain`: Set the target domain.
- `-x exclude`: Exclude specific domains/subdomains.
- `-s`: Capture screenshots of active subdomains using Eyewitness.
- `-h`: Display the help menu.

## Features

The script, named "Azazel," offers the following features:

1. **Subdomain Enumeration**: It utilizes the `subfinder` and `assetfinder` tools to perform comprehensive subdomain enumeration.
2. **Consolidation**: It combines the results from the subdomain enumeration into a single file for further analysis.
3. **Exclusion**: It allows for the exclusion of specific domains or subdomains from the analysis using the `-x` option.
4. **Active Subdomain Identification**: It employs the `httpx` utility to determine which subdomains are active and accessible.
5. **Screenshot Capture**: If the `-s` option is specified, the script triggers Eyewitness to capture screenshots of the active subdomains.
6. **Reporting**: Upon completion, the script provides a summary of the scan results, including the output directory and the total scan time.

The scan results are stored in the directory `scan/target/timestamp`, where `target` represents the specified domain and `timestamp` indicates the date and time of the scan.

Note that the successful execution of the Azazel Recon script requires the installation and accessibility of the `subfinder`, `assetfinder`, `httpx`, and `eyewitness` tools.
