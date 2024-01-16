⚠️ Azazel is currently in its early release stage. Numerous additional tools will be incorporated in the future, along with enhancements to the user interface and the introduction of compatibility for arch-based environments.

# Azazel 

This bash script automates the process of finding new subdomains and analyzing them in loop.

## Features
- **Multiple Tools Integration**: Uses `assetfinder`, `findomain`, and `subfinder` for comprehensive subdomain discovery.
- **Unique Sorting**: Combines and sorts results from all tools to avoid duplicates.
- **Customizable Loop Time**: Re-run the script at specified intervals.
- **Silent Mode**: Option to run in a less verbose mode.
- **Notification Support**: Notifies you discord/telegram/etc.. when new subdomains are discovered.
- **Nuclei Integration**: Optional scanning of new subdomains using Nuclei with custom templates.

## Options
- **-f, --file** : Specify domain file to process.
- **--loop** : Time in seconds to wait before re-running (default: 3600).
- **-o, --output** : Specify output file for results (default: subdomains.txt).
- **-x, --exclude** : File with subdomains to exclude.
- **--silent** : Run in silent mode.
- **--notify** : Enable notifications for new subdomains.
- **-n, --nuclei** : Run nuclei against new subdomains.
- **-t, --template** : Nuclei templates path (default: ~/nuclei-templates).

## Examples
```
./your_script_name.sh -f domains.txt --loop 3600 --output results.txt
./your_script_name.sh -f domains.txt --silent --notify --nuclei -t ~/nuclei-templates
```

## Dependecies
Ensure you have the following tools installed:

- assetfinder
- findomain
- subfinder
- httpx
- anew
- nuclei

## Contributing
Contributions, issues, and feature requests are welcome. Please check the issues page before opening a new one.
