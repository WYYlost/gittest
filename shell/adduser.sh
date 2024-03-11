#!/bin/sh

#V2200: migrate to pkc.nie.netease.com
#V2201: auto exclude user whose username is the same as the project name.
#V2202: add user by email
#V2203: echo http code if wget failed in Linux.
#V2204: add arg -n: get_users_by_group type=0; -i: int.pkc.nie.netease.com; auto upgrade.
#V2205: add output msg when http 404 occurred.

myver="2205"

puser="pseudo4pkc"
puid="8000"
EXCLUDE="puppet|dnsmasq|mysql|$puser"
server="http://pkc.nie.netease.com:8660"
gulisturl="$server/pkc/gameuser/all/"
urlpre="$server/pkc/v2/get_users_by_group"
prolist="$server/pkc/projectlist/"

verurl="$server/pkc/static/VERSION"

pros="/tmp/pkctmp_projectlist.txt.$$"
keyfile="/tmp/pkctmp_keyfile.txt.$$"
gulist="/tmp/pkctmp_gameuserlist.txt.$$"
cuser="/tmp/pkctmp_current_userlist.txt.$$"
gtmp="/tmp/pkctmp_gtmp.txt.$$"
httptmp="/tmp/pkctmp_httptmp.txt.$$"
rmflag=0
setuid=0
recursive=1
clean=1
isbsd=0
isproject=0
has_adm_group=0

os="$(uname)"
case "$os" in
    Linux)
        isbsd=0
    ;;
    FreeBSD)
        isbsd=1
    ;;
    *)
        echo "ERROR: unsupported os $os"
        exit 1
    ;;
esac

grep -q -w '^adm' /etc/group
if [ $? -eq 0 ] ; then
    has_adm_group=1
fi

usage()
{
    cat << _EOF
    Usage: $0 user_name|group_name [-y] [-f] [-i] [-n]
        -y      remove users not in group list, skiped while given a user_name.
        -f      fix user uid.
        -i      connect to server via internal network.
        -n      add users in current group only, skip the upper lever groups.
_EOF
}

check_user()
{
    i=`whoami`
    if [ $i != "root" ];then
        echo "ERROR: this program must be run by root!"
        exit 1
    fi
}

group_add()
{
    local gname=$1
    local gid=$2
    if [ $isbsd -eq 0 ] ; then
        /usr/sbin/groupadd -g $gid $gname
    else
        pw groupadd $gname -g $gid
    fi
    check_error $? "Failed to add group $gname" quit
    echo "INFO: group $gname was added, gid $gid"
}

group_mod()
{
    local gname=$1
    local gid=$2
    if [ $isbsd -eq 0 ] ; then
        /usr/sbin/groupmod -g $gid $gname
    else
        pw groupmod $gname -g $gid
    fi
    check_error $? "Failed to modify group $gname" quit
    echo "INFO: gid of $gname was set to $gid"
}

user_add()
{
    local user=$1
    local uid=$2
    local comment=$3

    if [ $isbsd -eq 0 ] ; then
        if [ "$user" = "$puser" ] ; then
            /usr/sbin/useradd -s /bin/false -d /nonexistant -u $uid $user
        else
            /usr/sbin/useradd -G $user -c "$comment" -s /bin/bash -g $user -m -d /home/$user -u $uid $user
            if [ $has_adm_group -eq 1 ] ; then
                /usr/sbin/usermod -a -G adm $user
            fi
            /usr/sbin/usermod -p '*' $user
        fi
    else
        if [ "$user" = "$puser" ] ; then
            pw useradd -w no -s /usr/sbin/nologin -u $uid -d /nonexistent -n $user
        else
            pw useradd -w no -c "$comment" -s /bin/csh -g $user -m -u $uid -n $user
        fi
    fi
    check_error $? "Failed to add user $user" quit
    if [ "$user" != "$puser" ] ; then
        echo "INFO: user $user was added, uid $uid, comment $comment"
    fi
}

user_mod()
{
    local user=$1
    local comment=$2
    local uid=$3

    local uidcmd=""
    if [ "$uid" != "" ] ; then
        uidcmd="-u $uid"
    else
        uid="unmodified"
    fi

    if [ $isbsd -eq 0 ] ; then
        if [ "$user" = "$puser" ] ; then
            /usr/sbin/usermod -c "$comment" -p '*' -s /bin/false -g $user $uidcmd $user
        else
            /usr/sbin/usermod -c "$comment" -p '*' -s /bin/bash -g $user $uidcmd $user
            if [ $has_adm_group -eq 1 ] ; then
                /usr/sbin/usermod -a -G adm $user
            fi
        fi
    else
        if [ "$user" = "$puser" ] ; then
            pw usermod -w no -c "$comment" -s /usr/sbin/nologin -g $user $uidcmd -n $user
        else
            pw usermod -w no -c "$comment" -s /bin/csh -g $user $uidcmd -n $user
        fi
    fi
    check_error $? "Failed to modify user $user" quit
    if [ "$user" != "$puser" ] ; then
        echo "INFO: user $user was modified, uid $uid, comment $comment"
    fi
}

user_group_add()
{
    local user=$1

    if [ $isbsd -eq 0 ] ; then
        /usr/sbin/usermod -a -G root $user
    else
        pw groupmod wheel -m $user
    fi
    check_error $? "Failed to add user $user to root/wheel group" quit
    echo "INFO: user $user was added to root/wheel group"
}

do_clean()
{
    rm -f $pros $keyfile $gulist $cuser $gtmp $httptmp
}

check_error(){
    local retcode="$1"
    local msg="$2"
    local quit="$3"

    if [ $retcode -ne 0 ] ; then
        echo "ERROR: $msg" >&2
        if [ "test"$quit = "testquit" ] ; then
            do_clean
            exit 1
        fi
    fi
}

httpget()
{
    local url="$1"
    local dst="$2"
    local rc=1
    local httpcode=200

    if [ $isbsd -eq 1 ] ; then
        fetch -q -o $dst "$url"
        check_error $? "Failed to get $url" quit
    else
        wget --server-response -O $dst "$url" 2> $httptmp
        rc=$?
        httpcode="$(cat $httptmp | awk '/HTTP\//{print $2}')"
        if [ "$httpcode" = "404" ] ; then
            echo "ERROR: user or project not found in pkc. Please register public key in Workflow first."
        fi
        check_error $rc "Failed to get $url, http code: $httpcode" quit
    fi
}

check_update()
{
    httpget "$verurl" $gtmp
    curver="$(cat $gtmp)"
    if [ "$curver" = "" ] ; then
        echo 'WARN: Failed to check new version, skip it.'
        return 1
    fi
    if [ "$curver" -gt "$myver" ] ; then
        echo "INFO: NEW VERSION $curver is available, try to update myself ..."
        httpget "$server/pkc/static/adduser.sh" "$0"
        echo "INFO: Update done. "
        do_clean
        /bin/sh $0 $@
        exit $?
    fi
}

check_args()
{
    echo $gameuser | egrep -q '^[.a-zA-Z0-9_@]+$'
    check_error $? "$gameuser is not a valid user/project name" quit

    for arg in $@
    do
        case "$arg" in
            -y)
                rmflag=1
                ;;
            -f)
                setuid=1
                ;;
            -n)
                recursive=0
                ;;
            -i)
                server="http://int.pkc.nie.netease.com:8660"
                gulisturl="$server/pkc/gameuser/all/"
                urlpre="$server/pkc/v2/get_users_by_group"
                prolist="$server/pkc/projectlist/"
                verurl="$server/pkc/static/VERSION"
                ;;
            *)
                echo "ERROR: unknown args $arg"
                do_clean
                exit 1
                ;;
        esac
    done
}


get_keyfile()
{
    httpget $prolist $pros
    local arg="$gameuser"
    grep -q "^$gameuser$" $pros
    if [ $? -eq 0 ] ; then
        echo "INFO: add users for project $arg"
        url="${urlpre}/?name=${arg}&type=${recursive}"
        isproject=1
    else
        #for single user
        url="$server/pkc/user_uid/$arg/"
        clean=0
        isproject=0
    fi

    httpget $url $keyfile
    if [ $? -ne 0 -o "$keyfile" = "" -o ! -e "$keyfile" ];then
        echo "ERROR: key or keylist of  $arg not found in pub key database"
        do_clean
        exit 1
    fi
    local m1="$(head -n1 $keyfile)"
    local m2=""
    if [ $isbsd -eq 0 ] ; then
        m2="$(sed -n -e '2,$p' $keyfile | md5sum | awk '{print $1}')"
    else
        m2="$(sed -n -e '2,$p' $keyfile | md5)"
    fi
    if [ "$m1" != "$m2" ] ; then
        echo "ERROR: keyfile md5 check failed"
        do_clean
        exit 1
    fi
}

do_adduser()
{
    local ADD=""
    local count=0

    while read line
    do
        #adun;normal;ssh-rsa pubkey;JiangTao;1000
        local user="$(echo $line | cut -d ';' -f 1)"
        local cansu="$(echo $line | cut -d ';' -f 2)"
        local key="$(echo $line | cut -d ';' -f 3)"
        local comment="$(echo $line | cut -d ';' -f 4)"
        local uid="$(echo $line | cut -d ';' -f 5)"

        local logined=0
        local uid_changed=0
        local added=no

        count=$(expr $count + 1)
        if [ "$count" -eq 1 ] ; then
            #skip md5
            continue
        fi

        if [ -z "$user" -o -z "$cansu" -o -z "$key" -o -z "$comment" -o -z "$uid" ];then
            echo "WARN: invalid line found: $line"
            continue
        fi
        if [ "$key" = "PUB-KEY-NOT-FOUND" ] ; then
            echo "WARN: pubkey of $user not found, skip it"
            continue
        fi

        echo "$uid" | egrep -q '^[0-9]+$'
        if [ $? -ne 0 -o "$uid" = "0" ] ; then
            echo "WARN: invalid uid of $user, uid: $uid"
            continue
        fi

        who | grep -q -w "^$user"
        if [ $? -eq 0 ] ; then
            logined=1
            if [ $setuid -eq 1 ] ; then
                echo "NOTI: $user has logined, its uid/gid won't be changed"
            fi
        fi

        echo $ADD | grep -q -w "$user"
        if [ $? -eq 0 ] ; then
            added=yes
        fi

        if [ "$added" = "no" ] ; then
            #check group
            grep -q -w "^$user" /etc/group
            if [ $? -ne 0 ] ; then
                group_add $user $uid
            else
                if [ $setuid -eq 1 ] ; then
                    #get current gid
                    gid="$(grep "^$user:" /etc/group | cut -d ':' -f 3)"
                    if [ "$gid" != "$uid" ] ; then
                        #modify a group id may cause some problem, be careful.
                        #normally, gid = uid > 1500, there should not be a gid collision.
                        if [ $logined -eq 0 ] ; then
                            uid_changed=1
                            group_mod $user $uid
                        else
                            echo "WARN: skip gid modification of $user"
                        fi
                    fi
                fi
            fi

            id $user > /dev/null 2>&1
            if [ $? -ne 0 ] ; then
                user_add $user $uid $comment
            else
                uidcmd=""
                if [ $setuid -eq 1 ] ; then
                    cuid="$(grep "^$user:" /etc/passwd | cut -d ':' -f 3)"
                    if [ "$cuid" != "$uid" ] ; then
                        if [ $logined -eq 0 ] ; then
                            uid_changed=1
                            uidcmd="$uid"
                            echo "INFO: uid of $user will be modified $cuid -> $uid"
                        else
                            echo "WARN: skip uid modification of $user"
                        fi
                    fi
                fi
                user_mod $user $comment $uidcmd
            fi

            if [ "$cansu" = "root" ] ; then
                user_group_add $user
            fi

            if [ ! -d /home/$user/.ssh ] ; then
                mkdir -p /home/$user/.ssh
                check_error $? "Failed to mkdir /home/$user/.ssh" quit
            fi
            echo "$key $comment" > /home/$user/.ssh/authorized_keys
            check_error $? "Failed to echo key of $user" quit

            if [ $uid_changed -eq 1 ] ; then
                chown -R $user:$user /home/$user
            fi
            chown $user:$user /home/$user && \
            chown -R $user:$user /home/$user/.ssh && \
            chmod 700 /home/$user/.ssh && \
            chmod 600 /home/$user/.ssh/authorized_keys
            check_error $? "Failed to chmod/chown dir/file of $user" quit

            ADD="$ADD $user"
        else
            echo "$key $comment" >> /home/$user/.ssh/authorized_keys
            check_error $? "Failed to add key of $user" quit
            echo "INFO: $user add key successful"
        fi
    done<$keyfile
}

add_pseudo_user()
{
    #add a pseudo user here,
    #if a user is added manually, not by this script,
    #make sure it don't use the uid we need
    id $puser > /dev/null 2>&1
    if [ $? -ne 0 ] ; then
        user_add $puser $puid "pkc_pseudo_user"
    else
        user_mod $puser "pkc_pseudo_user" $puid
    fi
}

rm_user()
{
    local gameuser=$1
    gameuser="$(echo $gameuser | cut -d '.' -f 1)"

    if [ $rmflag -eq 0 ] ; then
        echo "WARN: rmuser will be skiped, use $0 -y to remove users not in list"
    fi
    httpget $gulisturl $gulist
    gus="$(cat $gulist)"
    if [ "$gus" = "" ] ; then
        echo "ERROR: gameuser list is empty, check it"
        do_clean
        exit 1
    fi
    if [ "$gus" != "" ] ; then
        EXCLUDE="$EXCLUDE|$gus"
    fi

    awk -F':' '{if ($3 >= 1000 && $3 <= 5000) print $1}' /etc/passwd | grep -v  -w "$gameuser" | grep -v -w nobody | egrep -v -w "$EXCLUDE" > $cuser
    for user in `cat $cuser`
    do
        grep -q -w "^$user" $keyfile
        if [ $? -ne 0 ] ; then
            if [ $rmflag -eq 1 ] ; then
                echo "INFO: remove $user"
                [ -d /home/$user ] && mv /home/$user /home/$user.del
                if [ $isbsd -eq 0 ] ; then
                    /usr/sbin/userdel $user
                else
                    /usr/sbin/rmuser -y $user
                fi
            else
                echo "INFO: skip removing $user"
            fi
        fi
    done
}


#main
check_update $@

check_user
gameuser=$1
if [ "$gameuser" = "" ] ; then
    usage
    do_clean
    exit 1
fi
shift
check_args $@

get_keyfile
do_adduser
add_pseudo_user

if [ "$clean" -eq 1 ] ; then
    rm_user $gameuser
fi
do_clean

