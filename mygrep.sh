#!/bin/bash

# ==============================================================================
# mygrep.sh - A simple grep-like utility
#
# Searches for PATTERN within FILE case-insensitively.
# Supports -n (line numbers) and -v (invert match) options.
# ==============================================================================

# --- Default values for options ---
show_line_numbers=0 # Flag for -n option
invert_match=0      # Flag for -v option
show_help=0         # Flag for --help option

# --- Usage Function ---
# Displays help message and exits.
usage() {
  # Using cat with heredoc for cleaner multi-line echo
  cat << EOF
Usage: $(basename "$0") [OPTIONS] PATTERN FILE
Search for PATTERN in FILE case-insensitively.

Options:
  -n        Prefix each line of output with the 1-based line number
            within its input file.
  -v        Invert the sense of matching, to select non-matching lines.
  --help    Display this help message and exit.

Arguments:
  PATTERN   The string to search for (case-insensitive).
  FILE      The input text file to search within.

Examples:
  $(basename "$0") hello input.txt       # Find lines containing 'hello'
  $(basename "$0") -n hello input.txt    # Find lines containing 'hello' with line numbers
  $(basename "$0") -nv hello input.txt   # Find lines NOT containing 'hello' with line numbers
EOF
  # Exit with status 0 for --help, as it's informational, not an error.
  exit 0
}

# --- Option Parsing ---

# Check for --help specifically before getopts
if [[ "$1" == "--help" ]]; then
  usage
fi

# Use getopts for standard short options (-n, -v)
# The loop continues as long as getopts finds options listed in "nv"
# ':' after an option would mean it expects an argument (e.g., "f:")
while getopts "nv" opt; do
  case $opt in
    n)
      # Set flag if -n is found
      show_line_numbers=1
      ;;
    v)
      # Set flag if -v is found
      invert_match=1
      ;;
    \?)
      # Handle invalid options provided by the user
      echo "Error: Invalid option: -$OPTARG" >&2 # Output error to stderr
      echo "Run '$(basename "$0") --help' for usage information." >&2
      exit 1 # Exit with error status
      ;;
  esac
done

# Shift the processed options off the argument list.
# OPTIND is the index of the next argument to be processed.
# After the loop, it points to the first non-option argument (PATTERN).
shift $((OPTIND - 1))

# --- Argument Validation ---

# Check if the correct number of non-option arguments (PATTERN and FILE) remain
if [ "$#" -ne 2 ]; then
  if [ "$#" -eq 1 ]; then
      # Specific message if only one argument is left (could be pattern or file)
      echo "Error: Missing search pattern or filename." >&2
      echo "Perhaps you meant to search for '$1' in a file?" >&2
  elif [ "$#" -eq 0 ]; then
      # Specific message if no arguments are left
      echo "Error: Missing search pattern and filename." >&2
  else
      # Generic message for too many arguments
      echo "Error: Too many arguments provided." >&2
  fi
  echo "Run '$(basename "$0") --help' for usage information." >&2
  exit 1 # Exit with error status
fi

# Assign the remaining arguments to variables
pattern="$1"
filename="$2"

# Check if the specified file exists
if [ ! -f "$filename" ]; then
  echo "Error: File '$filename' not found." >&2
  exit 1 # Exit with error status
fi

# Check if the specified file is readable
if [ ! -r "$filename" ]; then
  echo "Error: File '$filename' is not readable. Check permissions." >&2
  exit 1 # Exit with error status
fi

# --- Main Processing Logic ---

line_num=0       # Initialize line counter
match_found=0    # Flag to track if any lines are output (for exit status)
exit_status=1    # Default exit status (1 = no matches/lines selected)

# Read the file line by line
# Using `while IFS= read -r line` is the standard safe way to read lines
# It prevents issues with backslashes and preserves leading/trailing whitespace
while IFS= read -r line || [[ -n "$line" ]]; do # Handle files without trailing newline
  ((line_num++)) # Increment line number for each line read

  # Perform case-insensitive check:
  # ${line,,} converts the line to lowercase (Bash 4.0+)
  # ${pattern,,} converts the pattern to lowercase
  # [[ ... == *pattern* ]] checks if the lowercase pattern is a substring
  # of the lowercase line.
  if [[ "${line,,}" == *"${pattern,,}"* ]]; then
    # Pattern was found in the line
    if [ "$invert_match" -eq 0 ]; then
      # Normal match (-v not specified): Print the line
      if [ "$show_line_numbers" -eq 1 ]; then
        echo "${line_num}:${line}" # Print with line number
      else
        echo "$line"              # Print without line number
      fi
      match_found=1 # Mark that we outputted a line
    fi
  else
    # Pattern was NOT found in the line
    if [ "$invert_match" -eq 1 ]; then
      # Inverted match (-v specified): Print the line
      if [ "$show_line_numbers" -eq 1 ]; then
        echo "${line_num}:${line}" # Print with line number
      else
        echo "$line"              # Print without line number
      fi
      match_found=1 # Mark that we outputted a line
    fi
  fi
done < "$filename" # Redirect the file content into the while loop

# --- Set Exit Status ---
# Mimic grep: exit 0 if any lines were selected (printed), 1 otherwise.
if [ "$match_found" -eq 1 ]; then
  exit_status=0
fi

exit $exit_status

