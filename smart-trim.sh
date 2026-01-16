#!/usr/bin/env bash
set -euo pipefail

## Defaults
keepGensDef=30
keepDaysDef=30
keepGens=$keepGensDef
keepDays=$keepDaysDef
profile="/nix/var/nix/profiles/system"

## Usage
usage () {
    printf "Usage:\n\t sudo %s <keep-generations> <keep-days>\n\n" "$0"
    printf "(defaults are: Keep-Gens=%s Keep-Days=%s)\n\n" "$keepGensDef" "$keepDaysDef"
    printf "If you enter any parameters, you must enter both, or none to use defaults.\n"
    printf "Example:\n\t sudo %s 15 10\n" "$0"
    printf "  this will work on the system profile and keep all generations from the\n"
    printf "last 10 days, and keep at least 15 generations no matter how old.\n"
    printf "\nThis script ONLY supports the NixOS system profile and must be run as root.\n"
    printf "\n-h or --help prints this help text.\n"
}

if [ $# -eq 1 ]; then
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
         usage
         exit 0
    fi
    printf "Unrecognized option. Exiting..\n\n"
    usage
    exit 3
elif [ $# -eq 0 ]; then
    printf "The current defaults are:\n Keep-Gens=%s Keep-Days=%s \n\n" "$keepGensDef" "$keepDaysDef"
    read -p "Keep these defaults? (y/n): " answer

    case "$answer" in
    [yY1] )
        printf "Using defaults..\n"
        ;;
    [nN0] )
        printf "Ok, doing nothing. Exiting..\n"
        exit 6
        ;;
    * )
        printf "Doing nothing. Exiting..\n"
        exit 7
        ;;
    esac
fi

## Check Root
if [[ $EUID -ne 0 ]]; then
   printf "Error: This script must be run as root to modify the system profile.\n"
   printf "Please run with sudo.\n"
   exit 1
fi

## Handle parameters
if (( $# >= 2 )); then
    keepGens=$1
    keepDays=$2
    
    if [[ $1 -lt 1 ]]; then
         keepGens=1
         printf "Warning: Setting keepGens to minimum 1.\n"
    fi
    if [[ $2 -lt 0 ]]; then
         keepDays=0
         printf "Warning: Setting keepDays to minimum 0.\n"
    fi
fi

if [[ ! -d "$profile" ]]; then
    printf "Error: System profile not found at %s\n" "$profile"
    printf "Are you running NixOS?\n"
    exit 1
fi

printf "Operating on profile: \t %s\n" "$profile"
printf "Parameters: \t\t Keep Gens = %s \t Keep Days = %s\n\n" "$keepGens" "$keepDays"

## Query nix-env
# Capture output, strip leading/trailing whitespace, squeeze tabs/spaces
IFS=$'\n' nixGens=( $(nix-env --list-generations -p "$profile" | sed 's:^\s*::; s:\s*$::' | tr '\t' ' ' | tr -s ' ') )

if [ ${#nixGens[@]} -eq 0 ]; then
    printf "No generations found for profile: %s\n" "$profile"
    exit 0
fi

timeNow=$(date +%s)
currentGen=0
declare -a gensToDelete

# First pass: Identify current generation
for i in "${nixGens[@]}"; do
    # Format: ID Date Time (current)
    IFS=' ' read -r -a iGenArr <<< "$i"
    genNumber=${iGenArr[0]}
    genDate=${iGenArr[1]}
    
    if [[ "$i" =~ \(current\) ]]; then
        currentGen=$genNumber
        currentDate=$genDate
    fi
done

if [[ $currentGen -eq 0 ]]; then
    printf "Could not determine current generation explicitly. Assuming the last one listed is active.\n"
    # Fallback to the last one in the list
    IFS=' ' read -r -a lastGenArr <<< "${nixGens[-1]}"
    currentGen=${lastGenArr[0]}
    currentDate=${lastGenArr[1]}
fi

printf "Current generation: %s (%s)\n" "$currentGen" "$currentDate"

# Second pass: Identify generations to delete
for i in "${nixGens[@]}"; do
    IFS=' ' read -r -a iGenArr <<< "$i"
    genNumber=${iGenArr[0]}
    genDate=${iGenArr[1]}
    
    # Calculate age in days
    genTime=$(date -d "$genDate" +%s)
    elapsedSecs=$((timeNow-genTime))
    genDaysOld=$((elapsedSecs/86400))
    
    # Check if this generation is the current one
    if [[ "$genNumber" -eq "$currentGen" ]]; then
        continue
    fi
    
    genDiff=$((currentGen - genNumber))
    
    # Logic: Delete ONLY if (Old enough) AND (Far enough back)
    # This ensures we keep:
    # 1. Any generation newer than keepDays.
    # 2. The last keepGens generations, regardless of age.
    # Note: If genNumber > currentGen (future/rollback), genDiff is negative, so it won't be deleted.
    if [[ $genDaysOld -gt $keepDays ]] && [[ $genDiff -ge $keepGens ]]; then
        gensToDelete+=("$genNumber")
        # verbose output optional:
        # printf "Marking gen %s: %s days old, %s gens behind.\n" "$genNumber" "$genDaysOld" "$genDiff"
    fi
done

if [ ${#gensToDelete[@]} -eq 0 ]; then
    printf "\nNothing to trim.\n"
else
    printf "\nFound %d generation(s) eligible for deletion.\n" "${#gensToDelete[@]}"
    
    read -p "Do you want to delete these? [y/N]: " answer
    case "$answer" in
        [yY1] )
            nix-env --delete-generations -p "$profile" "${gensToDelete[@]}"
            ;;
        * )
            printf "Aborting trim.\n"
            exit 0
            ;;
    esac
fi

# GC Step
printf "\n"
read -p "Run garbage collection (nix-collect-garbage) to free disk space from deleted generations? [y/N]: " gc_answer
case "$gc_answer" in
    [yY1] )
        printf "Running garbage collection...\n"
        nix-collect-garbage
        ;;
    * )
        printf "Skipping garbage collection.\n"
        ;;
esac

exit 0
