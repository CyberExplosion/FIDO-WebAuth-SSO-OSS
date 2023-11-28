#!/bin/bash
#
###############################################################
# /**
# * Copyright StrongAuth, Inc. All Rights Reserved.
# *
# * Use of this source code is governed by the GNU Lesser General Public License v2.1
# * The license can be found at https://github.com/StrongKey/fido2/blob/master/LICENSE
# */
###############################################################

. /etc/skfsrc

CURRENT_SKFS_BUILDNO=$(ls -1 $STRONGKEY_HOME/fido/Version* 2> /dev/null | sed -r 's|.*VersionFidoServer-||')

SCRIPT_HOME=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

SOFTWARE_HOME=/usr/local/software
STRONGKEY_HOME=/usr/local/strongkey

GLASSFISH_HOME=$STRONGKEY_HOME/payara5/glassfish
MARIA_HOME=$STRONGKEY_HOME/mariadb-10.6.8

GLASSFISH_ADMIN_PASSWORD=adminadmin
MARIA_ROOT_PASSWORD=BigKahuna
MARIA_SKFSDBUSER_PASSWORD=AbracaDabra
SERVICE_LDAP_BIND_PASS=Abcd1234!
SERVICE_LDAP_BASEDN='dc=strongauth,dc=com'

SAKA_DID=1

ROLLBACK=Y

# 4.7.0 Upgrade Variables
SAML_RESPONSE=false
SAML_CITRIX=false
SAML_DURATION=15
SAML_KEYGEN_DN='/C=US/ST=California/L=Cupertino/O=StrongAuth/OU=Engineering'
SAML_CERTS_PER_SERVER=3
SAML_TIMEZONE=UTC
SAML_KEYSTORE_PASS=Abcd1234!
SAML_KEY_VALIDITY=365

# 4.8.0 Upgrade Variables
CROSS_ORIGIN_ENABLED=false

# 4.9.0 Upgrade Variables
DELETE_OLD_POLICIES=false
AUTH_RETURN_RESPONSE_LEVEL=0

# 4.10.0 Upgrade Variables
SSO_KEYSTORE_PASS=Abcd1234!
JWT_KEYGEN_DN='OU=DID {domain}, O=StrongKey'
JWT_CN_LIST="CN=SKFS JWT Signer 1,CN=SKFS JWT Signer 2,CN=SKFS JWT Signer 3"
JWT_KEY_VALIDITY=365
SAML_KEYGEN_DN_410='OU=DID {domain}, O=StrongKey'
SAML_CN_LIST_410="CN=SKFS SAML Signer 1,CN=SKFS SAML Signer 2,CN=SKFS SAML Signer 3"
SAML_KEY_VALIDITY_410=365
AUTH_RETAIN_CHALLENGE=false

function check_exists {
for ARG in "$@"
do
    if [ ! -f $ARG ]; then
        >&2 echo -e "$ARG Not Found. Check to ensure the file exists in the proper location and try again."
        exit 1
    fi
done
}

function version_less_than { # Is first version num less than second version num
        first_num=$(echo $1 | sed 's/[^0-9.]//g') # Strip everything except numbers and periods
        second_num=$(echo $2 | sed 's/[^0-9.]//g')
        if [[ $first_num == $second_num ]]; then
                echo 'false'
        else
                before=$(printf "%s\n" "$first_num" "$second_num")
                sorted=$(sort -V <<<"$before")
                if [[ $before == $sorted ]]; then
                        echo 'true'
                else
                        echo 'false'
                fi
        fi
}

# Check that the script is run as root
if [ "$(whoami)" != "root" ]; then
        >&2 echo "$0 must be run as root"
        exit 1
fi

# Check that variables are set
if [ -z $GLASSFISH_HOME ]; then
        >&2 echo "Variable GLASSFISH_HOME not set correctly."
        exit 1
fi

# Check glassfish status
if ! ps -efww | grep "$GLASSFISH_HOME/modules/glassfish.ja[r]" &>/dev/null; then
        >&2 echo "Glassfish must be running in order to perform this upgrade"
        exit 1
fi

# Get GlassFish admin password
echo "$GLASSFISH_ADMIN_PASSWORD" > /tmp/password
while ! $GLASSFISH_HOME/bin/asadmin --user admin --passwordfile /tmp/password list . &> /dev/null; do
        echo -n "This upgrade requires the glassfish 'admin' password. Please enter the password now: "
        echo
        read -s GLASSFISH_ADMIN_PASSWORD
        echo "AS_ADMIN_PASSWORD=$GLASSFISH_ADMIN_PASSWORD" > /tmp/password
done

# Check that the SKFS is at least version 4.6.0, when the SKFS switched to jdk 11
if [[ $CURRENT_SKFS_BUILDNO < "4.6.0" ]]; then
	>&2 echo "SKFS must be at least version 4.6.0 in order to upgrade using this script."
	exit 1
fi

# Determine which package manager is on the system
YUM_CMD=$(which yum  2>/dev/null)
APT_GET_CMD=$(which apt-get 2>/dev/null)

# Undeploy SKFS
echo
echo "Undeploying old skfs build..."
$GLASSFISH_HOME/bin/asadmin --user admin --passwordfile /tmp/password undeploy fidoserver

# Start upgrade to 4.7.0
if [ $(version_less_than $CURRENT_SKFS_BUILDNO "4.7.0") = "true" ]; then
        echo "Upgrading to 4.7.0"

        echo "
skfs.cfg.property.saml.response=$SAML_RESPONSE
skfs.cfg.property.saml.certsperserver=$SAML_CERTS_PER_SERVER
skfs.cfg.property.saml.timezone=$SAML_TIMEZONE
skfs.cfg.property.saml.citrix=$SAML_CITRIX
skfs.cfg.property.saml.assertion.duration=$SAML_DURATION
skfs.cfg.property.saml.issuer.entity.name=https://$(hostname)/" >> $STRONGKEY_HOME/skfs/etc/skfs-configuration.properties

        if [ $(version_less_than $LATEST_SAKA_BUILDNO "4.10.0") = "true" ]; then
                # Generate SAML keystores
                $SCRIPT_HOME/keygen-saml.sh $SAML_KEYGEN_DN $($MARIA_HOME/bin/mysql -u skfsdbuser -p${MARIA_SKFSDBUSER_PASSWORD} skfs -B --skip-column-names -e "select count(fqdn) from servers;") $SAML_CERTS_PER_SERVER $SAKA_DID $SAML_KEYSTORE_PASS $SAML_KEY_VALIDITY
                NUM_DOMAINS=$($MARIA_HOME/bin/mysql -u skfsdbuser -p${MARIA_SKFSDBUSER_PASSWORD} skfs -B --skip-column-names -e "select count(*) from domains;")
                for (( DID = 2; DID <= $NUM_DOMAINS ; DID++ ))
                do
                        $SCRIPT_HOME/keygen-saml.sh $SAML_KEYGEN_DN $($MARIA_HOME/bin/mysql -u skfsdbuser -p${MARIA_SKFSDBUSER_PASSWORD} skfs -B --skip-column-names -e "select count(fqdn) from servers;") $SAML_CERTS_PER_SERVER $DID $SAML_KEYSTORE_PASS $SAML_KEY_VALIDITY
                done
                chown strongkey:strongkey $STRONGKEY_HOME/skfs/keystores/samlsigningtruststore.bcfks $STRONGKEY_HOME/skfs/keystores/samlsigningkeystore.bcfks
        fi

        mv $STRONGKEY_HOME/fido/VersionFidoServer-4.6.0 $STRONGKEY_HOME/fido/VersionFidoServer-4.7.0
fi # End of 4.7.0 Upgrade

# Start upgrade to 4.8.0
if [ $(version_less_than $CURRENT_SKFS_BUILDNO "4.8.0") = "true" ]; then
	echo "Upgrading to 4.8.0"

	# Cross Origin Policy changes
	for pid in $($MARIA_HOME/bin/mysql -u skfsdbuser -p${MARIA_SKFSDBUSER_PASSWORD} skfs -B --skip-column-names -e "select pid from fido_policies order by pid asc;"); do
		newpolicy=$(echo $($MARIA_HOME/bin/mysql -u skfsdbuser -p${MARIA_SKFSDBUSER_PASSWORD} skfs -B --skip-column-names -e "select policy from fido_policies where pid=$pid;") | /usr/bin/base64 --decode | tr -d '\n' | tr -d '\t' | sed "s/}\s*}\s*$/,\"crossOrigin\":{\"enabled\":$CROSS_ORIGIN_ENABLED,\"allowedOrigins\":[]}}}/" | /usr/bin/base64 -w 0)
		$MARIA_HOME/bin/mysql -u skfsdbuser -p${MARIA_SKFSDBUSER_PASSWORD} skfs -e "update fido_policies set policy='$newpolicy' where pid=$pid;"
	done

	if [ "$CROSS_ORIGIN_ENABLED" = "true" ]; then
		echo "Cross Origin has been enabled in all existig policies, but list of allowed origins are not yet set in the policy json. Please manually update the policies in the database and add any allowed origins."
	fi

	mv $STRONGKEY_HOME/fido/VersionFidoServer-4.7.0 $STRONGKEY_HOME/fido/VersionFidoServer-4.8.0
fi # End of 4.8.0 Upgrade

# Start upgrade to 4.9.0
if [ $(version_less_than $CURRENT_SKFS_BUILDNO "4.9.0") = "true" ]; then
        echo "Upgrading to 4.9.0"

	# Add last_used_date column to fido_keys table
	$MARIA_HOME/bin/mysql -u skfsdbuser -p${MARIA_SKFSDBUSER_PASSWORD} skfs -e "alter table fido_keys add last_used_date DATETIME NULL after create_location;"

	# If DELETE_OLD_POLICIES flag is set to true, only keep the earliest active policy per domain in the database and delete the others, otherwise set all others to inactive
	if [ "$DELETE_OLD_POLICIES" = "true" ]; then
		# Delete all other policies
		for did in $($MARIA_HOME/bin/mysql -u skfsdbuser -p${MARIA_SKFSDBUSER_PASSWORD} skfs -B --skip-column-names -e "select distinct did from fido_policies order by did asc;"); do
			# Get pid of newest active policy by creation date and mysqldump that single record using the pid
			newest_policy_pid=$($MARIA_HOME/bin/mysql -u skfsdbuser -p${MARIA_SKFSDBUSER_PASSWORD} skfs -B --skip-column-names -e "select pid from fido_policies where did=$did and status='Active' order by create_date desc limit 1;")
			$MARIA_HOME/bin/mysqldump --no-create-info -u skfsdbuser -p${MARIA_SKFSDBUSER_PASSWORD} skfs fido_policies -w"pid=$newest_policy_pid" > /tmp/domain${did}_policy.sql
			# Delete all policies per domain
			$MARIA_HOME/bin/mysql -u skfsdbuser -p${MARIA_SKFSDBUSER_PASSWORD} skfs -e "delete from fido_policies where did=$did;"
			# Re-insert saved policy
			$MARIA_HOME/bin/mysql -u skfsdbuser -p${MARIA_SKFSDBUSER_PASSWORD} skfs -e "source /tmp/domain${did}_policy.sql;"
		done
	else
		# Set all other policies to Inactive
		for did in $($MARIA_HOME/bin/mysql -u skfsdbuser -p${MARIA_SKFSDBUSER_PASSWORD} skfs -B --skip-column-names -e "select distinct did from fido_policies order by did asc;"); do
			# Get pid of newest active policy by creation date and mysqldump that single record using the pid
			newest_policy_pid=$($MARIA_HOME/bin/mysql -u skfsdbuser -p${MARIA_SKFSDBUSER_PASSWORD} skfs -B --skip-column-names -e "select pid from fido_policies where did=$did and status='Active' order by create_date desc limit 1;")
			# Set all policies in the current domain that arent the newest policy to Inactive
			for not_newest_policy_pid in $($MARIA_HOME/bin/mysql -u skfsdbuser -p${MARIA_SKFSDBUSER_PASSWORD} skfs -B --skip-column-names -e "select pid from fido_policies where did=$did and status='Active' and pid!=$newest_policy_pid;"); do
				$MARIA_HOME/bin/mysql -u skfsdbuser -p${MARIA_SKFSDBUSER_PASSWORD} skfs -e "update fido_policies set status='Inactive' where pid=$not_newest_policy_pid;"
			done
		done
	fi
	
	if [ -d $STRONGKEY_HOME/skfsclient ]; then
		mv $STRONGKEY_HOME/skfsclient $STRONGKEY_HOME/skfsclient.old
	fi
	cp -r $SCRIPT_HOME/skfsclient $SCRIPT_HOME/skfsadminclient $SCRIPT_HOME/fidoanalyzer $STRONGKEY_HOME
	chown -R strongkey. $STRONGKEY_HOME/skfsclient $STRONGKEY_HOME/skfsadminclient $STRONGKEY_HOME/fidoanalyzer

	echo "skfs.cfg.property.auth.return.responselevel=$AUTH_RETURN_RESPONSE_LEVEL" >> $STRONGKEY_HOME/skfs/etc/skfs-configuration.properties

	mv $STRONGKEY_HOME/fido/VersionFidoServer-4.8.0 $STRONGKEY_HOME/fido/VersionFidoServer-4.9.0
fi # End of 4.9.0 Upgrade

# Start upgrade to 4.10.0
if [ $(version_less_than $CURRENT_SKFS_BUILDNO "4.10.0") = "true" ]; then
        echo "Upgrading to 4.10.0"

        sed -i '/export STRONGKEY_HOME/a export SKFS_HOME=/usr/local/strongkey/skfs' /etc/skfsrc
        . /etc/skfsrc

        # Must stop and start glassfish for environment variable change to take
        service glassfishd stop
        service glassfishd start

        # Determine whether to create jwt or saml keys/certs based on existing/default properties
        JWT_CREATE=$(cat $STRONGKEY_HOME/skfs/etc/skfs-configuration.properties | grep "skfs.cfg.property.jwt.create=" | sed 's/skfs.cfg.property.jwt.create=//g')
        SAML_RESPONSE=$(cat $STRONGKEY_HOME/skfs/etc/skfs-configuration.properties | grep "skfs.cfg.property.saml.response=" | sed 's/skfs.cfg.property.saml.response=//g')
        # If properties did not exist in property file, set to defaults
        if [[ -z "${JWT_CREATE,,}" ]]; then
               JWT_CREATE=true # Default value
        fi
        if [[ -z "${SAML_RESPONSE,,}" ]]; then
               SAML_RESPONSE=false # Default value
        fi

        # Generate new sets of keys
        cd $STRONGKEY_HOME/skfs/keystores
        for did in $($MARIA_HOME/bin/mysql -u skfsdbuser -p${MARIA_SKFSDBUSER_PASSWORD} skfs -B --skip-column-names -e "select distinct did from fido_policies order by did asc;"); do
                $SCRIPT_HOME/keygen-sso.sh -jwt -did $did -dn "$(echo $JWT_KEYGEN_DN | sed -e "s/{domain}/$did/g")" -jwtcns "$JWT_CN_LIST" -p "$SSO_KEYSTORE_PASS" -v "$JWT_KEY_VALIDITY"
        done
        for did in $($MARIA_HOME/bin/mysql -u skfsdbuser -p${MARIA_SKFSDBUSER_PASSWORD} skfs -B --skip-column-names -e "select distinct did from fido_policies order by did asc;"); do
                $SCRIPT_HOME/keygen-sso.sh -saml -did $did -dn "$(echo $SAML_KEYGEN_DN_410 | sed -e "s/{domain}/$did/g")" -samlcns "$SAML_CN_LIST_410" -p "$SSO_KEYSTORE_PASS" -v "$SAML_KEY_VALIDITY_410"
        done
        chown -R strongkey. $STRONGKEY_HOME/skfs/keystores

        # Convert existing policies to new policy format
        cd $STRONGKEY_HOME/skfs/keystores/sso-keys
        JWT_CN_COUNT=$(($(echo $JWT_CN_LIST | tr -cd ',' | wc -c)+1))
        SAML_CN_COUNT=$(($(echo $SAML_CN_LIST_410 | tr -cd ',' | wc -c)+1))

        for did in $($MARIA_HOME/bin/mysql -u skfsdbuser -p${MARIA_SKFSDBUSER_PASSWORD} skfs -B --skip-column-names -e "select distinct did from fido_policies where status='Active' order by did asc;"); do
                $MARIA_HOME/bin/mysql -u skfsdbuser -p${MARIA_SKFSDBUSER_PASSWORD} skfs -B --skip-column-names -e "select policy from fido_policies where did=$did and status='Active';" > /tmp/tempPolicy
                mkdir -p $STRONGKEY_HOME/backups
                cp /tmp/tempPolicy $STRONGKEY_HOME/backups/4.10.0-upgrade-skfspolicy-did${did}.txt

                ## Remove deprecated policy values
                java -jar $SCRIPT_HOME/SKFSPolicyManager/SKFSPolicyManager.jar -cli -i "$(cat /tmp/tempPolicy)" -d '/FidoPolicy/system/jwtKeyValidity' -ot base64 > /tmp/tempPolicy
                java -jar $SCRIPT_HOME/SKFSPolicyManager/SKFSPolicyManager.jar -cli -i "$(cat /tmp/tempPolicy)" -d '/FidoPolicy/system/jwtRenewalWindow' -ot base64 > /tmp/tempPolicy
                java -jar $SCRIPT_HOME/SKFSPolicyManager/SKFSPolicyManager.jar -cli -i "$(cat /tmp/tempPolicy)" -d '/FidoPolicy/jwt/signingCerts' -ot base64 > /tmp/tempPolicy

                ## Add 4.10 policy values
                java -jar $SCRIPT_HOME/SKFSPolicyManager/SKFSPolicyManager.jar -cli -i "$(cat /tmp/tempPolicy)" -an '/FidoPolicy/system/did' $did -ot base64 > /tmp/tempPolicy

                ROOT_CA_SUBJECT_DN=$(openssl x509 -in ssoca-$did.pem -noout -subject -nameopt rfc2253 | awk -F 'subject=' '{print $2}')
                ROOT_CA_SERIAL=$((16#$(openssl x509 -in ssoca-$did.pem -noout -serial | awk -F 'serial=' '{print $2}')))
                ROOT_CA_PEM="$(cat ssoca-$did.pem | tr -d $'\r' | tr -d '\n')"
                java -jar $SCRIPT_HOME/SKFSPolicyManager/SKFSPolicyManager.jar -cli -i "$(cat /tmp/tempPolicy)" -ao '/FidoPolicy/signcerts' "{\"rootca\":{\"subjectdn\":\"$ROOT_CA_SUBJECT_DN\",\"serialnumber\":\"$ROOT_CA_SERIAL\",\"pemcert\":\"$ROOT_CA_PEM\",\"jwtcerts\":{\"default\":[]},\"samlcerts\":{\"default\":[],\"citrixidp\":{\"subjectdn\":\"CN=SKFS SAML Signer 1,$(echo $SAML_KEYGEN_DN_410 | sed -e "s/{domain}/$did/g")\",\"serialnumber\":\"$((16#$(openssl x509 -in samlsigning-$did-1.pem -noout -serial | awk -F 'serial=' '{print $2}')))\",\"pemcert\":\"$(cat samlsigning-$did-1.pem | tr -d $'\r' | tr -d '\n')\"}}}}" -ot base64 > /tmp/tempPolicy
                for (( CERT_NUM = 1; CERT_NUM <= JWT_CN_COUNT; CERT_NUM++ )); do
                        JWT_SUBJECT_DN=$(openssl x509 -in jwtsigning-$did-$CERT_NUM.pem -noout -subject -nameopt rfc2253 | awk -F 'subject=' '{print $2}')
                        JWT_SERIAL=$((16#$(openssl x509 -in jwtsigning-$did-$CERT_NUM.pem -noout -serial | awk -F 'serial=' '{print $2}')))
                        JWT_PEM="$(cat jwtsigning-$did-$CERT_NUM.pem | tr -d $'\r' | tr -d '\n')"
                        java -jar $SCRIPT_HOME/SKFSPolicyManager/SKFSPolicyManager.jar -cli -i "$(cat /tmp/tempPolicy)" -ao '/FidoPolicy/signcerts/rootca/jwtcerts/default/-' "{\"subjectdn\":\"$JWT_SUBJECT_DN\",\"serialnumber\":\"$JWT_SERIAL\",\"pemcert\":\"$JWT_PEM\"}" -ot base64 > /tmp/tempPolicy
                done
                for (( CERT_NUM = 1; CERT_NUM <= SAML_CN_COUNT; CERT_NUM++ )); do
                        SAML_SUBJECT_DN=$(openssl x509 -in samlsigning-$did-$CERT_NUM.pem -noout -subject -nameopt rfc2253 | awk -F 'subject=' '{print $2}')
                        SAML_SERIAL=$((16#$(openssl x509 -in samlsigning-$did-$CERT_NUM.pem -noout -serial | awk -F 'serial=' '{print $2}')))
                        SAML_PEM="$(cat samlsigning-$did-$CERT_NUM.pem | tr -d $'\r' | tr -d '\n')"
                        java -jar $SCRIPT_HOME/SKFSPolicyManager/SKFSPolicyManager.jar -cli -i "$(cat /tmp/tempPolicy)" -ao '/FidoPolicy/signcerts/rootca/samlcerts/default/-' "{\"subjectdn\":\"$SAML_SUBJECT_DN\",\"serialnumber\":\"$SAML_SERIAL\",\"pemcert\":\"$SAML_PEM\"}" -ot base64 > /tmp/tempPolicy
                done
                # Handle citrix saml key
                SAML_CITRIX=$(cat $STRONGKEY_HOME/skfs/etc/skfs-configuration.properties | grep "skfs.cfg.property.saml.citrix=" | sed 's/skfs.cfg.property.saml.citrix=//g')
                if [ "${SAML_CITRIX,,}" = "true" ]; then
                        java -jar $SCRIPT_HOME/SKFSPolicyManager/SKFSPolicyManager.jar -cli -i "$(cat /tmp/tempPolicy)" -ao '/FidoPolicy/signcerts/rootca/samlcerts/citrixidp' "{\"subjectdn\":\"CN=SKFS SAML Signer 1,$(echo $SAML_KEYGEN_DN_410 | sed -e "s/{domain}/$did/g")\",\"serialnumber\":\"$((16#$(openssl x509 -in samlsigning-$did-1.pem -noout -serial | awk -F 'serial=' '{print $2}')))\",\"pemcert\":\"$(cat samlsigning-$did-1.pem | tr -d $'\r' | tr -d '\n')\"}" -ot base64 > /tmp/tempPolicy
                fi

                java -jar $SCRIPT_HOME/SKFSPolicyManager/SKFSPolicyManager.jar -cli -i "$(cat /tmp/tempPolicy)" --parse
                if [ $? -eq 1 ]; then
                    echo "New SKFS FIDO Policy for domain $did cannot be parsed by SKFS. Please check upgrade script inputs. The policy that failed to parse can be located at /tmp/tempPolicy"
                    exit 1
                fi

                cp -r $SCRIPT_HOME/SKFSPolicyManager $STRONGKEY_HOME
                chown -R strongkey. $STRONGKEY_HOME/SKFSPolicyManager
                
                # Update policy
                $MARIA_HOME/bin/mysql -u skfsdbuser -p${MARIA_SKFSDBUSER_PASSWORD} skfs -e "update fido_policies set policy='$(cat /tmp/tempPolicy)' where did=$did and status='Active';"
                rm /tmp/tempPolicy
        done

        # Convert jwt crypto properties to skfs properties
        cat $STRONGKEY_HOME/crypto/etc/crypto-configuration.properties | grep "crypto.cfg.property.jwtsigning" | sed -e "s/crypto/skfs/g" | sed -e "s/keystores\/jwtsigning/keystores\/ssosigning/g" >> $STRONGKEY_HOME/skfs/etc/skfs-configuration.properties
        echo "skfs.cfg.property.retainauthenticatechallenge=$AUTH_RETAIN_CHALLENGE" >> $STRONGKEY_HOME/skfs/etc/skfs-configuration.properties
        echo "skfs.cfg.property.jwtsigning.password=$SSO_KEYSTORE_PASS" >> $STRONGKEY_HOME/skfs/etc/skfs-configuration.properties
        echo "skfs.cfg.property.saml.keystore.password=$SSO_KEYSTORE_PASS" >> $STRONGKEY_HOME/skfs/etc/skfs-configuration.properties

        # Comment out deprecated jwt/saml properties and move deprecated keystores
        sed -i "s/crypto.cfg.property.jwtsigning/#crypto.cfg.property.jwtsigning/g" $STRONGKEY_HOME/crypto/etc/crypto-configuration.properties
        sed -i "/certsperserver/s/^/#/" $STRONGKEY_HOME/skfs/etc/skfs-configuration.properties
        mkdir -p $STRONGKEY_HOME/skfs/keystores/deprecated
        mv $STRONGKEY_HOME/skfs/keystores/jwtsigning*.bcfks $STRONGKEY_HOME/skfs/keystores/deprecated
        if [ $(version_less_than $CURRENT_SAKA_BUILDNO "4.8.0") = "false" ]; then # If current version already had saml signing keystore (if upgrading from <4.8.0, no saml singing keystore is created anymore since keygen-saml is deprecated)
                mv $STRONGKEY_HOME/skfs/keystores/samlsigning*.bcfks $STRONGKEY_HOME/skfs/keystores/deprecated
        fi
        chown -R strongkey. $STRONGKEY_HOME/skfs/keystores/deprecated

        # Create new index on fido_keys table in DB
        $MARIA_HOME/bin/mysql -u skfsdbuser -p${MARIA_SKFSDBUSER_PASSWORD} skfs -B --skip-column-names -e "create index didkh on fido_keys (did, keyhandle);"

        mv $STRONGKEY_HOME/fido/VersionFidoServer-4.9.0 $STRONGKEY_HOME/fido/VersionFidoServer-4.10.0
fi # End of 4.10.0 Upgrade

# Start Glassfish
echo
echo "Starting Glassfish..."
service glassfishd restart

#adding sleep to ensure glassfish starts up correctly
sleep 10

# Deploy NEW SKFS
echo
echo "Deploying new skfs build..."

check_exists "$SCRIPT_HOME/fidoserver.ear"

cp $SCRIPT_HOME/fidoserver.ear /tmp
# Deploy SKFS
$GLASSFISH_HOME/bin/asadmin --user admin --passwordfile /tmp/password deploy /tmp/fidoserver.ear

rm /tmp/fidoserver.ear
rm /tmp/password

echo
echo "Restarting glassfish..."
service glassfishd restart

echo
echo "Upgrade finished!"

exit 0
