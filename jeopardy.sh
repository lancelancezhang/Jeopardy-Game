#!/bin/bash
# SOFTENG206 Assignment 1
# author: Lance Zhang
# initialise variables
no_questions=false 
answering=false
catcomplete_count=0

print_opening_board()
{
echo -e "\n==============================================================\nWelcome to Jeopardy!\n==============================================================\nPlease select from one of the following options:"
echo -e "      (p)rint the question board\n      (a)sk a question\n      (v)iew current winnings\n      (r)esetgame\n     e(x)it\n"

# accept input from the user - reset variable for error checking
read -p "Enter a selection [p/a/v/r/x]: " OPENINGINPUT
check_opening_input $UINPUT
}

print_question_board()
{
echo -e "\n==============================================================\nQuestion Board\n==============================================================\n*Categories*"
cat_start_count=1
no_lines=0
local points_pos=0
for category in data/*
do
	# print the category names
	echo "[$cat_start_count]$(basename "$category")"
	# if the category is complete set it as such
	# need to write into a note pad?
	if (( $(wc -l < "$category") == 0 ))
	then
		echo "*COMPLETE*"	
	else
		# print the points for each category
		while read -r line
		do # reads each line
			IFS=','
			read -ra ADDR <<< $line
			for i in "${ADDR[@]}"
			do # splits each line by comma
				((points_pos=$line_num+2))
				if (( $points_pos % 3 == 0 )) # print points
				then
					echo "$i"
				fi
				((line_num=$line_num+1))
			done
		done < "$category"
		((cat_start_count=$cat_start_count+1))
	fi
done
}

check_opening_input()
{
case $OPENINGINPUT in
[pP])
	print_question_board
	any_button_to_continue
	print_opening_board
	;;
[aA])
	ask_question
	;;
[vV])
	view_winnings
	;;
[rR])
	reset_game
	;;
[xX] | [eE])
	exit_game
	;;
*)
	print_opening_board
	;;
esac
}

ask_question()
{
if ("$no_questions")
then
	echo -e "\nThere are no questions left.\nYou must reset the game."
	print_opening_board
else
	print_question_board
	pick_category
	pick_question
	answer_question
	any_button_to_continue
	print_opening_board
fi
}

view_winnings()
{
echo -e "\nYour current winnings are $winnings"
any_button_to_continue
print_opening_board
}

reset_game()
{
echo -e "You are about to reset the game. \nThis means your saved earnings will be reduced to 0"
# error checking make sure user does not accidentally reset their earnings 
read -p "Type 'C' if you would like to reset the game: " RESETINPUT
case $RESETINPUT in
	[Cc])
		# reset all save files
		echo "Your game has been reset"
		
		# remove the data folder with data inside
		rm -r ./data
		# setup the game again - refresh
		set_up
		winnings=0
		no_questions=false
	;;
	*)
		echo "Your game will not be reset"
	;;
esac
print_opening_board
}

exit_game()
{
read -p "Type 'C' if you would like to exit the game: " EXITINPUT
case $EXITINPUT in
	[Cc])
		echo "Thank you for playing. Your progress will be saved."
		# save the game all winnings values
		dir=dat.txt
		echo "$winnings" > "$dir"
	;;
	*)
		echo "Returning back to main menu"
		print_opening_board
	;;
esac
}

any_button_to_continue()
{
# error checking - make sure the user is able to see the question board and move when required
read -p "Press any key to continue: "
}

pick_category()
{
local count=1

read -p "Choose a category to answer - pick a number: " usercatnum
if [[ "$usercatnum" =~ ^[0-9]+$ ]]
then
	# read the file for and read out of the numbers - CHANGE HAS TO BE APPLIED HERE
	if (( $usercatnum <= ($num_categories - 1) )) && (( $usercatnum > 0 ))
		then
			for category in data/*
			do
			# find specific file being used
				if (( $count == $usercatnum ))
				then
				# check if no lines in file - complete category
				# this will be written into a text file and read into with a for loop
					if (( $(wc -l < "$category") == 0 ))
					then
						echo "That category is complete"
						# this is not a good way of checking how many are left
						((catcomplete_count=$catcomplete_count+1))
						# if no questions remaining
						# perhaps need to write from one text file into another one
						# then check like this if everything is done
						if (( $catcomplete_count == $num_categories ))
						then
							echo "You must reset your game. No questions remaining."
							no_questions=true
							print_opening_board
						else
							pick_category
						fi
					fi
				fi
				((count=$count+1))
			done
		else
			echo "That category is invalid"
			pick_category	
	fi
else
	echo "That category is invalid"
	pick_category
fi
}

answer_question()
{
local count=1
local pointspos=1
local calc=0
local answered=true

# here the user answers the questions
read -p "Your Answer: " useranswer
for category in data/*
do
	# if the user gets to their selected category number - check this 
	if (( $count == $usercatnum ))
	then
		while read -r lines2
		do
		# split at the commas
			IFS=','
			read -ra ADDR <<< $lines2
			for k in "${ADDR[@]}"
			do
			# position of the answers?
				((calc=$pointspos+2))
				if (( $calc % 3 == 2  ))
				then
					if [ "$answered" = true ]
					then
					# ignoring case sensitivity checking whether they are the same answer
						if [ "${useranswer,,}" == "${k,,}" ] && [ $pointspos > $pos ]
						# check if user answer correct - if so add points on and remove question if not remove question only
						then
						
							echo -e "\nYou've answered that correctly!\nAwarded $userpointnum points"
							((winnings=$winnings+$userpointnum))
							# removing from the category from the text file
							sed -i ''$(($(($pos / 3)) + 1))'d' $category 
							answered=false
						# path if the question is wrong 
						elif [ $pointspos == $(( $(wc -l < "$category") * 3 )) ]
						then
							echo -e "\nSorry, you've answered that incorrectly"\
							# remove the category from the text file 
							sed -i ''$(($(($pos / 3)) + 1))'d' $category
							answered=false
						fi
					fi
				fi
				((pointspos=$pointspos+1))
			done
		done < "$category"
	fi
	((count=$count+1))
done
}

pick_points()
{
# all error checking for user input
read -p "Choose a question value: " userpointnum
# check if there is $ sign remove if so
if [ ${userpointnum:0:1} == '$' ]
then
	userpointnum=${userpointnum#?}
	# check if user input is a number 
elif ! [[ ${userpointnum:0:1} =~ ^[0-9]+$ ]]
then
	echo "Please enter a valid input"
	pick_points
fi
local count=1
for category in data/*
do
	if (( $count == $usercatnum ))
	then
	# if point num is in the category
		if grep -q $userpointnum "$category"
		then
			:
		else
			echo "Please enter a valid input"
			pick_points
		fi
	fi
	((count=$count+1))
done
}

pick_question()
{
local count=1
local pointspos=1
local calc=0
local matching=false
pick_points
# check if question specified exists in list
for category in data/*
do
# check if same category as the user picked - should change to a name and look for specific file name instead - saves continuous file name
	if (( $count == $usercatnum ))
	then
		while read -r lines; do
			IFS=','
			read -ra ADDR <<< $lines
			for j in "${ADDR[@]}"; do
				((calc=$pointspos+2))
				if (( $calc % 3 == 0))
				then
					# questions match by point num
					if (( $userpointnum == $j ))
					then
						pos=$pointspos
						matching=true
					fi
				fi
				if [ $matching == true ] && (( $calc % 3 == 1 ))
				then
				# ask user the question
					# asks question to user
					echo "$j"
					espeak "$j"
					matching=false
				fi  
				((pointspos=$pointspos+1))
			done
		done < "$category"
	fi
	((count=$count+1))
done
}

set_up()
{
if [ ! -d "./data" ]
then
	mkdir data
	# need to check if there are questions left
	for category in categories/*
	do
		cp $category data
	done
fi
# create file if doesnt exist
if [ ! -d "./dat.txt" ]
then
	touch dat.txt
	echo "0" >> ./dat.txt
fi

# read from the file
file="./dat.txt"
winnings=$(cat "$file")

local count=1
for category in data/*
do
	# check if there are questions remaining to answer
	if (( $(wc -l < "$category") == 0 ))
	then
		if (( $count == $(ls ./data/ | wc -l) ))	
		then
			no_questions=true
		fi
		((count=$count+1))
	fi
done
}

# main
set_up
print_opening_board
