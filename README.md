⚠️ Azazel is currently in its early release stage. Numerous additional tools will be incorporated in the future, along with enhancements to the user interface and the introduction of compatibility for arch-based environments.

# Azazel

Azazel is a versatile bash script designed to help you discover vulnerabilities and potential security issues in web applications using various tools and pattern matching.

## Table of Contents

- [Introduction](#introduction)
- [Usage](#usage)
- [Installation](#installation)
- [Ouput](#output)
- [Disclaimer](#disclaimer).
- [License](#license)

## Introduction

Azazel is a bash script designed to automate the discovery of vulnerabilities and security issues in web applications. It utilizes different spidering tools (paramspider or katana) and pattern matching techniques to gather information and identify potential risks.

## Usage

```bash
./azazel.sh [-p|-k] <target_domain>
```

## Options

```bash
    -p: Use ParamSpider (default)
    -k: Use Katana
    -h: Display help message
```

## Installation
1. Clone this repository to your local machine:
```bash
git clone https://github.com/your-username/azazel.git
cd azazel
```
2. Make the script executable:
```bash
chmod +x azazel.sh
```
3. Run the script with appropriate options and target domain:
```bash
./azazel.sh -p example.com
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

## Disclaimer
This script is provided as-is and without any warranty. Use it at your own risk and ensure compliance with applicable laws and regulations. The authors and contributors of this script are not responsible for any misuse or damage caused.

## License
This project is licensed under the MIT License.

Feel free to contribute, open issues, and provide feedback.
