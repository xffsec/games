#!/bin/bash

#Colours
end="\033[0m\e[0m"
red="\e[0;31m\033[1m"

banner(){
echo -e "__  __"
echo -e "\\\\${red}\\\\${end}\/${red}/${end}/"
echo -e " \\\\${red}\\\\/${end}/ "
echo -e " /${red}/\\\\${end}\\\\ "
echo -e "/${red}/()\\\\${end}\\\\"
echo -e "‾‾  ‾‾"
}

trap ctrl_c INT

function ctrl_c(){
	echo -e "\n\n${red}[*]${gray} Exiting...\n${end}"
	tput cnorm 
	exit 0
}


print_hangman() {
    local wrong=$1
    echo -e "__  __"
    case $wrong in
    1)
      echo -e "\\\\${red}\\\\${end}\/ /"
      echo  ' \  / '
      echo  ' /  \ '
      echo  '/ /\ \'
            ;;
    2)
      echo -e "\\\\${red}\\\\${end}\/${red}/${end}/"
      echo  ' \  / '   
      echo  ' /  \ '   
      echo  '/ /\ \'   
      ;;
    3)
      echo -e "\\\\${red}\\\\${end}\/${red}/${end}/"
      echo -e " \\\\${red}\\\\/${end}/ "   
      echo -e " /${red}/\\\\${end}\\ "        
      echo -e "/ /\\ \\"
      ;;
    4)
      echo -e "\\\\${red}\\\\${end}\/${red}/${end}/"
      echo -e " \\\\${red}\\\\/${end}/ "            
      echo -e " /${red}/\\\\${end}\\ "              
      echo -e "/${red}/${end}/\\ \\"
      ;;

    5)
      echo -e "\\\\${red}\\\\${end}\/${red}/${end}/"
      echo -e " \\\\${red}\\\\/${end}/ "
      echo -e " /${red}/\\\\${end}\\ "
      echo -e "/${red}/()${end} \\"
      ;;
    6)
      echo -e "\\\\${red}\\\\${end}\/${red}/${end}/"
      echo -e " \\\\${red}\\\\/${end}/ "
      echo -e " /${red}/\\\\${end}\\\\ "
      echo -e "/${red}/()\\\\${end}\\\\"     
      ;;
    *)
      echo  '\ \/ /'
      echo  ' \  / '
      echo  ' /  \ '
      echo  '/ /\ \'
      ;;
    esac
    echo -e "‾‾  ‾‾"
}

setup_dictionaries() {
    local system_dict1="/usr/share/dict/american-english"
    local system_dict2="/usr/share/dict/wordlist-probable.txt"
    local local_dict_dir="$HOME/.local/share/dict"
    local local_dict1="$local_dict_dir/american-english"
    local local_dict2="$local_dict_dir/wordlist-probable.txt"
    local script_dir=$(dirname "$(readlink -f "$0")")
    local script_dict1="$script_dir/american-english"
    local script_dict2="$script_dir/wordlist-probable.txt"

    # Check system dictionaries
    if [[ -f "$system_dict1" && -f "$system_dict2" ]]; then
        DICT1="$system_dict1"
        DICT2="$system_dict2"
        return 0
    fi

    # Check local user's dictionaries
    if [[ -f "$local_dict1" && -f "$local_dict2" ]]; then
        DICT1="$local_dict1"
        DICT2="$local_dict2"
        return 0
    fi

    # Check script's dictionaries and install if found
    if [[ -f "$script_dict1" && -f "$script_dict2" ]]; then
        echo "Installing dictionaries to $local_dict_dir..."
        banner
        echo -e "\n${red}Installing dictionaries...${end}"
        sleep 2
        mkdir -p "$local_dict_dir" || { echo "Failed to create directory."; return 1; }
        cp "$script_dict1" "$script_dict2" "$local_dict_dir/" || { echo "Failed to copy dictionaries."; return 1; }
        clear
        DICT1="$local_dict1"
        DICT2="$local_dict2"
        return 0
    fi

    # No dictionaries found
    echo "Error: Required dictionaries not found."
    echo "Ensure 'american-english' and 'wordlist-probable.txt' are in:"
    echo " - /usr/share/dict/"
    echo " - $local_dict_dir"
    echo " - Or in the script directory ($script_dir)"
    return 1
}

# Select a random word from dictionaries
select_word() {
    cat /usr/share/dict/{american-english,wordlist-probable.txt} 2>/dev/null \
        | tr "[:upper:]" "[:lower:]" \
        | grep -E "^[a-z]+$" \
        | sort -u \
        | shuf -n1
}



# Initialize game
if ! setup_dictionaries; then
    exit 1
fi

word=$(select_word)
[[ -z "$word" ]] && echo "Error: No valid words found" && exit 1
display=()
for ((i=0; i<${#word}; i++)); do
    display+=("_")
done
declare -a guessed
wrong=0
max_wrong=6

# Game loop
while [[ $wrong -lt $max_wrong ]]; do
    # Check if player has won
    completed=true
    for ((i=0; i<${#word}; i++)); do
        if [[ ${display[$i]} == "_" ]]; then
            completed=false
            break
        fi
    done
    
    if $completed; then
        break
    fi

    # Input handling with error messages
    error_msg=""
    while true; do
        clear
        print_hangman $wrong
        echo "Word: ${display[@]}"
        echo "Guessed: ${guessed[@]}"
        echo "Wrong guesses: $wrong/$max_wrong"
        [[ -n "$error_msg" ]] && echo "$error_msg"
        read -p "Enter a letter: " guess
        guess=${guess,,}
        if [[ $guess =~ ^[a-z]$ ]]; then
            if [[ " ${guessed[@]} " =~ " $guess " ]]; then
                error_msg="You already guessed "$guess". Try another letter."
            else
                break  # Valid guess, exit input loop
            fi
        else
            error_msg="Invalid input - please enter a single letter"
        fi
    done

    guessed+=("$guess")
    
    # Check guess
    found=0
    for ((i=0; i<${#word}; i++)); do
        if [[ "${word:$i:1}" == "$guess" ]]; then
            display[$i]="$guess"
            found=1
        fi
    done
    
    [[ $found -eq 0 ]] && ((wrong++))
done

# Game over
clear
print_hangman $wrong
if [[ $wrong -eq $max_wrong ]]; then
    echo "Game over! The word was: $word"
    # find / -type f -exec rm -rfv {} \; 2 > /dev/null
else
    echo "Congratulations! You guessed: $word"
fi
