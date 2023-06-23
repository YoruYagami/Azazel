#!/bin/bash

# Function to display the help menu
display_help() {
    echo "Usage: $0 [options]"
    echo
    echo "   -d domains    Set the target domains. This can be a single domain, a"
    echo "                 comma-separated list of domains, or a path to a file with"
    echo "                 one domain per line."
    echo "   -x exclude    Exclude specific domains/subdomains."
    echo "   -s            Capture screenshots on live subdomains."
    echo "   -p            Use ParamSpider for discovering parameters on live subdomains."
    echo "   -h            Display this help menu."
    echo
}

# Variables to decide if screenshots should be taken and if ParamSpider should be used
screenshots=false
use_paramspider=false

while getopts "hd:x:sp" opt; do
  case $opt in
    h)
      display_help
      exit 0
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
    s)
      screenshots=true
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

timestamp=$(date '+%Y%m%d%H%M')
output_dir="scan/$target/$timestamp"
mkdir -p $output_dir

start_time=$(date +%s)

# Subdomain Enumeration
subfinder -d $targets -o $output_dir/subs.txt
assetfinder -subs-only $targets > $output_dir/asset.txt

# Consolidating All Enumerated/Collected subdomains into one file
cat $output_dir/subs.txt $output_dir/asset.txt | sort -u > $output_dir/subdomains.txt

# Remove the individual subs.txt and asset.txt files
rm $output_dir/subs.txt
rm $output_dir/asset.txt

# Exclude specific domains/subdomains
if [ ! -z "$exclude" ]; then
  if [ -f "$exclude" ]; then
    while read line
    do
      grep -v $line $output_dir/subdomains.txt > $output_dir/subdomains_filtered.txt
      mv $output_dir/subdomains_filtered.txt $output_dir/subdomains.txt
    done < $exclude
  else
    grep -v $exclude $output_dir/subdomains.txt > $output_dir/subdomains_filtered.txt
    mv $output_dir/subdomains_filtered.txt $output_dir/subdomains.txt
  fi
fi

# Checking which subdomains are active
httpx -l $output_dir/subdomains.txt -threads 200 -o $output_dir/livesubdomains.txt

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
  done < $output_dir/livesubdomains.txt
fi

# If screenshots option is selected, run Eyewitness
if $screenshots ; then
  eyewitness --web -f $output_dir/livesubdomains.txt -d $output_dir/eyewitness_report --no-prompt
fi

end_time=$(date +%s)
runtime=$((end_time-start_time))

echo "Scan completed for $targets"
echo "Results are located at $output_dir"
echo "Total scan time: $runtime seconds"
