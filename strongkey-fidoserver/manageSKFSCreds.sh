#!/bin/bash
#
###############################################################
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License, as published by the Free Software Foundation and
# available at https://www.gnu.org/licenses/old-licenses/lgpl-2.1.html,
# version 2.1.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# Copyright (c) 2001-2021 StrongAuth, Inc.
#
# $Date$
# $Revision$
# $Author$
# $URL$
#
################################################################

. /etc/bashrc

SCRIPT_HOME=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
OPERATION=$1
SAKA_DID=$2
SERVICE_LDAP_BIND_PASS=$3
SERVICE_LDAP_BASEDN='dc=strongauth,dc=com'
USERNAME=$4
allgroups="FidoRegistrationService-AuthorizedServiceCredentials,FidoAuthenticationService-AuthorizedServiceCredentials,FidoAuthorizationService-AuthorizedServiceCredentials,FidoAdministrationService-AuthorizedServiceCredentials,FidoCredentialService-AuthorizedServiceCredentials,FidoPolicyManagementService-AuthorizedServiceCredentials,FidoMonitoringService-AuthorizedServiceCredentials,test"


##########################################
##########################################

usage() {
        echo "Usage: "
        echo "${0##*/} addUser <did> <bind-pass> <username>"
        echo "${0##*/} addGroup <did> <bind-pass> <group name>"
        echo "${0##*/} addUserToGroup <did> <bind-pass> <username> <group(s)>"
        echo "${0##*/} removeUserFromGroup <did> <bind-pass> <username> <group(s)>"
        echo "${0##*/} getUserGroups <did> <bind-pass> <username>"
        echo "${0##*/} changeUserPassword <did> <bind-pass> <username>"
        echo "${0##*/} deleteUser <did> <bind-pass> <username>"
        echo "Options:"
        echo "did                The domain ID"
        echo "username           Username of the user or admin user"
        echo "group(s)           List of groups separated by commas"
}

if [[ -z $OPERATION || -z $SAKA_DID || -z $USERNAME ]]; then
        usage
        exit 1
fi

#Test If Default LDAP Password is Used
ldapwhoami -x -w  "$SERVICE_LDAP_BIND_PASS" -D "cn=Manager,$SERVICE_LDAP_BASEDN" 2> /tmp/Error 1> /dev/null
ERROR=$(</tmp/Error)
rm /tmp/Error
if [ -n "$ERROR" ]; then
        echo "Enter LDAP Bind Password:"
        read -s SERVICE_LDAP_BIND_PASS
        echo ""
fi


if [ "$OPERATION" = "addUser" ]; then
        echo "Enter Password for New User:"
        PASSWORD=$(slappasswd -h {SSHA})
        if [ -z "$PASSWORD" ]; then
                exit 1
        fi

        cat > /tmp/ldapuser.ldif << LDAPUSER
dn: cn=$USERNAME,did=$SAKA_DID,ou=users,ou=v2,ou=SKCE,ou=StrongAuth,ou=Applications,$SERVICE_LDAP_BASEDN
changetype: add
objectClass: person
objectClass: organizationalPerson
objectClass: inetOrgPerson
objectClass: top
userPassword: $PASSWORD
givenName: $USERNAME
cn: $USERNAME
sn: $USERNAME
LDAPUSER
        ldapmodify -x -w  "$SERVICE_LDAP_BIND_PASS" -D "cn=Manager,$SERVICE_LDAP_BASEDN" -f /tmp/ldapuser.ldif 2> /tmp/Error
        ERROR=$(</tmp/Error)
        rm /tmp/ldapuser.ldif /tmp/Error
        if [ -z "$ERROR" ]; then
                echo "Added User '$USERNAME'"
                #print out for groups and a prompt to run addusertogroup
                echo ""
                tput setaf 1; echo "This User is currently a Member of NO Groups!"
                tput sgr0; echo "Please run addUserToGroup and specify which of the following Groups you wish $USERNAME to be added to:"
                echo ""
                echo "$allgroups"
                echo ""
                exit 0
        else
                echo $ERROR
                exit 1
        fi
fi
if [ "$OPERATION" = "addAdmin" ]; then
        echo "Enter Password for New Admin:"
        PASSWORD=$(slappasswd -h {SSHA})
        if [ -z "$PASSWORD" ]; then
                exit 1
        fi

        cat > /tmp/ldapuser.ldif << LDAPUSER
dn: cn=$USERNAME,did=$SAKA_DID,ou=users,ou=v2,ou=SKCE,ou=StrongAuth,ou=Applications,$SERVICE_LDAP_BASEDN
changetype: add
objectClass: person
objectClass: organizationalPerson
objectClass: inetOrgPerson
objectClass: top
userPassword: $PASSWORD
givenName: $USERNAME
cn: $USERNAME
sn: $USERNAME

dn: cn=FidoAdminAuthorized,did=$SAKA_DID,ou=groups,ou=v2,ou=SKCE,ou=StrongAuth,ou=Applications,$SERVICE_LDAP_BASEDN
changetype: modify
add: uniqueMember
uniqueMember: cn=$USERNAME,did=$SAKA_DID,ou=users,ou=v2,ou=SKCE,ou=StrongAuth,ou=Applications,$SERVICE_LDAP_BASEDN
LDAPUSER
        ldapmodify -x -w  "$SERVICE_LDAP_BIND_PASS" -D "cn=Manager,$SERVICE_LDAP_BASEDN" -f /tmp/ldapuser.ldif 2> /tmp/Error
        ERROR=$(</tmp/Error)
        rm /tmp/ldapuser.ldif /tmp/Error
        if [ -z "$ERROR" ]; then
                echo "Added Admin $USERNAME"
                exit 0
        else
                echo $ERROR
                exit 1
        fi
fi
if [ "$OPERATION" = "addGroup" ]; then
        GROUP_NAME=$3
        if [ -z $GROUP_NAME ]; then
                usage
                exit 1
        fi
        cat > /tmp/FidoServiceGroup.ldif <<-LDAPGROUP
dn: cn=$GROUP_NAME,did=$SAKA_DID,ou=groups,ou=v2,ou=SKCE,ou=StrongAuth,ou=Applications,$SERVICE_LDAP_BASEDN
objectClass: groupOfUniqueNames
objectClass: top
cn: $GROUP_NAME
uniqueMember: cn=fidoadminuser,did=$SAKA_DID,ou=users,ou=v2,ou=SKCE,ou=StrongAuth,ou=Applications,$SERVICE_LDAP_BASEDN
uniqueMember: cn=svcfidouser,did=$SAKA_DID,ou=users,ou=v2,ou=SKCE,ou=StrongAuth,ou=Applications,$SERVICE_LDAP_BASEDN
LDAPGROUP

        /bin/ldapadd -x -w $SERVICE_LDAP_BIND_PASS -D "cn=Manager,$SERVICE_LDAP_BASEDN" -f /tmp/FidoServiceGroup.ldif
	
	newallgroups=$(echo $(cat $SCRIPT_HOME/manageSKFSCreds.sh | grep -E "^allgroups=") | sed "s/\"$/,$GROUP_NAME\"/")
        sed -i "s/^allgroups=.*$/$newallgroups/" $SCRIPT_HOME/manageSKFSCreds.sh

        echo "Added Group: '$GROUP_NAME'"
        exit 0
fi
if [ "$OPERATION" = "addUserToGroup" ]; then
        if [[ ! $(ldapsearch -Y external -H ldapi:/// -b "$SERVICE_LDAP_BASEDN" cn="$USERNAME" -LLL 2> /dev/null) =~ "$USERNAME" ]]; then
                echo "User '$USERNAME' does not exist."
                exit 1
        fi

        groups="$4"
        if [ -z $groups ];then
		usage
		exit 1
        fi
        IFS=','
        read -a groupsarr <<< "$groups"
        for group in "${groupsarr[@]}";
        do
                if [[ "$allgroups" == *"$group"* ]]; then
                        cat > /tmp/ldapgroup.ldif << LDAPUSER
dn: cn=$group,did=$SAKA_DID,ou=groups,ou=v2,ou=SKCE,ou=StrongAuth,ou=Applications,$SERVICE_LDAP_BASEDN
changetype: modify
add: uniqueMember
uniqueMember: cn=$USERNAME,did=$SAKA_DID,ou=users,ou=v2,ou=SKCE,ou=StrongAuth,ou=Applications,$SERVICE_LDAP_BASEDN
LDAPUSER
                        ldapmodify -x -w  "$SERVICE_LDAP_BIND_PASS" -D "cn=Manager,$SERVICE_LDAP_BASEDN" -f /tmp/ldapgroup.ldif 2> /tmp/Error
                        ERROR=$(</tmp/Error)
                        rm /tmp/ldapgroup.ldif /tmp/Error
                        if [ -z "$ERROR" ]; then
                                echo "Added User '$USERNAME' to Group '$group'"
				echo ""
                        else
                                if [[ "$ERROR" =~ "already exists" ]]; then 
					echo "User '$USERNAME' is already a part of Group '$group'"
					echo ""
				else
					#echo $ERROR
	                                echo "'$group' is not a valid Group for Users."
	                                exit 1
				fi
                        fi
                else
                        echo "'$group' is not a valid Group for Users."
                        exit 1
                fi
        done
        echo "Done!"
        exit 0
fi
if [ "$OPERATION" = "removeUserFromGroup" ]; then
        if [[ ! $(ldapsearch -Y external -H ldapi:/// -b "$SERVICE_LDAP_BASEDN" cn="$USERNAME" -LLL 2> /dev/null) =~ "$USERNAME" ]]; then
                echo "User '$USERNAME' does not exist."
                exit 1
        fi

        groups="$4"
        if [ -z $groups ];then
		usage
		exit 1
        fi
        IFS=','
        read -a groupsarr <<< "$groups"
        for group in "${groupsarr[@]}";
        do
                if [[ "$allgroups" == *"$group"* ]]; then
                        cat > /tmp/ldapgroup.ldif << LDAPUSER
dn: cn=$group,did=$SAKA_DID,ou=groups,ou=v2,ou=SKCE,ou=StrongAuth,ou=Applications,$SERVICE_LDAP_BASEDN
changetype: modify
delete: uniqueMember
uniqueMember: cn=$USERNAME,did=$SAKA_DID,ou=users,ou=v2,ou=SKCE,ou=StrongAuth,ou=Applications,$SERVICE_LDAP_BASEDN
LDAPUSER
                        ldapmodify -x -w  "$SERVICE_LDAP_BIND_PASS" -D "cn=Manager,$SERVICE_LDAP_BASEDN" -f /tmp/ldapgroup.ldif 2> /tmp/Error
                        ERROR=$(</tmp/Error)
                        rm /tmp/ldapgroup.ldif /tmp/Error
                        if [ -z "$ERROR" ]; then
                                echo "Removed User '$USERNAME' from Group '$group'"
				echo ""
                        else
				if [[ "$ERROR" =~ "uniqueMember: no such value" ]]; then
                                        echo "User '$USERNAME' is not a part of Group '$group'"
					echo ""
                                else
                                        #echo $ERROR
                                        echo "'$group' is not a valid Group for Users."
                                        exit 1
                                fi
                        fi
                else
                        echo "'$group' is not a valid Group for Users."
                        exit 1
                fi
        done
        echo "Done!"
        exit 0
fi
if [ "$OPERATION" = "deleteUser" ]; then
        if [[ ! $(ldapsearch -Y external -H ldapi:/// -b "$SERVICE_LDAP_BASEDN" cn="$USERNAME" -LLL 2> /dev/null) =~ "$USERNAME" ]]; then
                echo "User '$USERNAME' does not exist."
                exit 1
        fi

        IFS=','
        read -a groupsarr <<< "$allgroups"
        for group in "${groupsarr[@]}";
        do
                cat > /tmp/ldapgroup.ldif << LDAPUSER
dn: cn=$group,did=$SAKA_DID,ou=groups,ou=v2,ou=SKCE,ou=StrongAuth,ou=Applications,$SERVICE_LDAP_BASEDN
changetype: modify
delete: uniqueMember
uniqueMember: cn=$USERNAME,did=$SAKA_DID,ou=users,ou=v2,ou=SKCE,ou=StrongAuth,ou=Applications,$SERVICE_LDAP_BASEDN
LDAPUSER
                ldapmodify -x -w  "$SERVICE_LDAP_BIND_PASS" -D "cn=Manager,$SERVICE_LDAP_BASEDN" -f /tmp/ldapgroup.ldif 2> /tmp/Error 1> /dev/null
                ERROR=$(</tmp/Error)
                rm /tmp/ldapgroup.ldif /tmp/Error
                if [ -z "$ERROR" ]; then
                        echo "Removed User '$USERNAME' from Group '$group'"
                fi
        done
        ldapdelete -x -w  "$SERVICE_LDAP_BIND_PASS" -D "cn=Manager,$SERVICE_LDAP_BASEDN" "cn=$USERNAME,did=$SAKA_DID,ou=users,ou=v2,ou=SKCE,ou=StrongAuth,ou=Applications,$SERVICE_LDAP_BASEDN"
        echo "Deleted User: '$USERNAME'"
        exit 0
fi
if [ "$OPERATION" = "changeUserPassword" ] ; then
        if [[ ! $(ldapsearch -Y external -H ldapi:/// -b "$SERVICE_LDAP_BASEDN" cn="$USERNAME" -LLL 2> /dev/null) =~ "$USERNAME" ]]; then
                echo "User '$USERNAME' does not exist."
                exit 1
        fi

        #PASSWORD_CHANGE_RESULT=$(ldappasswd -v -x -w  "$SERVICE_LDAP_BIND_PASS" -D "cn=Manager,$SERVICE_LDAP_BASEDN" -S "cn=$USERNAME,did=$SAKA_DID,ou=users,ou=v2,ou=SKCE,ou=StrongAuth,ou=Applications,$SERVICE_LDAP_BASEDN")
        ldappasswd -x -w  "$SERVICE_LDAP_BIND_PASS" -D "cn=Manager,$SERVICE_LDAP_BASEDN" -S "cn=$USERNAME,did=$SAKA_DID,ou=users,ou=v2,ou=SKCE,ou=StrongAuth,ou=Applications,$SERVICE_LDAP_BASEDN"
        if [ $? -eq 1 ]; then
		echo "Change Password Failed for User: '$USERNAME'"
		exit 1
        fi
        echo "Changed Password for User: '$USERNAME'"
        exit 0
fi
if [ "$OPERATION" = "getUserGroups" ]; then
        if [[ ! $(ldapsearch -Y external -H ldapi:/// -b "$SERVICE_LDAP_BASEDN" cn="$USERNAME" -LLL 2> /dev/null) =~ "$USERNAME" ]]; then
                echo "User '$USERNAME' does not exist."
                exit 1
        fi

        GROUPS_OUTPUT=$(ldapsearch -LLL -Y external -H ldapi:/// -b "$SERVICE_LDAP_BASEDN" "uniqueMember=cn=$USERNAME,did=$SAKA_DID,ou=users,ou=v2,ou=SKCE,ou=StrongAuth,ou=Applications,$SERVICE_LDAP_BASEDN" 2> /dev/null | grep dn -A 1 --color=never)
        if [[ -z $GROUPS_OUTPUT ]]; then
                echo "'$USERNAME' is not a part of any groups."
        else
		echo "'$USERNAME' is a part of the following groups:"
		echo ""
                echo "$GROUPS_OUTPUT"
        fi
        exit 0
fi

usage
exit 1
