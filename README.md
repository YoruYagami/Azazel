⚠️ Azazel is currently in its early release stage. Numerous additional tools will be incorporated in the future, along with enhancements to the user interface and the introduction of compatibility for arch-based environments.

# Azazel

Azazel is a bash script designed to automate the discovery of vulnerabilities and security issues in web applications. It utilizes different spidering tools (paramspider or katana) and pattern matching techniques to gather information and identify potential risks.

## Table of Contents

- [Options](#options)
- [Usage](#usage)
- [Installation](#installation)
- [Ouput](#output)
- [Disclaimer](#disclaimer).
- [License](#license)

## Options
```bash
Usage: ./azazel.sh [./azazel.sh -d https://target.com -k --krl 2 -t ~/fuzzing-templates/ --nrl 5 --proxy http://127.0.0.1:8080]

Options:
  -p                 Use ParamSpider (default)
  -k                 Use Katana
  -n                 Perform an initial scan with Nikto
  -d                 Specify the target domain
  -t                 Use Nuclei with a specific template
  --nrl              Set Nuclei rate limit (e.g., --nrl 10, default is 150)
  --krl              Set Katana rate limit (e.g., --krl 10, default is 150)
  --proxy            Set proxy for selected tools (e.g., --proxy http://127.0.0.1:8080)
  -h                 Display this help message

Available spider tools: paramspider, katana

```

## Usage

```bash
     ~/hacking/github/Azazel  on    main +2 !1  ./azazel.sh -d "http://testphp.vulnweb.com/" -k --krl 50 -t ~/fuzzing-templates/xss/reflected-xss.yaml --nrl 5 --proxy http://127.0.0.1:8080                                           ✔                                                                   
                                                                                                                                                                                                                                                                                                                     
[-] /robots.txt not found.                                                                                                                                                                                                                                                                                           
                                                                                                                                                                                                                                                                                                                     
[-] /sitemap.xml not found.                                                                                                                                                                                                                                                                                          
                                                                                                                                                                                                                                                                                                                     
[+] Target vulnerable to Clickjacking!.                                                                                                                                                                                                                                                                              
                                                                                                                                                                                                                                                                                                                     
[+] HttpOnly flag is missing from the cookie!.                                                                                                                                                                                                                                                                       
                                                                                                                                                                                                                                                                                                                     
[+] Content-Security-Policy (CSP) header is missing!.                                                                                                                                                                                                                                                                
                                                                                                                                                                                                                                                                                                                     
[ ! ] Executing katana, please wait...                                                                                                                                                                                                                                                                               
                                                                                                                                                                                                                                                                                                                     
   __        __                                                                                                                                                                                                                                                                                                      
  / /_____ _/ /____ ____  ___ _                                                                                                                                                                                                                                                                                      
 /  '_/ _  / __/ _  / _ \/ _  /                                                                                                                                                                                                                                                                                      
/_/\_\\_,_/\__/\_,_/_//_/\_,_/                                                                                                                                                                                                                                                                                       
                                                                                                                                                                                                                                                                                                                     
                projectdiscovery.io                                                                                                                                                                                                                                                                                  
                                                                                                                                                                                                                                                                                                                     
[INF] Current katana version v1.0.3 (latest)                                                                                                                                                                                                                                                                         
[INF] Started standard crawling for => http://testphp.vulnweb.com/                                                                                                                    
http://testphp.vulnweb.com/cart.php                                          
http://testphp.vulnweb.com/userinfo.php                                      
http://testphp.vulnweb.com/disclaimer.php                                    
http://testphp.vulnweb.com/index.php                                         
http://testphp.vulnweb.com/signup.php                                        
http://testphp.vulnweb.com/categories.php                                    
http://testphp.vulnweb.com/artists.php                                       
http://testphp.vulnweb.com/AJAX/styles.css                                   
http://testphp.vulnweb.com/hpp/params.php?p=valid&pp=12                      
http://testphp.vulnweb.com/Mod_Rewrite_Shop/Details/web-camera-a4tech/2/                                                                                  
http://testphp.vulnweb.com/Mod_Rewrite_Shop/Details/color-printer/3/                                                                                      
http://testphp.vulnweb.com/Mod_Rewrite_Shop/Details/network-attached-storage-dlink/1/                                                                     
http://testphp.vulnweb.com/listproducts.php?cat=4                            
http://testphp.vulnweb.com/artists.php?artist=1                              
http://testphp.vulnweb.com/Mod_Rewrite_Shop/BuyProduct-1/                    
http://testphp.vulnweb.com/Mod_Rewrite_Shop/BuyProduct-2/                    
http://testphp.vulnweb.com/Mod_Rewrite_Shop/RateProduct-1.html                                                                                            
http://testphp.vulnweb.com/Mod_Rewrite_Shop/BuyProduct-3/                    
http://testphp.vulnweb.com/Mod_Rewrite_Shop/RateProduct-3.html                                                                                            
http://testphp.vulnweb.com/artists.php?artist=2                              
http://testphp.vulnweb.com/Mod_Rewrite_Shop/RateProduct-2.html                                                                                            
http://testphp.vulnweb.com/artists.php?artist=3                              
http://testphp.vulnweb.com/listproducts.php?cat=3                            
http://testphp.vulnweb.com/listproducts.php?cat=2                            
...                

Count of potential vulnerable URLs discovered:                               

Vulnerability   URLs discovered                                              
-------------   ---------------                                              
lfi             18                                                           
redirect        14                                                           
ssrf            14                                                           
xss             2                                                            

JavaScript files discovered: 0      
                                        
[ ! ] Executing nuclei with template /home/kali/fuzzing-templates/xss/reflected-xss.yaml, please wait...                                                  

                     __     _                                                
   ____  __  _______/ /__  (_)                                               
  / __ \/ / / / ___/ / _ \/ /                                                
 / / / / /_/ / /__/ /  __/ /                                                 
/_/ /_/\__,_/\___/_/\___/_/   v2.9.10                                        

                projectdiscovery.io                                          

[INF] Current nuclei version: v2.9.10 (latest)                               
[INF] Current nuclei-templates version: v9.6.0 (latest)                      
[INF] New templates added in latest release: 33                              
[INF] Templates loaded for current scan: 1                                   
[INF] Targets loaded for current scan: 18                                    
[reflected-xss] [http] [medium] http://testphp.vulnweb.com/listproducts.php?cat=4'"><30358                                                                
[reflected-xss] [http] [medium] http://testphp.vulnweb.com/listproducts.php?cat=1'"><30358                                                                
[reflected-xss] [http] [medium] http://testphp.vulnweb.com/listproducts.php?cat=3'"><30358                                                                
[reflected-xss] [http] [medium] http://testphp.vulnweb.com/listproducts.php?cat=2'"><30358                                                                


```
## Key Features
1. Parameter Parsing: The script accepts a range of command-line arguments that specify the desired action, such as target domain and scanning tools to use.
2. Multi-tool Integration: Incorporates various popular web scanning tools
3. Additional Checks: The script also has built-in functionalities to check for the presence of "robots.txt", "sitemap.xml", and specific HTTP headers.
4. Output Management: All scan results are organized and saved in timestamped directories for easier access.
5. Visualization: Displays a count of potential vulnerable URLs discovered in a table-like format.
6. Proxy Support: The script can use a proxy for the scanning, enhancing the user's privacy and ability to bypass certain access controls.

## Installation
1. Clone this repository to your local machine:
```bash
git clone https://github.com/your-username/azazel.git
cd azazel
```
2. Make the script and the installation executable:
```bash
chmod +x install.sh && chmod +x azazel.sh
```
3. Run the installation script:
```bash
./install.sh
```

4. Run the script with appropriate options and target domain:
```bash
./azazel.sh -d https://target.com -k --krl 2 -t ~/fuzzing-templates/ --nrl 5 --proxy http://127.0.0.1:8080
```

## Output
The script will create a directory named scan with a subdirectory for each target domain and a timestamped subdirectory for each scan. The output directory structure will be as follows:

```
scan
└── http:
    └── testphp.vulnweb.com
        └── 202308111034
            ├── getjs_output.txt
            ├── nuclei_results.txt
            ├── paramspider
            │   └── vuln
            │       ├── gf_lfi.txt
            │       ├── gf_redirect.txt
            │       ├── gf_ssrf.txt
            │       └── gf_xss.txt
            └── urls.txt

6 directories, 7 files
```

## Disclaimer
This script is provided as-is and without any warranty. Use it at your own risk and ensure compliance with applicable laws and regulations. The authors and contributors of this script are not responsible for any misuse or damage caused.

## License
This project is licensed under the MIT License.

Feel free to contribute, open issues, and provide feedback.
