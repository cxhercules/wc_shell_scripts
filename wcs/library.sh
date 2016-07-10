#!/bin/sh -x
##
## Libary files to use on different scripts
##

# -*-Shell-script-*-
#
# functions	This file contains functions to be used by most or all
#		shell scripts in this dir
#

# inpath - Varifies that a specified program is either valid as is,
#   or that it can be found in the PATH directory list. 

in_path()
{
   # Given a command and the PATH, try to find the command. Returns
   # 0 if found and executable, 1 if not. Note that this temporarily modifies
   # the IFS (input field separator) but restores it upon completion. 

   cmd=$1       path=$2          retval=1
   oldIFS=$IFS  IFS=":"

   for directory in $path   
   do 
      if [ -x $directory/$cmd ] ; then
          retval=0    # if we're here, we found $cmd in $directory
      fi
   done
   IFS=$oldIFS
   return $retval
}


checkForCmdInPath()
{
   var=$1

   # The variable slicing notation in the fallowing conditional
   # needs some explation: ${var#expr} returns everyting after
   # the match for 'expr' in the variable value (if nay), and 
   # ${var%expr} returns everything that doesn't match (in this 
   # case, just the very first character. You can also do this in 
   # Bash with ${var:0:1}, and you could use cut too: cut -c1. 

   if [ "$var" != "" ]; then
      if [ "${var%${var#?}}" = "/" ]; then
         if [ ! -x $var ]; then 
            return 1
         fi
      elif ! in_path $var $PATH ; then
         return 2
      fi
   fi        
}

# validAlphaNum - Ensures that input consists only of alphabetical and numeric characters. 

validAlphaNum()
{
   # VAlidate arg: returns 0 if all upper+lower+digits, 1 otherwise

   # Remove all unacceptable chars
   compressed="$(echo $1 | sed -e 's/[^[:alnum:]]//g')"

   if [ "$compressed" != "$1" ] ; then
      return 1
   else
      return 0
   fi
}

# normdate -- Normalizes month field in date specification
# to three letters, first letter capitalization. A helper 
# function for Script #7, valid-date. Exits w/ zero if no error. 

monthnoToName()
{
   # Sets the variable  'month' to the appropriate value
	case $1 in 
	   1 ) month="Jan"		;; 2 ) month="Feb"		;;
	   3 ) month="Mar"		;; 4 ) month="Apr"		;;
	   5 ) month="May"		;; 6 ) month="June"		;;
	   7 ) month="Jul"		;; 8 ) month="Aug"		;;
	   9 ) month="Sep"		;; 10) month="Oct"		;;
	   11) month="Nov"		;; 12) month="Dec"		;;
	   * ) echo "$0: Unknown numeric month value $1" >&2; exit 1
	esac
	return 0
}

# nicenumber -- Given a number, shows it in comma-separated form.
# Expects DD and TD to be instantiated. Instantiates nicenum
# or, if a second arg is specified, the output is echoed to stdout. 

nicenumber()
{
   # Note that we assume that '.' is the decimal separator in
	# the INPUT value to this script. The decimal separator in the output value is
	# '.' unless specified by the user with the -d flag

   integer=$(echo $1 | cut -d. -f1)					# left of the decimal
	decimal=$(echo $1 | cut -d. -f2)					# right of the decimal

	if [ $decimal != $1 ]; then
		# There's a fractional part, so let's include it.
		result="${DD:="."}$decimal"
	fi

	thousands=$integer

	while [ $thousands -gt 999 ]; do 
		remainder=$(($thousands % 1000))				# three least significant digits

		while [ ${#remainder} -lt 3 ]; do 			# force leading zeros as needed
			remainder="0$remainder"
		done

		thousands=$(($thousands / 1000))				# to left of remainder, if any
		result="${TD:=","}${remainder}${result}"	# builds right to left
	done

	nicenum="${thousands}${result}"
	if [ ! -z $2 ]; then
		echo $nicenum
	fi
}

# validint -- Validates integer input, allowing negative ints too.

function validint
{
	# Validate first field. Then test against min value $2 and/or 
	# max value $3 if they are supplied. If they are not supplied, skip these tests. 

   number="$1";		min="$2";		max="$3";

	if [ -z $number ] ; then 
		echo "You didn't enter anything. Unacceptable." >&2; return 1
	fi

	if [ "${number%${number#?}}" = "-" ] ; then # is first char a '-' sign?
		testvalue="${number#?}"		# all but first character
	else
		testvalue="$number"
	fi

	nodigits="$(echo $testvalue | sed 's/[[:digit:]]//g')"

	if [ ! -z $nodigits ] ; then 
		echo "Invalid number format! Only digits, no commas, spaces, etc." >&2
		return 1
	fi

	if [ ! -z $min ] ; then 
		if [ "$number" -lt "$min" ] ; then
			echo "Your value is too small: smallest acceptable value is $min" >&2
			return 1
		fi
	fi

	if [ ! -z $max ] ; then 
		if [ "$number" -gt "$max" ] ; then 
		   echo "Your value is too big: largest acceptable value is $max" >&2
			return 1
		fi
	fi
	
	return 0
}


# validfloat

# To test whether an entered value is a valid floating-point number, we 
# need to split the value at the decimal point. We then test the first part
# to see if it's a valid integer, then test the second part to see if it's a 
# valid >=0 integer, so -30.5 is valid, but -30.-8 isn't. 

validfloat()
{
	fvalue="$1"
	
	if [ ! -z $(echo $fvalue | sed 's/[^.]//g') ] ; then
		decimalPart="$(echo $fvalue | cut -d. -f1)"
		fractionalPart="$(echo $fvalue | cut -d. -f2)"

		if [ ! -z $decimalPart ] ; then
			if ! validint "$decimalPart" "" "" ; then
				return 1
			fi
		fi

		if [ "${fractionalPart%${fractionalPart#?}}" = "-" ] ; then
			echo "Invalid floating-point number: '-' not allowed \
				after decimal point" >&2
			return 1
		fi

		if [ "$fractionalPart" != "" ] ; then
			if ! validint "$fractionalPart" "0" "" ; then
				return 1
			fi
		fi

		if [ "$decimalPart" = "-" -o -z "$decimalPart" ] ; then
			if [ -z $fractionalPart ] ; then
				echo "Invalid floating-point format." >&2 ; return 1
			fi
		fi

	else
      if [ "$fvalue" = "-" ] ; then
			echo "Invalid floating-point format." >&2 ; return 1
		fi

		if ! validint "$fvalue" "" "" ; then
			return 1
		fi
	fi

	return 0
}

# valid-date -- Validates a date, taking into account leap year rules. 

exceedsDaysInMonth()
{
	# Given a month name, return 0 if the specified day value is
	# less than or equal to then max days in the month; 1 otherwise

	case $(echo $1|tr '[:upper:]' '[:lower:]') in
	   jan* ) days=31	;;		feb* )	days=28	;;
	   mar* ) days=31	;;		apr* )	days=30	;;
	   may* ) days=31	;;		jun* )	days=30	;;
	   jul* ) days=31	;;		aug* )	days=31	;;
	   sep* ) days=30	;;		oct* )	days=31	;;
	   nov* ) days=30	;;		dec* )	days=31	;;
		* ) echo "$0: Unknown month name $1" >&2; exit 1
	esac

	if [ $2 -lt 1 -o $2 -gt $days ] ; then 
		return 1
	else
		return 0		# the day number is valid
	fi

}

isLeapYear()
{
	# This function returns 0 if a leap year; 1 otherwise. 
	# The formula for checking whether a year is a leap year is:
	# 1. Years not divisible by 4 are not leap years. 
	# 2. Years divisible by 4 and by 400 are leap years. 
	# 3. Years divisible by 4, not divisible by 400, and divisible by 100, 
	# are not leap years. 
	# 4. All other years divisible by 4 are leap years. 

	year=$1
	if [ "$((year % 4))" -ne 0 ] ; then
		return 1 # nope, not a leap year
	elif [ "$((year % 400))" -eq 0 ] ; then
	   return 0 # yes, it's a leap year
	elif [ "$((year % 100))" -eq 0 ] ; then
	   return 1
	else
		return 0
	fi
}

# Normalize date and split back out returned values

# Substitute for echo if not working with -n option
echon() {
	echo "$*" | tr -d '\n'
}


#!/bin/sh

# ANSI Color -- Use these variables to make output in different colors
# and formats. Color names that end with 'f' are foreground (text) colors,
# and those ending with 'b' are backgroun colors. 

initializeANSI()
{
	esc="" # if this doesn't work, enter an ESC directly

	blackf="${esc}[30m";   redf="${esc}[31m";   greenf="${esc}[32m"
	yellowf="${esc}[33m";  bluef="${esc}[34m";  purplef="${esc}[35m"
	cyanf="${esc}[36m";    whitef="${esc}[37m"


	blackb="${esc}[30m";   redb="${esc}[31m";   greenb="${esc}[32m"
	yellowb="${esc}[33m";  blueb="${esc}[34m";  purpleb="${esc}[35m"
	cyanb="${esc}[36m";    whiteb="${esc}[37m"

	boldon="${esc}[1m";    boldoff="${esc}[22m"
	italicson="${esc}[3m"; italicsoff="${esc}[23m"
	ulon="${esc}[4m";      uloff="${esc}[24m"
	invon="${esc}[7m";     invoff="${esc}[27m"

	reset="${esc}[0m"
}


# filelock - A flexible file locking mechanism

filelock()
{
	retries="10"			# default number of retries
	action="lock"			# default action
	nullcmd="/bin/true"	# null command for lockfile

	while getopts "lur:" opt;  do 
		case $opt in 
		  l ) action="lock"     ;;
		  u ) action="unlock"   ;;
		  r ) retries="$OPTARG" ;;
		esac
	done
	shift $(($OPTIND - 1))

	if [ $# -eq 0 ] ; then
		cat << EOF >&2
Usage: $0 [-l|-u] [-r retries] lockfilename
Where -l requests a lock (the default), -u requests an unlock, -r X 
specifies a maximum number of retries before it fails (default = $retries).
EOF
	  exit 1
	fi

   # Ascertain whether we have a lockf or lockfile system apps

	if [ -z "$(which lockfile | grep -v '^no ')" ]; then
		echo "$0 failed: 'lockfile' utility not found in PATH." >&2
		exit 1
	fi

	if [ "$action" = "lock" ] ; then
		if ! lockfile -1 -r $retries "$1" 2> /dev/null; then
			echo "$0: Failed: Couldn't create lockfile in time" >&2
			exit 1
		fi
	else   # action = unlock
		if [ ! -f "$1" ] ; then
			echo "$0: Warning: lockfile $1 doesn't exist to unlock" >&2
			exit 1
		fi
		rm -f "$1"
	fi
}

# scriptbc - Wrapper for 'bc' that returns the result of a calculation.
scriptbc ()
{
	if [ $1 = "-p" ] ; then
		precision=$2
		shift 2
	else
		precision=2			#default
	fi

bc -q << EOF
scale=$precision
$*
quit
EOF
}

