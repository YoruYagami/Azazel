#!/bin/bash

# Function to display the help menu
display_help() {
    echo "Usage: $0 [options]"
    echo
    echo "   -d domains    Set the target domains. This can be a single domain, a"
    echo "                 comma-separated list of domains, or a path to a file with"
    echo "                 one domain per line."
    echo "   -x exclude    Exclude specific domains/subdomains."
    echo "   -e            Perform subdomain enumeration."
    echo "   -p            Use ParamSpider for discovering parameters on live subdomains."
    echo "   -h            Display this help menu."
    echo
}

# Variables to decide if screenshots should be taken and if ParamSpider should be used
use_paramspider=false
perform_enum=false

while getopts "hed:x:p" opt; do
  case $opt in
    h)
      display_help
      exit 0
      ;;
    e)
      perform_enum=true
      ;;
    d)
      if [ -f "$OPTARG" ]; then
        mapfile -t targets < $OPTARG
      else
        IFS=',' read -ra targets <<< "$OPTARG"
      fi
      ;;
    x)
      exclude=$OPTARG
      ;;
    p)
      use_paramspider=true
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      display_help
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      display_help
      exit 1
      ;;
  esac
done

# Debug line:
echo "Target domains: ${targets[@]}"

if [ -z "${targets[*]}" ]; then
  echo "Please specify the target domain using the -d option."
  exit 1
fi

start_time=$(date +%s)

# Loop over each target domain
for target in "${targets[@]}"; do

  timestamp=$(date '+%Y%m%d%H%M')
  output_dir="scan/$target/$timestamp"
  mkdir -p $output_dir

  # Check if -e option is selected, then perform enumeration
  if $perform_enum ; then
    # Subdomain Enumeration
    subfinder -d $target -o $output_dir/subs.txt
    assetfinder -subs-only $target > $output_dir/asset.txt

    # Consolidating All Enumerated/Collected subdomains into one file
    cat $output_dir/subs.txt $output_dir/asset.txt | sort -u > $output_dir/subdomains.txt
    
    # Checking which subdomains are active
    httpx -l $output_dir/subdomains.txt -threads 200 -title -status-code -o $output_dir/sub_statuscode_title.txt

    # Extract only domains and save to another file
    awk '{print $1}' $output_dir/sub_statuscode_title.txt | sed -e 's/https\?:\/\///' | sed -e 's/\/.*$//' > $output_dir/livesubdomains.txt

    # Remove the individual subs.txt and asset.txt files
    rm $output_dir/subs.txt
    rm $output_dir/asset.txt
    rm $output_dir/subdomains.txt

  fi

  # If ParamSpider option is selected, run ParamSpider on each live subdomain
  if $use_paramspider ; then
    # Check if ParamSpider is already cloned
    home_dir="$HOME"
    if [ ! -d "$home_dir/ParamSpider" ]; then
      echo "Cloning ParamSpider..."
      git clone https://github.com/devanshbatham/ParamSpider.git "$home_dir/ParamSpider"
    fi
    
    # Create a directory for ParamSpider output
    paramspider_output_dir="$output_dir/paramspider"
    mkdir -p $paramspider_output_dir
    
    # Run ParamSpider on each live subdomain
    while read -r subdomain; do
      echo "Running ParamSpider on $subdomain"
      python3 "$home_dir/ParamSpider/paramspider.py" -d "$subdomain" --exclude png,jpg,gif,jpeg,swf,woff,gif,svg --level high --quiet -o "$paramspider_output_dir/$subdomain.txt"
      
      # Use gf to find common patterns in http
      if [ -d "$paramspider_output_dir/http:" ]; then
        mkdir -p "$paramspider_output_dir/http:/vuln"
        if ls $paramspider_output_dir/http:/*.txt > /dev/null 2>&1; then
          for pattern in lfi rce redirect sqli ssrf ssti xss idor; do
            cat $paramspider_output_dir/http:/*.txt | gf $pattern > "$paramspider_output_dir/http:/vuln/gf_${pattern}.txt"
          done
        fi
      fi

      # Use gf to find common patterns in https
      if [ -d "$paramspider_output_dir/https:" ]; then
        mkdir -p "$paramspider_output_dir/https:/vuln"
        if ls $paramspider_output_dir/https:/*.txt > /dev/null 2>&1; then
          for pattern in lfi rce redirect sqli ssrf ssti xss idor; do
            cat $paramspider_output_dir/https:/*.txt | gf $pattern > "$paramspider_output_dir/https:/vuln/gf_${pattern}.txt"
          done
        fi
      fi
    done < $output_dir/livesubdomains.txt
  fi
done

end_time=$(date +%s)
runtime=$((end_time-start_time))

echo "Scan completed for ${targets[@]}"
echo "Total scan time: $runtime seconds"
