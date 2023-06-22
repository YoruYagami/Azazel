#!/bin/bash

# Function to display the help menu
display_help() {
    echo "Usage: $0 [options]"
    echo
    echo "   -d domain     Set the target domain."
    echo "   -x exclude    Exclude specific domains/subdomains."
    echo "   -s            Capture screenshots of active subdomains with Eyewitness."
    echo "   -h            Display this help menu."
    echo
}

# Variable to decide if screenshots should be taken
screenshots=false

# Step 1: The Skeleton
while getopts "hd:x:s" opt; do
  case $opt in
    h)
      display_help
      exit 0
      ;;
    d)
      target=$OPTARG
      ;;
    x)
      exclude=$OPTARG
      ;;
    s)
      screenshots=true
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

if [ -z "$target" ]; then
  echo "Please specify the target domain using the -d option."
  exit 1
fi

timestamp=$(date '+%Y%m%d%H%M')
output_dir="scan/$target/$timestamp"
mkdir -p $output_dir

start_time=$(date +%s)

# Subdomain Enumeration
subfinder -d $target -o $output_dir/subs.txt
assetfinder -subs-only $target > $output_dir/asset.txt

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
httpx -l $output_dir/subdomains.txt -o $output_dir/activesubs.txt

# If screenshots option is selected, run Eyewitness
if $screenshots ; then
  eyewitness --web -f $output_dir/activesubs.txt -d $output_dir/eyewitness_report --no-prompt
fi

end_time=$(date +%s)
runtime=$((end_time-start_time))

echo "Scan completed for $target"
echo "Results are located at $output_dir"
echo "Total scan time: $runtime seconds"
