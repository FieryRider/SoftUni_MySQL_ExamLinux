#!/bin/bash
# MySql login
user='root'
password='admdb'
database_name="$1"
tmpdir=/tmp/mysql

distro_name=$(grep '^ID=' /etc/os-release)
if [[ $(loginctl show-session $(loginctl | grep $(whoami) | awk '{print $1}') -p Type | grep -Po '(?<=Type=).*') = 'x11' ]]; then
  case distro_name in
    'ID=ubuntu' | 'ID=debian')
      if [[ $(dpkg -s xsel 2> /dev/null) = '' ]]; then
        echo '"xsel" package required.'
        echo 'Please install it with "apt-get install xsel"'
        echo "Without it the auto-copy to clipboard feature won't work. The program will continue it's execution without it. If you wan't to stop it's execution to install the package press Ctrl^C"
      fi
      ;;
    'ID=arch')
      if [[ $(pacman -Qs xsel) = '' ]]; then
        echo '"xsel" package required.'
        echo 'Please install it with "pacman -S xsel"'
        echo "Without it the auto-copy to clipboard feature won't work. The program will continue it's execution without it. If you wan't to stop it's execution to install the package press Ctrl^C"
      fi
      ;;
    'ID=fedora' | 'ID="centos"')
      if [[ $(rpm -qa | grep xsel) = '' ]]; then
        echo '"xsel" package required.'
        echo 'Please install it with "dnf install xsel"'
        echo "Without it the auto-copy to clipboard feature won't work. The program will continue it's execution without it. If you wan't to stop it's execution to install the package press Ctrl^C"
      fi
      ;;
  esac
fi

if [[ $(loginctl show-session $(loginctl | grep $(whoami) | awk '{print $1}') -p Type | grep -Po '(?<=Type=).*') = 'wayland' ]]; then
  case distro_name in
    'ID=ubuntu' | 'ID=debian')
      if [[ $(dpkg -s wl-clipboard 2> /dev/null) = '' ]]; then
        echo '"wl-clipboard" package required.'
        echo 'Please install it with "apt-get install wl-clipboard" (Only available in Ubuntu 20.04+ and Debian 10+)'
        echo "Without it the auto-copy to clipboard feature won't work. The program will continue it's execution without it. If you wan't to stop it's execution to install the package press Ctrl^C"
      fi
      ;;
    'ID=arch')
      if [[ $(pacman -Qs wl-clipboard) = '' ]]; then
        echo '"wl-clipboard" package required.'
        echo 'Please install it with "pacman -S wl-clipboard"'
        echo "Without it the auto-copy to clipboard feature won't work. The program will continue it's execution without it. If you wan't to stop it's execution to install the package press Ctrl^C"
      fi
      ;;
    'ID=fedora' )
      if [[ $(rpm -qa | grep wl-clipboard) = '' ]]; then
        echo '"wl-clipboard" package required'
        echo 'Please install it with "dnf install wl-clipboard"'
        echo "Without it the auto-copy to clipboard feature won't work. The program will continue it's execution without it. If you wan't to stop it's execution to install the package press Ctrl^C"
      fi
      ;;
  esac
fi

if [[ ! -d $tmpdir ]]; then
  mkdir $tmpdir
  chmod a+rwx $tmpdir
fi

rm $tmpdir/output.tsv
echo 'Enter check query: '
read check_command
if [[ $check_command = *\; ]]; then
  check_command=${check_command::-1}
fi

mysql -u "$user" -p"$password" -e "USE \`$database_name\`; $check_command INTO OUTFILE '${tmpdir}/output.tsv' FIELDS TERMINATED BY '\t' LINES TERMINATED BY '\n';"

# add empty line at the end of the file with tab separators for the amount of columns
head -1 $tmpdir/output.tsv | grep -Po '\t' >> $tmpdir/output.tsv
set -i '$d' $tmpdir/output.tsv

if [[ $(loginctl show-session $(loginctl | grep $(whoami) | awk '{print $1}') -p Type | grep -Po '(?<=Type=).*') = 'x11' ]]; then
  cat "$tmpdir"/output.tsv | xsel -i -b
elif [[ $(loginctl show-session $(loginctl | grep $(whoami) | awk '{print $1}') -p Type | grep -Po '(?<=Type=).*') = 'wayland' ]]; then
  cat "$tmpdir"/output.tsv | wl-copy
fi
