#!/bin/bash
# add uu init user
# author: xuchi03
declare -A userpublickey useruid
BACKUPDIR='/var/initsh/backup'
candidateuser=(lzyn6787 lcn1701 zfzn1702 sunyi07 wb.wuyuying )
userpublickey=(['lzyn6787']="ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAvBpBwVUw28IH3iHmH47IgjTeuXVJliTt9aSxI+PU0m+rooVxWOOYPVGu26WSpFOoEgzYn+QpmqU9Xzxk6QVV3JfYv23hd1gCAw+y1cIqEERUNy30wQ7K6wJlijDMynSq+257ivNDUuPsA5whTwIdyde3rvR7d758soUDjw3CC1S1S54O1jP9kXH0VaWPH++WXxG+XBhZb1GM5I9R1n8hdmz95mxYmHtXyE1s5h6fVGej+bnVEmpXHC4B12Q2Zf3xbfygj+8KrOAm0nk7H/uEjG2VoYgc/ubgzt34uSos02RJqNM5iEeis2avTosu+1Gr3L3wv68urCGu69U+kjVX8Q==" \
['lcn1701']="ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAqXAnWm4I8PE+SOSWiqDsWCnEW3kQYwroqq6wpURf3nIIz/XTkdgaQqWPpKbW/SJM6Scnnw9YXTAsdxlZ1nIw2BZWE9/Tw4eyTEfRA3PgSGHDj6VDJ437r4e8WjHlr12SB7mFkegdH8/NaaNHoFE1BuE7hg83MtLJdOR4Fp0w0BZiQ1Rhd8hTxpxmW/vcu8Bl6SPbFpsCs3ByMLDz+LDrSz54jM0HoatFdaU2oiFTIwzY3p281prpAwfDf823uq15Bmn40IcDrKyEW37M6ns6FRMP2F1VEA2aZ+3NVlBckpaG4PaGkI756i4PcL7K0HCXpOUjtExlbg4IO0b02gjNqw==" \
['zfzn1702']="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDTHKv998cSVuNptKNP+armIC8a70GLqkPW/iYgrmNXdG23EPngUr0LcmL7p97q+YuXMVWJDDvbfN7SaoOItese2V8ZgKWcYjXqeb5fiNE44GNTkSF5Xlcl02R5K1sj1h5kxVDpcqNE60GG/gj+NjnOADy/s2lBmWfJsgOpHvhKHea+CT7wQmdXO+WV0780CIwD0Wg18TXUozYqNNM5To8T1547PO4KRu9XVfITU3S0gXdG2ICvSoEF3SLQmttSdTGiw3Oib5xcjefky5PTYP5vjOxH4Td6k2UHfeVedcN8k/0aA0rTuFsS6uHD2bvkJGVLLv2F/po/1QOiXie91JlB" \
['wb.wuyuying']="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDj03YcM8WU6UXNuAxR8Dacgklm1qGgauD9PZ4Vwhsqqx0bU4b1ClfDA1Wbp7RYY72Eo0pV57WBZD4cgG8HHUWOGRV+b7nOE8i2pokUbRYRvCbAQ6m++n6D5QXebBUk975uzdNqoWDel45ZEJHn+fdhXbMvE1r162ijQlSqWps6i6ifVfMJ9sXiwbWH7IbUPhidhN1qnRS0RcGYiTIsX9RBOTu5XsoIQ0FaW24PdW/tSC8PQzZZH1rzaF0SCxNM5eDfcCvs4fHeyJhJakJdXKYy59rps0CbmLVAoYpimrR4pyHqlYVRvcQqSxq+xHWh/dluwfc8NAnGjkV8HDVHBdnr" \
['sunyi07']="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDhVa1jt4daspS9Cl2B7W6Mx8tRHGWLS6kt254SNYacnHniMNN48vVcYLN3EHRGDysN7vbMPbfj0Lf85CviB5zAbL9NsXNP31n5ocnjMDcblbEZv78sZU7zls2rdYf8cwjRcpEDWxonGhECddL3GW2O7hvp8mrDlesfvIjIU1HacdAKRFGnBaoTer/Sb9qpIZO1C7sRqfUA6+OcP9apjP/fv6LZQzjXpGAAMF81dIs0rYu8gAOLX9L0pz4Flvejsab9XZDru0I2sxm461qu38Du93Pz3u3kFNIlsXG74H9lFw90+zrHIuyCRFv7eA6JLH1cap9uHHFvYvyv8KxaJvUJ")
useruid=(['lzyn6787']="4216" \
['lcn1701']="2749" \
['zfzn1702']="2748" \
['wb.wuyuying']="52356" \
['sunyi07']="50645")
created_users=()
failed_users=()

check_exit(){
# $1: string to print when got error
    RETCODE=$?
    if [ "$RETCODE" -ne 0 ]
    then
        if [ -n "$1" ]
        then
            echo "$1" >&2
        fi
        exit "$RETCODE"
    fi
}

#check user
if [ `whoami` != "root" ]
then
    echo "^[[1;31mMust be run with root user^[[00m" >&2
    exit 1
fi
echo -e "\n\033[33mChange Root Passwd...\033[0m\n"
echo root:zUR1Y5xIuAWzQrm | chpasswd

echo -e "\n\033[33mStep 1/3: add default user ...\033[0m\n"
# add uu user and sa
for user in "${candidateuser[@]}"
do
    echo $user
    uid=${useruid[$user]}
    if id "$user" >/dev/null 2>&1; then
        echo "User '$user' already exists, skipping."
        created_users+=("$user")
        continue
    fi
    if useradd -p '*' -u "$uid" -m -s /bin/bash "$user"; then
        usermod -aG root "$user"
        cd "/home/$user" && mkdir .ssh && \
        touch .ssh/authorized_keys && \
        echo "${userpublickey[$user]}" > .ssh/authorized_keys && \
        chown -R "$user:$user" .ssh && \
        chmod 700 .ssh && \ 
        chmod 600 .ssh/authorized_keys && \
        created_users+=("$user")
    else
        echo -e "\033[31mFailed to create user '$user'.\033[0m"
        failed_users+=("$user")
    fi
done

if [ "${#created_users[@]}" -eq "${#candidateuser[@]}" ]; then
  echo -e "\033[32mAll users created successfully: ${created_users[*]}\033[0m"
else
  echo -e "\033[31mFailed to create the following users: ${failed_users[*]}.\033[0m"
fi

sleep 5

#===================================================================================
echo -e "\n\033[33mStep 2/3: config ssh...\033[0m\n"
# 备份文件并重启服务
mkdir -p /var/initsh/backup
cp /etc/ssh/sshd_config /var/initsh/backup/
echo """
# 1. Basic
Port 32200
Protocol 2
AddressFamily inet

# 2. Authentication
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_dsa_key
AuthorizedKeysFile .ssh/authorized_keys

KeyRegenerationInterval 3600
ServerKeyBits 768
UsePrivilegeSeparation yes
LoginGraceTime 120

PermitRootLogin no
StrictModes yes

RSAAuthentication yes
PubkeyAuthentication yes
PermitEmptyPasswords no
ChallengeResponseAuthentication no
PasswordAuthentication no

IgnoreRhosts yes
RhostsRSAAuthentication no
HostbasedAuthentication no


# 3. Features
UseDNS no
UsePAM no
X11Forwarding yes
X11DisplayOffset 10
PrintMotd no
PrintLastLog yes
TCPKeepAlive yes
AcceptEnv LANG LC_*


# 4. Logging
SyslogFacility AUTH
LogLevel INFO


# 5. x509
Subsystem sftp /usr/lib/sftp-server
""" > /etc/ssh/sshd_config
service ssh restart
sleep 5

# =========================================================================================
echo -e "\n\033[33mStep 3/3: deploy default iptables...\033[0m\n"
os_version=`grep 'VERSION='  /etc/os-release | grep -Po '\d+'`
mkdir -p /etc/iptables/
echo """
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]

# for established connections
-I INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
-A INPUT -s 127.0.0.1/32 -j ACCEPT
-A INPUT -p icmp -j ACCEPT
# for ssh
-A INPUT -p tcp --dport 32200 -j ACCEPT
# Drop all
-A INPUT -j DROP

COMMIT
""" | tee /etc/iptables/iptables.cur /etc/iptables.netease
sleep 5

if [ $os_version -eq "7" ]; then
    bash /etc/network/if-pre-up.d/iptables
else
    iptables-restore < /etc/iptables.netease
    echo -e "\033[32madd default user and init ssh & ipatbles success!\033[0m"
fi
check_exit
exit 0
