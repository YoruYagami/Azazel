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
./azazel.sh -p "http://testphp.vulnweb.com/"                                                                                    ✔    

[ ! ] Executing paramspider, please wait...


         ___                               _    __       
        / _ \___ ________ ___ _  ___ ___  (_)__/ /__ ____
       / ___/ _ `/ __/ _ `/  ' \(_-</ _ \/ / _  / -_) __/
      /_/   \_,_/_/  \_,_/_/_/_/___/ .__/_/\_,_/\__/_/   
                                  /_/                    
                            
                            - coded with <3 by Devansh Batham 
    

[+] Total number of retries:  0
[+] Total unique urls found : 108
[+] Output is saved here : scan/http://testphp.vulnweb.com//202308091233/parameter.txt

[!] Total execution time      : 1.9762s

Count of potential vulnerable URLs discovered:

Vulnerability   URLs discovered          
-------------   ---------------          
lfi             34                       
redirect        17                       
sqli            19                       
ssrf            20                       
ssti            18                       
xss             32                       
idor            17                       
debug_logic     3                        

JavaScript files discovered: 0

[+] Scan complete. Results saved in scan/http://testphp.vulnweb.com//202308091233
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
2. Make the script and the installation executable:
```bash
chmod +x azazel.sh
chmod +x install.sh
```
3. Run the installation script:
```bash
./install.sh
```

4. Run the script with appropriate options and target domain:
```bash
./azazel.sh -p example.com
```

## Output
The script will create a directory named scan with a subdirectory for each target domain and a timestamped subdirectory for each scan. The output directory structure will be as follows:

```
scan
└── http:
    └── testphp.vulnweb.com
        └── 202308091233
            ├── getjs_output.txt
            ├── parameter.txt
            └── paramspider
                └── vuln
                    ├── gf_debug_logic.txt
                    ├── gf_idor.txt
                    ├── gf_lfi.txt
                    ├── gf_redirect.txt
                    ├── gf_sqli.txt
                    ├── gf_ssrf.txt
                    ├── gf_ssti.txt
                    └── gf_xss.txt

6 directories, 10 files
```

## Disclaimer
This script is provided as-is and without any warranty. Use it at your own risk and ensure compliance with applicable laws and regulations. The authors and contributors of this script are not responsible for any misuse or damage caused.

## License
This project is licensed under the MIT License.

Feel free to contribute, open issues, and provide feedback.
