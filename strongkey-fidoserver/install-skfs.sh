#!/bin/bash
###################################################################################
# /**
# * Copyright StrongAuth, Inc. All Rights Reserved.
# *
# * Use of this source code is governed by the GNU Lesser General Public License v2.1
# * The license can be found at https://github.com/StrongKey/fido2/blob/master/LICENSE
# */
###################################################################################
# Uncomment to show detailed installation process
#SHOWALL=1

##########################################
##########################################
# Fido Server Info
FIDOSERVER_VERSION=4.10.0

# Server Passwords
LINUX_PASSWORD=ShaZam123
MARIA_ROOT_PASSWORD=BigKahuna
MARIA_SKFSDBUSER_PASSWORD=AbracaDabra

XMXSIZE=512m
BUFFERPOOLSIZE=512m

# SSO
SSO_KEYSTORE_PASS=Abcd1234!

# JWT
RPID=strongkey.com
JWT_CREATE=true
JWT_DURATION=30
JWT_KEYGEN_DN='OU=DID {domain}, O=StrongKey'
JWT_CN_LIST="CN=SKFS JWT Signer 1,CN=SKFS JWT Signer 2,CN=SKFS JWT Signer 3"
JWT_KEY_VALIDITY=365

# SAML
SAML_RESPONSE=false
SAML_CITRIX=false
SAML_DURATION=15
SAML_KEYGEN_DN='OU=DID {domain}, O=StrongKey'
SAML_CN_LIST="CN=SKFS SAML Signer 1,CN=SKFS SAML Signer 2,CN=SKFS SAML Signer 3"
SAML_TIMEZONE=UTC
SAML_KEY_VALIDITY=365
## External SAML keys
SAML_EXTERNAL_PROVIDED=false
SAML_EXTERNAL_DID=1
SAML_EXTERNAL_EXTENSION='p12'                   # p12 or jks
SAML_EXTERNAL_STOREPATH='/path/to/key.p12'
SAML_EXTERNAL_STOREPASS='12345678'
SAML_EXTERNAL_CERT_ALIAS='signatureCertAlias1,signatureCertAlias2,signatureCertAlias3'
SAML_EXTERNAL_KEY_ALIAS='signatureKeyAlias1,singatureKeyAlias2,singatureKeyAlias3'
SAML_EXTERNAL_KEY_PASS='12345678'               # Typically, the same password as the keystore password

# MDS
MDS_ENABLED=true        # Property that enables MDS download
MDS_RETURN=false        # Property to determine if MDS data should be returned in the JSON response.
MDS_RETURN_WS=R,A,G
MDS_MECHANISM=url                               	# Property that define the MDS fetch mechanism. Allowed options : URL / File
MDS_MECHANISM_URL=https://mds.fidoalliance.org/         # In case of 'file' the location can be a file on the local file system under the /usr/local/strongauth directory
MDS_ROOTCA_URL=http://secure.globalsign.com/cacert/root-r3.crt

# RESPONSE_DETAIL
RESPONSE_DETAIL=false			# Property to determine if webservices should return detailed information in response.
RESPONSE_DETAIL_WEBSERVICES=R,A		# Property to determine what webservices should return the detailed information. Default : R,A ( Reg / Auth ). Comma separated list of all the allowed web services example : R, or R,A or A and so on.
RESPONSE_DETAIL_FORMAT=default		# Property to determine the format for the returned response details. Allowed values : default | webauthn2
AUTH_RETURN_RESPONSE_LEVEL=0

# TODO
AUTH_RETAIN_CHALLENGE=false     # TODO

# Policy
POLICY_DOMAINS=ALL	# 'ALL' or 'ONE'
CROSS_ORIGIN_ENABLED=false

##########################################
##########################################

# Flags to indicate if a module should be installed
INSTALL_GLASSFISH=Y
INSTALL_OPENLDAP=Y
INSTALL_MARIA=Y

# Start Required Distributables
GLASSFISH=payara-5.2021.6.zip
JEMALLOC=jemalloc-3.6.0-1.el7.x86_64.rpm
MARIA=mariadb-10.6.8-linux-systemd-x86_64.tar.gz
MARIACONJAR=mariadb-java-client-2.2.6.jar
# End Required Distributables

OPENLDAP_PASS=Abcd1234!
SERVICE_LDAP_BASEDN='dc=strongauth,dc=com'
SAKA_DID=1
SERVICE_LDAP_SVCUSER_PASS=Abcd1234!
SKFS_LDIF=skfs.ldif

# Other vars
STRONGKEY_HOME=/usr/local/strongkey
SKFS_HOME=$STRONGKEY_HOME/skfs
GLASSFISH_HOME=$STRONGKEY_HOME/payara5/glassfish
GLASSFISH_CONFIG=$GLASSFISH_HOME/domains/domain1/config
MARIAVER=mariadb-10.6.8-linux-systemd-x86_64
MARIATGT=mariadb-10.6.8
MARIA_HOME=$STRONGKEY_HOME/$MARIATGT
SKFS_SOFTWARE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SKFS_BASE_LDIF=skfs-base.ldif
ALLOW_USERNAME_CHANGE=false

function check_exists {
for ARG in "$@"
do
    if [ ! -f $ARG ]; then
        >&2 echo -e "\E[31m$ARG Not Found. Check to ensure the file exists in the proper location and try again.\E[0m"
        exit 1
    fi
done
}

function get_ip {
        # Try using getent if it is available, best option
        if ! getent hosts $1 2>/dev/null | awk '{print $1; succ=1} END{exit !succ}'; then

                # If we are here, likely don't have getent. Try reading /etc/hosts.
                if ! awk "/^[^#].*$1/ "'{ print $1; succ=1} END{exit !succ}' /etc/hosts; then

                        # Wasn't in /etc/hosts, try DNS
                        if ! dig +short +time=2 +retry=1 +tries=1 $1 | grep '.' 2>/dev/null; then

                                # Can't resolve IP
                                >&2 echo -e "\E[31mFQDN $1 not resolvable. Modify DNS or add a hosts entry and try again.\E[0m"
                                exit 1
                        fi
                fi
        fi
}

# install required packages
YUM_CMD=$(which yum  2>/dev/null)
APT_GET_CMD=$(which apt-get 2>/dev/null)

echo -n "Installing required linux packages (openjdk, unzip, libaio, ncurses-compat-libs[only applicable for Amazon Linux], rng-tools, curl) ... "
echo -n "The installer will skip packages that do not apply or are already installed. "
if [[ ! -z $YUM_CMD ]]; then
	yum -y install unzip libaio java-11-openjdk ncurses-compat-libs rng-tools curl >/dev/null 2>&1
	update-alternatives --set java java-11-openjdk.x86_64
	if [ $INSTALL_OPENLDAP = 'Y' ]; then
		if [[ $(cat /etc/system-release | grep "CentOS") ]]; then
			yum -y install openldap compat-openldap openldap-clients openldap-servers openldap-servers-sql openldap-devel >/dev/null 2>&1
			yum -y reinstall openldap compat-openldap openldap-clients openldap-servers openldap-servers-sql openldap-devel >/dev/null 2>&1
		elif [[ $(cat /etc/system-release | grep "Rocky") ]]; then
			dnf -y install openldap-servers openldap-clients >/dev/null 2>&1
			rm -f /usr/share/openldap-servers/UPGRADE_INSTRUCTIONS
		fi
	fi
	systemctl restart rngd
elif [[ ! -z $APT_GET_CMD ]]; then
	apt-get update >/dev/null 2>&1
	apt install unzip libncurses5 libaio1 dbus openjdk-11-jdk-headless daemon rng-tools curl -y >/dev/null 2>&1
	# modify rng tools to use dev urandom as the vm may not have a harware random number generator
	if ! grep -q "^HRNGDEVICE=/dev/urandom" /etc/default/rng-tools ; then
		echo "HRNGDEVICE=/dev/urandom" | sudo tee -a /etc/default/rng-tools
	fi
	systemctl restart rng-tools
else
   echo "error can't install packages"
   exit 1;
fi
echo "Successful"

JAVA_CMD=$(java -version 2>&1 >/dev/null | egrep "\S+\s+version")

if [[ ! -z $JAVA_CMD ]]; then
        :
else
        echo "java binary does not exist or cannot be executed"
        exit 1
fi

# download required software
if [ ! -f $SKFS_SOFTWARE/$GLASSFISH ]; then
        echo -n "Downloading Payara ... "
	wget https://repo1.maven.org/maven2/fish/payara/distributions/payara/5.2021.6/payara-5.2021.6.zip -q
        echo "Successful"
fi

if [ ! -f $SKFS_SOFTWARE/$MARIA ]; then
        echo -n "Downloading Mariadb Server ... "
	wget https://archive.mariadb.org/mariadb-10.6.8/bintar-linux-systemd-x86_64/mariadb-10.6.8-linux-systemd-x86_64.tar.gz -q
        echo "Successful"
fi

if [ ! -f $SKFS_SOFTWARE/$MARIACONJAR ]; then
        echo -n "Downloading Mariadb JAVA Connector ... "
        wget https://downloads.mariadb.com/Connectors/java/connector-java-2.2.6/mariadb-java-client-2.2.6.jar -q
        echo "Successful"
fi

if [ ! -f $SKFS_SOFTWARE/$JEMALLOC ]; then
        echo -n "Downloading Jemalloc ... "
        wget https://download-ib01.fedoraproject.org/pub/epel/7/x86_64/Packages/j/jemalloc-3.6.0-1.el7.x86_64.rpm -q
        echo "Successful"
fi

# Make sure we can resolve our own hostname
get_ip "$(hostname)" > /dev/null

# Check that the script is run as root
if [ $UID -ne 0 ]; then
        >&2 echo -e "\E[31m$0 must be run as root\E[0m"
        exit 1
fi

# Check that strongkey doesn't already exist
if $(id strongkey &> /dev/null); then
        >&2 echo -e "\E[31m'strongkey' user already exists. Run cleanup.sh and try again.\E[0m"
        exit 1
fi

# Check that all files are present
if [ $INSTALL_GLASSFISH = 'Y' ]; then
        check_exists $SKFS_SOFTWARE/$GLASSFISH
fi

if [ $INSTALL_MARIA = 'Y' ]; then
        check_exists $SKFS_SOFTWARE/$MARIA $SKFS_SOFTWARE/$JEMALLOC $SKFS_SOFTWARE/$MARIACONJAR
fi

check_exists $SKFS_SOFTWARE/signingkeystore.bcfks $SKFS_SOFTWARE/signingtruststore.bcfks

# Make backup directory if not there
if [ -d /etc/org ]; then
        :
else
        mkdir /etc/org
        if [ -f /etc/bashrc ]; then
                cp /etc/bashrc /etc/org
        else
                cp /etc/bash.bashrc /etc/org
        fi
        cp /etc/sudoers /etc/org
fi

# Config-related checks

# If using provided SAML keys/certs, check that the extension is correct
if [ "$SAML_EXTERNAL_PROVIDED" = "true" ]; then
        if [ "${SAML_EXTERNAL_EXTENSION^^}" = "P12" ]; then
                SAML_EXTERNAL_STORETYPE=PKCS12
        elif [ "${SAML_EXTERNAL_EXTENSION^^}" = "JKS" ]; then
                SAML_EXTERNAL_STORETYPE=JKS
        else
                echo "Invalid extension specified for provided SAML keystore: ${SAML_EXTERNAL_STOREPATH}. Only .p12 and .jks extensions allowed."
                exit 0
        fi
fi

# Create the strongkey group and user, and add it to /etc/sudoers
groupadd strongkey
useradd -g strongkey -c"StrongKey" -d $STRONGKEY_HOME -m strongkey
echo strongkey:$LINUX_PASSWORD | /usr/sbin/chpasswd
cat >> /etc/sudoers <<-EOFSUDOERS

## SKFS permissions
Cmnd_Alias SKFS_COMMANDS = /usr/sbin/service glassfishd start, /usr/sbin/service glassfishd stop, /usr/sbin/service glassfishd restart, /usr/sbin/service mysqld start, /usr/sbin/service mysqld stop, /usr/sbin/service mysqld restart, /usr/sbin/service slapd start, /usr/sbin/service slapd stop, /usr/sbin/service slapd restart, /usr/sbin/slapcat
strongkey ALL=SKFS_COMMANDS
EOFSUDOERS

##### Create skfsrc #####
cat > /etc/skfsrc << EOFSKFSRC
    export GLASSFISH_HOME=$GLASSFISH_HOME
        export MYSQL_HOME=$MARIA_HOME
    export STRONGKEY_HOME=$STRONGKEY_HOME
         export SKFS_HOME=$SKFS_HOME
              export PATH=\$GLASSFISH_HOME/bin:\$MYSQL_HOME/bin:\$STRONGKEY_HOME/bin:/usr/lib64/qt-3.3/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin:/root/bin

alias str='cd $STRONGKEY_HOME'
alias dist='cd $STRONGKEY_HOME/dist'
alias aslg='cd $GLASSFISH_HOME/domains/domain1/logs'
alias ascfg='cd $GLASSFISH_HOME/domains/domain1/config'
alias tsl='tail --follow=name $GLASSFISH_HOME/domains/domain1/logs/server.log'
alias mys='mysql -u skfsdbuser -p\`dbpass 2> /dev/null\` skfs'
alias lskc='mysql -u skfsdbuser -p\`dbpass 2> /dev/null\` skfs -e "select count(sid) from fido_keys"'
alias lsku='mysql -u skfsdbuser -p\`dbpass 2> /dev/null\` skfs -e "select username, sid, did, fkid, create_date, last_used_date, status from fido_keys order by username, sid, did"'
alias repl='mysql -u skfsdbuser -p\`dbpass 2> /dev/null\` skfs -e "select tsid, count(1) from replication group by tsid"'
alias zmq='netstat -an | sed -re "s|tcp6?\s+[0-9]+\s+[0-9]+\s+||" -e "s|(\S+\s+)(\S+:700.\s+)(\S+)\s+|0\2\1\3|" | sort | sed -re "s|^0(\S+\s+)(\S+\s+)(\S+)|\2\1\3|" -ne "/:700[^ ].*(EST|SYN)/p"'
alias java='java -Djavax.net.ssl.trustStore=\$STRONGKEY_HOME/certs/cacerts -Djavax.net.ssl.trustStorePassword="changeit" '
EOFSKFSRC

if [ -f /etc/bashrc ]; then
        echo ". /etc/skfsrc" >> /etc/bashrc
else
        echo ". /etc/skfsrc" >> /etc/bash.bashrc
fi

# Make needed directories
mkdir -p $STRONGKEY_HOME/certs $STRONGKEY_HOME/Desktop $STRONGKEY_HOME/dbdumps $STRONGKEY_HOME/lib $STRONGKEY_HOME/bin $STRONGKEY_HOME/appliance/etc $STRONGKEY_HOME/crypto/etc $SKFS_HOME/etc $SKFS_HOME/keystores $STRONGKEY_HOME/skce/etc/

##### Install Fido #####
cp $SKFS_SOFTWARE/certimport.sh $STRONGKEY_HOME/bin

echo -n "Installing StrongKey FIDO2 Server (SKFS) ... "

cp $STRONGKEY_HOME/bin/* $STRONGKEY_HOME/Desktop/

chmod 700 $STRONGKEY_HOME/Desktop/*.sh

SERVICE_LDAP_USERNAME=$(sed -r 's|^[cC][nN]=([^,]*),.*|\1|' <<< "$SERVICE_LDAP_SVCUSER_DN")
SERVICE_LDAP_SUFFIX=$(sed -r 's|^[cC][nN]=[^,]*(,.*)|\1|' <<< "$SERVICE_LDAP_SVCUSER_DN")

SERVICE_LDAP_PINGUSER=$(sed -r 's|^[cC][nN]=([^,]*),.*|\1|' <<< "$SERVICE_LDAP_PINGUSER_DN")
SERVICE_LDAP_PINGUSER_SUFFIX=$(sed -r 's|^[cC][nN]=[^,]*(,.*)|\1|' <<< "$SERVICE_LDAP_PINGUSER_DN")

if [ "${SERVICE_LDAP_SUFFIX}" != "${SERVICE_LDAP_PINGUSER_SUFFIX}" ]; then
        echo "Warning: SERVICE_LDAP_USER and SERVICE_LDAP_PINGUSER must be in the same OU. Pinguser may not authenticate as expected. Run update-ldap-config with corrected users."
fi

cp $SKFS_SOFTWARE/signingkeystore.bcfks $SKFS_SOFTWARE/signingtruststore.bcfks $SKFS_HOME/keystores
cp -R $SKFS_SOFTWARE/keymanager $STRONGKEY_HOME/
cp -R $SKFS_SOFTWARE/skfsclient $STRONGKEY_HOME/
cp -R $SKFS_SOFTWARE/fidoanalyzer $STRONGKEY_HOME/
cp -R $SKFS_SOFTWARE/SKFSPolicyManager $STRONGKEY_HOME/

echo "Successful"


##### MariaDB #####
if [ $INSTALL_MARIA = 'Y' ]; then
        echo -n "Installing MariaDB... "
        if [ $SHOWALL ]; then
                tar zxvf $SKFS_SOFTWARE/$MARIA -C $STRONGKEY_HOME
        else
                tar zxf $SKFS_SOFTWARE/$MARIA -C $STRONGKEY_HOME
        fi

        rpm -ivh $SKFS_SOFTWARE/$JEMALLOC &> /dev/null
        sed -i 's|^mysqld_ld_preload=$|mysqld_ld_preload=/usr/lib64/libjemalloc.so.1|' $STRONGKEY_HOME/$MARIAVER/bin/mysqld_safe
        cp $STRONGKEY_HOME/$MARIAVER/support-files/mysql.server /etc/init.d/mysqld
        chmod 755 /etc/init.d/mysqld
        /lib/systemd/systemd-sysv-install enable mysqld
        mkdir $STRONGKEY_HOME/$MARIAVER/backups $STRONGKEY_HOME/$MARIAVER/binlog $STRONGKEY_HOME/$MARIAVER/log $STRONGKEY_HOME/$MARIAVER/ibdata
        mv $STRONGKEY_HOME/$MARIAVER $STRONGKEY_HOME/$MARIATGT
        DBSIZE=10M
        SERVER_BINLOG=$STRONGKEY_HOME/$MARIATGT/binlog/skfs-binary-log

        cat > /etc/my.cnf <<-EOFMYCNF
	[client]
	socket                          = /usr/local/strongkey/$MARIATGT/log/mysqld.sock

	[mysqld]
	user                            = strongkey
	lower_case_table_names          = 1
	log-bin                         = $SERVER_BINLOG

	[server]
	basedir                         = /usr/local/strongkey/$MARIATGT
	datadir                         = /usr/local/strongkey/$MARIATGT/ibdata
	pid-file                        = /usr/local/strongkey/$MARIATGT/log/mysqld.pid
	socket                          = /usr/local/strongkey/$MARIATGT/log/mysqld.sock
	general_log                     = 0
	general_log_file                = /usr/local/strongkey/$MARIATGT/log/mysqld.log
	log-error                       = /usr/local/strongkey/$MARIATGT/log/mysqld-error.log
	innodb_data_home_dir            = /usr/local/strongkey/$MARIATGT/ibdata
	innodb_data_file_path           = ibdata01:$DBSIZE:autoextend
	innodb_flush_method             = O_DIRECT
	innodb_buffer_pool_size         = ${BUFFERPOOLSIZE}
	innodb_log_file_size            = 512M
	innodb_log_buffer_size          = 5M
	innodb_flush_log_at_trx_commit  = 1
	sync_binlog                     = 1
	lower_case_table_names          = 1
	max_connections                 = 1000
	thread_cache_size               = 1000
	expire_logs_days                = 10
	EOFMYCNF

        echo "Successful"
fi

##################
MYSQL_CMD=$($MARIA_HOME/bin/mysql --version 2>/dev/null)
if [[ ! -z $MYSQL_CMD ]]; then
      :
else
      echo "mysql binary does not exist or cannot be executed."
      exit 1
fi
##################

##### Payara #####
if [ $INSTALL_GLASSFISH = 'Y' ]; then
        echo -n "Installing Payara... "
        if [ $SHOWALL ]; then
                unzip $SKFS_SOFTWARE/$GLASSFISH -d $STRONGKEY_HOME
        else
                unzip $SKFS_SOFTWARE/$GLASSFISH -d $STRONGKEY_HOME > /dev/null
        fi

        if [ -d /root/.gfclient ]; then
                rm -rf /root/.gfclient
        fi

        if [ -d $STRONGKEY_HOME/.gfclient ]; then
                rm -rf $STRONGKEY_HOME/.gfclient
        fi

        cp $SKFS_SOFTWARE/glassfishd /etc/init.d
        chmod 755 /etc/init.d/glassfishd
        /lib/systemd/systemd-sysv-install enable glassfishd

        keytool -genkeypair -alias skfs -keystore $GLASSFISH_CONFIG/keystore.jks -storepass changeit -keypass changeit -keyalg RSA -keysize 2048 -sigalg SHA256withRSA -validity 3562 -dname "CN=$(hostname),OU=\"StrongKey FidoServer\"" &>/dev/null
        keytool -changealias -alias s1as -destalias s1as.original -keystore $GLASSFISH_CONFIG/keystore.jks -storepass changeit &>/dev/null
        keytool -changealias -alias skfs -destalias s1as -keystore $GLASSFISH_CONFIG/keystore.jks -storepass changeit &>/dev/null
        sed -ri 's|^(com.sun.enterprise.server.logging.GFFileHandler.rotationOnDateChange=).*|\1true|
                 s|^(com.sun.enterprise.server.logging.GFFileHandler.rotationLimitInBytes=).*|\1200000000|' $GLASSFISH_CONFIG/logging.properties
        keytool -exportcert -alias s1as -file $STRONGKEY_HOME/certs/$(hostname).der --keystore $GLASSFISH_CONFIG/keystore.jks -storepass changeit &>/dev/null
        keytool -importcert -noprompt -alias $(hostname) -file $STRONGKEY_HOME/certs/$(hostname).der --keystore $STRONGKEY_HOME/certs/cacerts -storepass changeit &>/dev/null
        keytool -importcert -noprompt -alias $(hostname) -file $STRONGKEY_HOME/certs/$(hostname).der --keystore $GLASSFISH_CONFIG/cacerts.jks -storepass changeit &>/dev/null

        echo "Successful"
        ##### MariaDB JDBC Driver #####
        echo -n "Installing JDBC Driver... "
        cp $SKFS_SOFTWARE/$MARIACONJAR $GLASSFISH_HOME/lib
        echo "Successful"
fi

##### Change ownership of files #####
chown -R strongkey:strongkey $STRONGKEY_HOME

##### Start OpenLDAP #####
if [ $INSTALL_OPENLDAP = 'Y' ]; then
	systemctl start slapd
	systemctl enable slapd >/dev/null 2>&1

	OLDAPPASS=$(slappasswd -h {SSHA} -s $OPENLDAP_PASS)

	sed -i "s|^olcRootPW:.*$|olcRootPW: $OLDAPPASS|" $SKFS_SOFTWARE/ldaprootpassword.ldif
	sed -i "s|^olcRootPW:.*$|olcRootPW: $OLDAPPASS|" $SKFS_SOFTWARE/db.ldif
	
fi

##### Configure OpenLDAP #####
if [ $INSTALL_OPENLDAP = 'Y' ]; then
	# If still running CentOS, change db type to hdb
	if [[ $(cat /etc/system-release | grep "CentOS") ]]; then
		sed -i "s/mdb/hdb/g" $SKFS_SOFTWARE/db.ldif
	fi

	/bin/ldapadd -Y EXTERNAL -H ldapi:/// -f ldaprootpassword.ldif >/dev/null 2>&1
	/bin/ldapmodify -Y EXTERNAL  -H ldapi:/// -f $SKFS_SOFTWARE/db.ldif >/dev/null 2>&1
	/bin/ldapmodify -Y EXTERNAL  -H ldapi:/// -f $SKFS_SOFTWARE/monitor.ldif >/dev/null 2>&1

	cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
	chown ldap:ldap /var/lib/ldap/*

	/bin/ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif >/dev/null 2>&1
	/bin/ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif >/dev/null 2>&1
	/bin/ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif >/dev/null 2>&1
	/bin/ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/core.ldif >/dev/null 2>&1

	/bin/ldapadd -x -c -w $OPENLDAP_PASS -D "cn=Manager,$SERVICE_LDAP_BASEDN" -f $SKFS_SOFTWARE/$SKFS_BASE_LDIF

	cp $SKFS_SOFTWARE/local.ldif /etc/openldap/schema/
	/bin/ldapadd -x -H ldapi:/// -D "cn=config" -w $OPENLDAP_PASS -f /etc/openldap/schema/local.ldif
	sleep 5

	SLDNAME=${SERVICE_LDAP_BASEDN%%,dc*}
	sed -r "s|dc=strongauth,dc=com|$SERVICE_LDAP_BASEDN|
		s|dc: strongauth|dc: ${SLDNAME#dc=}|
		s|did: .*|did: ${SAKA_DID}|
		s|did=[0-9]+,|did=${SAKA_DID},|
		s|^ou: [0-9]+|ou: ${SAKA_DID}|
		s|(domain( id)*) [0-9]*|\1 ${SAKA_DID}|
		s|userPassword: .*|userPassword: $SERVICE_LDAP_SVCUSER_PASS|" $SKFS_SOFTWARE/$SKFS_LDIF > /tmp/skfs.ldif

	/bin/ldapadd -x -c -w $OPENLDAP_PASS -D "cn=Manager,$SERVICE_LDAP_BASEDN" -f /tmp/skfs.ldif

	/bin/ldapmodify -Y external -H ldapi:/// -f add_slapdlog.ldif >/dev/null 2>&1
	systemctl force-reload slapd >/dev/null 2>&1
	cp $SKFS_SOFTWARE/10-slapd.conf /etc/rsyslog.d/
	service rsyslog restart

	echo "ldape.cfg.property.service.ce.ldap.ldapurl=ldap://localhost:389" >> /usr/local/strongkey/skce/etc/skce-configuration.properties
	chown -R strongkey:strongkey $STRONGKEY_HOME/skce
fi

echo "Successful"

##### Start MariaDB and Payara #####
echo -n "Creating $DBSIZE SKFS Internal Database..."
cd $STRONGKEY_HOME/$MARIATGT
scripts/mysql_install_db --basedir=`pwd` --datadir=`pwd`/ibdata &>/dev/null
# Sleep till the database is created
bin/mysqld_safe &>/dev/null &
READY=`grep "ready for connections" $MARIA_HOME/log/mysqld-error.log | wc -l`
while [ $READY -ne 1 ]
do
        echo -n .
        sleep 3
        READY=`grep "ready for connections" $MARIA_HOME/log/mysqld-error.log | wc -l`
done
echo done

$MARIA_HOME/bin/mysql -u root mysql -e "set password for 'root'@localhost=password('$MARIA_ROOT_PASSWORD');
                                                    delete from mysql.db where host = '%';
                                                    delete from mysql.user where user = '';
						    flush privileges;"

# Initialize skfs database
$MARIA_HOME/bin/mysql -u root mysql -p$MARIA_ROOT_PASSWORD -e "create database skfs;
                                            grant all on skfs.* to skfsdbuser@localhost identified by '$MARIA_SKFSDBUSER_PASSWORD';
                                            flush privileges;"

cd $SKFS_SOFTWARE/fidoserverSQL
$STRONGKEY_HOME/$MARIATGT/bin/mysql --user=skfsdbuser --password=$MARIA_SKFSDBUSER_PASSWORD --database=skfs --quick < create.txt

# Add server entries to SERVERS table
$STRONGKEY_HOME/$MARIATGT/bin/mysql --user=skfsdbuser --password=$MARIA_SKFSDBUSER_PASSWORD --database=skfs -e "insert into SERVERS values (1, '$(hostname)', 'Active', 'Both', 'Active', null, null);"

$STRONGKEY_HOME/$MARIATGT/bin/mysql --user=skfsdbuser --password=$MARIA_SKFSDBUSER_PASSWORD --database=skfs -e "insert into DOMAINS values (1,'SKFS 1','Active','Active','-----BEGIN CERTIFICATE-----\nMIIDizCCAnOgAwIBAgIENIYcAzANBgkqhkiG9w0BAQsFADBuMRcwFQYDVQQKEw5T\ndHJvbmdBdXRoIEluYzEjMCEGA1UECxMaU0tDRSBTaWduaW5nIENlcnRpZmljYXRl\nIDExEzARBgNVBAsTClNBS0EgRElEIDExGTAXBgNVBAMTEFNLQ0UgU2lnbmluZyBL\nZXkwHhcNMTkwMTMwMjI1NDAwWhcNMTkwNDMwMjI1NDAwWjBuMRcwFQYDVQQKEw5T\ndHJvbmdBdXRoIEluYzEjMCEGA1UECxMaU0tDRSBTaWduaW5nIENlcnRpZmljYXRl\nIDExEzARBgNVBAsTClNBS0EgRElEIDExGTAXBgNVBAMTEFNLQ0UgU2lnbmluZyBL\nZXkwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCH/W7ERX0U3a+2VLBY\nyjpCRTCdRtiuiLv+C1j64gLAyseF5sMH+tLNcqU0WgdZ3uQxb2+nl2y8Cp0B8Cs9\nvQi9V9CIC7zvMvgveQ711JqX8RMsaGBrn+pWx61E4B1kLCYCPSI48Crm/xkMydGM\nTKXHpfb+t9uo/uat/ykRrel5f6F764oo0o1KJkY6DjFEMh9TKMbJIeF127S2pFxl\nNNBhawTDGDaA1ag9GoWHGCWZ/bbCMMiwcH6q71AqRg8qby1EsBKA7E4DD8f+5X6b\nU3zcY3kudKlYxP4rix42PHCY3B4ZnpWS3A6lZRBot7NklsLvlxvDbKIiTcyDvSA0\nunfpAgMBAAGjMTAvMA4GA1UdDwEB/wQEAwIHgDAdBgNVHQ4EFgQUlSKnwxvmv8Bh\nlkFSMeEtAM7AyakwDQYJKoZIhvcNAQELBQADggEBAG2nosn6cTsZTdwRGws61fhP\n+tvSZXpE5mYk93x9FTnApbbsHJk1grWbC2psYxzuY1nYTqE48ORPngr3cHcNX0qZ\npi9JQ/eh7AaCLQcb1pxl+fJAjnnHKCKpicyTvmupv6c97IE4wa2KoYCJ4BdnJPnY\nnmnePPqDvjnAhuCTaxSRz59m7aW4Tyt9VPsoBShrCSBYzK5cH3FNIGffqB7zI3Jh\nXo0WpVD/YBE/OsWRbthZ0OquJIfxcpdXS4srCFocQlqNMhlQ7ZVOs73WrRx+uGIr\nhUYvIJrqgAc7+F0I7v2nAQLmxMBYheZDhN9DA9LuJRV93A8ELIX338DKxBKBPPU=\n-----END CERTIFICATE-----',NULL,'-----BEGIN CERTIFICATE-----\nMIIDizCCAnOgAwIBAgIENIYcAzANBgkqhkiG9w0BAQsFADBuMRcwFQYDVQQKEw5T\ndHJvbmdBdXRoIEluYzEjMCEGA1UECxMaU0tDRSBTaWduaW5nIENlcnRpZmljYXRl\nIDExEzARBgNVBAsTClNBS0EgRElEIDExGTAXBgNVBAMTEFNLQ0UgU2lnbmluZyBL\nZXkwHhcNMTkwMTMwMjI1NDAwWhcNMTkwNDMwMjI1NDAwWjBuMRcwFQYDVQQKEw5T\ndHJvbmdBdXRoIEluYzEjMCEGA1UECxMaU0tDRSBTaWduaW5nIENlcnRpZmljYXRl\nIDExEzARBgNVBAsTClNBS0EgRElEIDExGTAXBgNVBAMTEFNLQ0UgU2lnbmluZyBL\nZXkwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCH/W7ERX0U3a+2VLBY\nyjpCRTCdRtiuiLv+C1j64gLAyseF5sMH+tLNcqU0WgdZ3uQxb2+nl2y8Cp0B8Cs9\nvQi9V9CIC7zvMvgveQ711JqX8RMsaGBrn+pWx61E4B1kLCYCPSI48Crm/xkMydGM\nTKXHpfb+t9uo/uat/ykRrel5f6F764oo0o1KJkY6DjFEMh9TKMbJIeF127S2pFxl\nNNBhawTDGDaA1ag9GoWHGCWZ/bbCMMiwcH6q71AqRg8qby1EsBKA7E4DD8f+5X6b\nU3zcY3kudKlYxP4rix42PHCY3B4ZnpWS3A6lZRBot7NklsLvlxvDbKIiTcyDvSA0\nunfpAgMBAAGjMTAvMA4GA1UdDwEB/wQEAwIHgDAdBgNVHQ4EFgQUlSKnwxvmv8Bh\nlkFSMeEtAM7AyakwDQYJKoZIhvcNAQELBQADggEBAG2nosn6cTsZTdwRGws61fhP\n+tvSZXpE5mYk93x9FTnApbbsHJk1grWbC2psYxzuY1nYTqE48ORPngr3cHcNX0qZ\npi9JQ/eh7AaCLQcb1pxl+fJAjnnHKCKpicyTvmupv6c97IE4wa2KoYCJ4BdnJPnY\nnmnePPqDvjnAhuCTaxSRz59m7aW4Tyt9VPsoBShrCSBYzK5cH3FNIGffqB7zI3Jh\nXo0WpVD/YBE/OsWRbthZ0OquJIfxcpdXS4srCFocQlqNMhlQ7ZVOs73WrRx+uGIr\nhUYvIJrqgAc7+F0I7v2nAQLmxMBYheZDhN9DA9LuJRV93A8ELIX338DKxBKBPPU=\n-----END CERTIFICATE-----',NULL,'CN=SKFS Signing Key,OU=DID 1,OU=SKFS EC Signing Certificate 1,O=StrongKey','https://$(hostname):8181/app.json',NULL);"

if [ "$CROSS_ORIGIN_ENABLED" = "true" ]; then
        echo "Cross Origin has been enabled in all existig policies, but list of allowed origins are not yet set in the policy json. Please manually update the policies in the database and add any allowed origins."
fi

echo "appliance.cfg.property.serverid=1" > $STRONGKEY_HOME/appliance/etc/appliance-configuration.properties
echo "appliance.cfg.property.enableddomains.ccspin=$CCS_DOMAINS" >> $STRONGKEY_HOME/appliance/etc/appliance-configuration.properties
echo "appliance.cfg.property.replicate=false" >> $STRONGKEY_HOME/appliance/etc/appliance-configuration.properties
chown -R strongkey:strongkey $STRONGKEY_HOME/appliance

echo "skfs.cfg.property.allow.changeusername=$ALLOW_USERNAME_CHANGE

skfs.cfg.property.jwt.create=$JWT_CREATE
skfs.cfg.property.jwtsigning.password=$SSO_KEYSTORE_PASS

skfs.cfg.property.saml.response=$SAML_RESPONSE
skfs.cfg.property.saml.timezone=$SAML_TIMEZONE
skfs.cfg.property.saml.citrix=$SAML_CITRIX
skfs.cfg.property.saml.assertion.duration=$SAML_DURATION
skfs.cfg.property.saml.issuer.entity.name=https://$(hostname)/
skfs.cfg.property.saml.keystore.password=$SSO_KEYSTORE_PASS

skfs.cfg.property.mds.enabled=$MDS_ENABLED
skfs.cfg.property.return.MDS=$MDS_RETURN
skfs.cfg.property.return.MDS.webservices=$MDS_RETURN_WS
skfs.cfg.property.mds.mechanism=$MDS_MECHANISM
skfs.cfg.property.mds.url=$MDS_MECHANISM_URL
skfs.cfg.property.mds.rootca.url=$MDS_ROOTCA_URL

skfs.cfg.property.apple.rootca.url=$STRONGKEY_HOME/skfs/applerootca.crt

skfs.cfg.property.return.responsedetail=$RESPONSE_DETAIL
skfs.cfg.property.return.responsedetail.webservices=$RESPONSE_DETAIL_WEBSERVICES
skfs.cfg.property.return.responsedetail.format=$RESPONSE_DETAIL_FORMAT

skfs.cfg.property.auth.return.responselevel=$AUTH_RETURN_RESPONSE_LEVEL

skfs.cfg.property.retainauthenticatechallenge=$AUTH_RETAIN_CHALLENGE
" >> $STRONGKEY_HOME/skfs/etc/skfs-configuration.properties
chown -R strongkey:strongkey $STRONGKEY_HOME/skfs

mkdir -p $STRONGKEY_HOME/fido
touch $STRONGKEY_HOME/fido/VersionFidoServer-$FIDOSERVER_VERSION
chown -R strongkey:strongkey $STRONGKEY_HOME/fido

service glassfishd start
sleep 10

##### Perform Payara Tasks #####
$GLASSFISH_HOME/bin/asadmin set server.network-config.network-listeners.network-listener.http-listener-1.enabled=false
$GLASSFISH_HOME/bin/asadmin set server.network-config.protocols.protocol.http-listener-2.http.request-timeout-seconds=7200
$GLASSFISH_HOME/bin/asadmin set server.network-config.protocols.protocol.http-listener-2.ssl.ssl3-tls-ciphers=+TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,+TLS_DHE_RSA_WITH_AES_256_GCM_SHA384,+TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384,+TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA,+TLS_DHE_RSA_WITH_AES_256_CBC_SHA256,+TLS_DHE_RSA_WITH_AES_256_CBC_SHA
$GLASSFISH_HOME/bin/asadmin set server.network-config.protocols.protocol.http-listener-2.ssl.ssl2-enabled=false
$GLASSFISH_HOME/bin/asadmin set server.network-config.protocols.protocol.http-listener-2.ssl.ssl3-enabled=false
$GLASSFISH_HOME/bin/asadmin set server.network-config.protocols.protocol.http-listener-2.ssl.tls-enabled=false
$GLASSFISH_HOME/bin/asadmin set server.network-config.protocols.protocol.http-listener-2.ssl.tls11-enabled=false
$GLASSFISH_HOME/bin/asadmin set server.network-config.protocols.protocol.http-listener-2.http.trace-enabled=false
$GLASSFISH_HOME/bin/asadmin set server.network-config.protocols.protocol.http-listener-2.http.xpowered-by=false

# Create skfs database connection pool
$GLASSFISH_HOME/bin/asadmin create-jdbc-connection-pool \
        --datasourceclassname org.mariadb.jdbc.MySQLDataSource \
        --restype javax.sql.ConnectionPoolDataSource \
        --isconnectvalidatereq=true \
        --validationmethod meta-data \
        --property ServerName=localhost:DatabaseName=skfs:port=3306:user=skfsdbuser:password=$MARIA_SKFSDBUSER_PASSWORD:DontTrackOpenResources=true \
        SKFSPool
$GLASSFISH_HOME/bin/asadmin create-jdbc-resource --connectionpoolid SKFSPool jdbc/strongkeylite
$GLASSFISH_HOME/bin/asadmin set server.resources.jdbc-connection-pool.SKFSPool.max-pool-size=1000
$GLASSFISH_HOME/bin/asadmin set server.thread-pools.thread-pool.http-thread-pool.max-thread-pool-size=1000
$GLASSFISH_HOME/bin/asadmin set server.thread-pools.thread-pool.http-thread-pool.min-thread-pool-size=10

$GLASSFISH_HOME/bin/asadmin delete-jvm-options $($GLASSFISH_HOME/bin/asadmin list-jvm-options | sed -n '/\(-XX:NewRatio\|-XX:MaxPermSize\|-XX:PermSize\|-client\|-Xmx\|-Xms\)/p' | sed 's|:|\\\\:|' | tr '\n' ':')
$GLASSFISH_HOME/bin/asadmin create-jvm-options -Djtss.tcs.ini.file=$STRONGKEY_HOME/lib/jtss_tcs.ini:-Djtss.tsp.ini.file=$STRONGKEY_HOME/lib/jtss_tsp.ini:-Xmx${XMXSIZE}:-Xms${XMXSIZE}:-Djdk.tls.ephemeralDHKeySize=2048:-Dproduct.name="":-XX\\:-DisableExplicitGC

# Create URL for first time setup
install_date_millis=$(date +%s%3N)
$MARIA_HOME/bin/mysql -u skfsdbuser -p${MARIA_SKFSDBUSER_PASSWORD} skfs -e "insert into configurations values(1, 'skfs.cfg.property.install.date.hash', '$(echo $(hostname)$install_date_millis | md5sum | cut -d ' ' -f 1)', 'Hash created during install to aid in first time setup');"

cat > $GLASSFISH_HOME/domains/domain1/docroot/app.json <<- EOFAPPJSON
{
        "trustedFacets" : [{
                "version": { "major": 1, "minor" : 0 },
                "ids": [
                        "https://$(hostname)",
                        "https://$(hostname):8181"
                ]
        }]
}
EOFAPPJSON

# Add other servers to app.json
for fqdn in $($MARIA_HOME/bin/mysql -u skfsdbuser -p${MARIA_SKFSDBUSER_PASSWORD} skfs -B --skip-column-names -e "select fqdn from servers;"); do
        # Skip doing ourself again
        if [ "$fqdn" == "$(hostname)" ]; then
                continue
        fi
        sed -i "/^\[/a \"           https://$fqdn:8181\"," $GLASSFISH_HOME/domains/domain1/docroot/app.json
        sed -i "/^\[/a \"           https://$fqdn\"," $GLASSFISH_HOME/domains/domain1/docroot/app.json
done

cd $SKFS_HOME/keystores

# Generate JWT keystores. First domain's keys are created automatically, and if ALL default policy domains are created, create keys for domains 2-8
$SKFS_SOFTWARE/keygen-sso.sh -jwt -did 1 -dn "$(echo $JWT_KEYGEN_DN | sed -e "s/{domain}/1/g")" -jwtcns "$JWT_CN_LIST" -p "$SSO_KEYSTORE_PASS" -v "$JWT_KEY_VALIDITY"
if [ ${POLICY_DOMAINS^^} = "ALL" ]; then
        for (( DID = 2; DID <= 8 ; DID++ )); do
                $SKFS_SOFTWARE/keygen-sso.sh -jwt -did $DID -dn "$(echo $JWT_KEYGEN_DN | sed -e "s/{domain}/$DID/g")" -jwtcns "$JWT_CN_LIST" -p "$SSO_KEYSTORE_PASS" -v "$JWT_KEY_VALIDITY"
        done
fi

# Generate SAML keystores. First domain's keys are created automatically, and if ALL default policy domains are created, create keys for domains 2-8
$SKFS_SOFTWARE/keygen-sso.sh -saml -did 1 -dn "$(echo $SAML_KEYGEN_DN | sed -e "s/{domain}/1/g")" -samlcns "$SAML_CN_LIST" -p "$SSO_KEYSTORE_PASS" -v "$SAML_KEY_VALIDITY"
if [ ${POLICY_DOMAINS^^} = "ALL" ]; then
        for (( DID = 2; DID <= 8 ; DID++ )); do
                $SKFS_SOFTWARE/keygen-sso.sh -saml -did $DID -dn "$(echo $SAML_KEYGEN_DN | sed -e "s/{domain}/$DID/g")" -samlcns "$SAML_CN_LIST" -p "$SSO_KEYSTORE_PASS" -v "$SAML_KEY_VALIDITY"
        done
fi
# If external SAML keys are provided, use the importsamlkeys.sh script to replace the existing saml keys with the ones provided for that domain
if [ "$SAML_EXTERNAL_PROVIDED" = "true" ]; then
        $SKFS_SOFTWARE/importsamlkeys.sh $SAML_EXTERNAL_DID $SSO_KEYSTORE_PASS $SAML_EXTERNAL_STORETYPE $SAML_EXTERNAL_STOREPATH $SAML_EXTERNAL_STOREPASS $SAML_EXTERNAL_CERT_ALIAS $SAML_EXTERNAL_KEY_ALIAS $SAML_EXTERNAL_KEY_PASS
fi
chown -R strongkey:strongkey $SKFS_HOME/keystores

# Insert policies. If POLICY_DOMAINS=ALL (Default: ALL), then 8 domains with different policies will be added.
cd $SKFS_HOME/keystores/sso-keys
startDate=$(date +%s)
ROOT_CA_SUBJECT_DN=$(openssl x509 -in ssoca-1.pem -noout -subject -nameopt rfc2253 | awk -F 'subject=' '{print $2}')
ROOT_CA_SERIAL=$((16#$(openssl x509 -in ssoca-1.pem -noout -serial | awk -F 'serial=' '{print $2}')))
ROOT_CA_PEM="$(cat ssoca-1.pem | tr -d $'\r' | tr -d '\n')"

JWT_CN_COUNT=$(($(echo $JWT_CN_LIST | tr -cd ',' | wc -c)+1))
SAML_CN_COUNT=$(($(echo $SAML_CN_LIST | tr -cd ',' | wc -c)+1))

JWT_CERTS_LIST=
for (( CERT_NUM = 1; CERT_NUM <= JWT_CN_COUNT; CERT_NUM++ )); do
        JWT_SUBJECT_DN=$(openssl x509 -in jwtsigning-1-$CERT_NUM.pem -noout -subject -nameopt rfc2253 | awk -F 'subject=' '{print $2}')
        JWT_SERIAL=$((16#$(openssl x509 -in jwtsigning-1-$CERT_NUM.pem -noout -serial | awk -F 'serial=' '{print $2}')))
        JWT_PEM="$(cat jwtsigning-1-$CERT_NUM.pem | tr -d $'\r' | tr -d '\n')"
        JWT_CERTS_LIST="$JWT_CERTS_LIST,{\"subjectdn\":\"$JWT_SUBJECT_DN\",\"serialnumber\":\"$JWT_SERIAL\",\"pemcert\":\"$JWT_PEM\"}"
done
SAML_CERTS_LIST=
for (( CERT_NUM = 1; CERT_NUM <= SAML_CN_COUNT; CERT_NUM++ )); do
        SAML_SUBJECT_DN=$(openssl x509 -in samlsigning-1-$CERT_NUM.pem -noout -subject -nameopt rfc2253 | awk -F 'subject=' '{print $2}')
        SAML_SERIAL=$((16#$(openssl x509 -in samlsigning-1-$CERT_NUM.pem -noout -serial | awk -F 'serial=' '{print $2}')))
        SAML_PEM="$(cat samlsigning-1-$CERT_NUM.pem | tr -d $'\r' | tr -d '\n')"
        SAML_CERTS_LIST="$SAML_CERTS_LIST,{\"subjectdn\":\"$SAML_SUBJECT_DN\",\"serialnumber\":\"$SAML_SERIAL\",\"pemcert\":\"$SAML_PEM\"}"
done
fidoPolicy=$(echo "{\"FidoPolicy\":{\"name\":\"MinimalPolicy\",\"copyright\":\"\",\"version\":\"1.0\",\"startDate\":\"${startDate}\",\"endDate\":\"1760103870871\",\"system\":{\"did\":1,\"requireCounter\":\"optional\",\"integritySignatures\":false,\"userVerification\":[\"required\",\"preferred\",\"discouraged\"],\"userPresenceTimeout\":0,\"allowedAaguids\":[\"all\"],\"transport\":[\"usb\",\"internal\"]},\"crossOrigin\":{\"enabled\":$CROSS_ORIGIN_ENABLED,\"allowedOrigins\":[]},\"algorithms\":{\"curves\":[\"secp256r1\",\"secp384r1\",\"secp521r1\",\"curve25519\"],\"rsa\":[\"RS256\",\"RS384\",\"RS512\",\"PS256\",\"PS384\",\"PS384\"],\"signatures\":[\"ES256\",\"ES384\",\"ES512\",\"EdDSA\",\"ES256K\"]},\"attestation\":{\"conveyance\":[\"none\",\"indirect\",\"direct\",\"enterprise\"],\"formats\":[\"fido-u2f\",\"packed\",\"tpm\",\"android-key\",\"android-safetynet\",\"apple\",\"none\"]},\"registration\":{\"displayName\":\"required\",\"attachment\":[\"platform\",\"cross-platform\"],\"discoverableCredential\":[\"required\",\"preferred\",\"discouraged\"],\"excludeCredentials\":\"enabled\"},\"authentication\":{\"allowCredentials\":\"enabled\"},\"authorization\":{\"maxdataLength\":256,\"preserve\":true},\"rp\":{\"id\":\"${RPID}\",\"name\":\"FIDOServer\"},\"extensions\":{},\"mds\":{\"authenticatorStatusReport\":[{\"status\":\"FIDO_CERTIFIED_L1\",\"priority\":\"1\",\"decision\":\"IGNORE\"},{\"status\":\"FIDO_CERTIFIED_L2\",\"priority\":\"1\",\"decision\":\"ACCEPT\"},{\"status\":\"UPDATE_AVAILABLE\",\"priority\":\"5\",\"decision\":\"IGNORE\"},{\"status\":\"REVOKED\",\"priority\":\"10\",\"decision\":\"DENY\"}]},\"jwt\":{\"algorithms\":[\"ES256\",\"ES384\",\"ES521\"],\"duration\":${JWT_DURATION},\"required\":[\"rpid\",\"iat\",\"exp\",\"cip\",\"uname\",\"agent\"]},\"signcerts\":{\"rootca\":{\"subjectdn\":\"$ROOT_CA_SUBJECT_DN\",\"serialnumber\":\"$ROOT_CA_SERIAL\",\"pemcert\":\"$ROOT_CA_PEM\",\"jwtcerts\":{\"default\":[${JWT_CERTS_LIST:1}]},\"samlcerts\":{\"default\":[${SAML_CERTS_LIST:1}],\"citrixidp\":{\"subjectdn\":\"CN=SKFS SAML Signer 1,$(echo $SAML_KEYGEN_DN | sed -e "s/{domain}/1/g")\",\"serialnumber\":\"$((16#$(openssl x509 -in samlsigning-1-1.pem -noout -serial | awk -F 'serial=' '{print $2}')))\",\"pemcert\":\"$(cat samlsigning-1-1.pem | tr -d $'\r' | tr -d '\n')\"}}}}}}" | /usr/bin/base64 -w 0)
$STRONGKEY_HOME/$MARIATGT/bin/mysql --user=skfsdbuser --password=$MARIA_SKFSDBUSER_PASSWORD --database=skfs -e "insert into FIDO_POLICIES values (1,1,1,'${fidoPolicy}','Active','',NOW(),NULL,NULL);"

if [ ${POLICY_DOMAINS^^} = "ALL" ]; then

        # Domain 2
        $STRONGKEY_HOME/$MARIATGT/bin/mysql --user=skfsdbuser --password=$MARIA_SKFSDBUSER_PASSWORD --database=skfs -e "insert into DOMAINS values (2,'SKFS 2','Active','Active','',NULL,'',NULL,'CN=SKFS Signing Key,OU=DID 2,OU=SKFS EC Signing Certificate 1,O=StrongKey','https://$(hostname):8181/app.json',NULL);"
        ROOT_CA_SUBJECT_DN=$(openssl x509 -in ssoca-2.pem -noout -subject -nameopt rfc2253 | awk -F 'subject=' '{print $2}')
        ROOT_CA_SERIAL=$((16#$(openssl x509 -in ssoca-2.pem -noout -serial | awk -F 'serial=' '{print $2}')))
        ROOT_CA_PEM="$(cat ssoca-2.pem | tr -d $'\r' | tr -d '\n')"
        JWT_CERTS_LIST=
        if [ "${JWT_CREATE,,}" = "true" ]; then
                for (( CERT_NUM = 1; CERT_NUM <= JWT_CN_COUNT; CERT_NUM++ )); do
                        JWT_SUBJECT_DN=$(openssl x509 -in jwtsigning-2-$CERT_NUM.pem -noout -subject -nameopt rfc2253 | awk -F 'subject=' '{print $2}')
                        JWT_SERIAL=$((16#$(openssl x509 -in jwtsigning-2-$CERT_NUM.pem -noout -serial | awk -F 'serial=' '{print $2}')))
                        JWT_PEM="$(cat jwtsigning-2-$CERT_NUM.pem | tr -d $'\r' | tr -d '\n')"
                        JWT_CERTS_LIST="$JWT_CERTS_LIST,{\"subjectdn\":\"$JWT_SUBJECT_DN\",\"serialnumber\":\"$JWT_SERIAL\",\"pemcert\":\"$JWT_PEM\"}"
                done
        fi
        SAML_CERTS_LIST=
        if [ "${SAML_RESPONSE,,}" = "true" ]; then
                for (( CERT_NUM = 1; CERT_NUM <= SAML_CN_COUNT; CERT_NUM++ )); do
                        SAML_SUBJECT_DN=$(openssl x509 -in samlsigning-2-$CERT_NUM.pem -noout -subject -nameopt rfc2253 | awk -F 'subject=' '{print $2}')
                        SAML_SERIAL=$((16#$(openssl x509 -in samlsigning-2-$CERT_NUM.pem -noout -serial | awk -F 'serial=' '{print $2}')))
                        SAML_PEM="$(cat samlsigning-2-$CERT_NUM.pem | tr -d $'\r' | tr -d '\n')"
                        SAML_CERTS_LIST="$SAML_CERTS_LIST,{\"subjectdn\":\"$SAML_SUBJECT_DN\",\"serialnumber\":\"$SAML_SERIAL\",\"pemcert\":\"$SAML_PEM\"}"
                done
        fi
        fidoPolicy=$(echo "{\"FidoPolicy\":{\"name\":\"ModerateSKFSPolicy-SpecificSecurityKeys\",\"copyright\":\"StrongAuth, Inc. (DBA StrongKey) All Rights Reserved\",\"version\":\"2.0\",\"startDate\":\"${startDate}\",\"endDate\":\"1760103870871\",\"system\":{\"did\":2,\"requireCounter\":\"mandatory\",\"integritySignatures\":true,\"userVerification\":[\"preferred\"],\"userPresenceTimeout\":60,\"allowedAaguids\":[\"95442b2e-f15e-4def-b270-efb106facb4e\",\"87dbc5a1-4c94-4dc8-8a47-97d800fd1f3c\",\"95442b2e-f15e-4def-b270-efb106facb4e\",\"87dbc5a1-4c94-4dc8-8a47-97d800fd1f3c\",\"da776f39-f6c8-4a89-b252-1d86137a46ba\",\"e3512a8a-62ae-11ea-bc55-0242ac130003\",\"cb69481e-8ff7-4039-93ec-0a2729a154a8\",\"ee882879-721c-4913-9775-3dfcce97072a\",\"fa2b99dc-9e39-4257-8f92-4a30d23c4118\",\"2fc0579f-8113-47ea-b116-bb5a8db9202a\",\"c1f9a0bc-1dd2-404a-b27f-8e29047a43fd\",\"cb69481e-8ff7-4039-93ec-0a2729a154a8\",\"ee882879-721c-4913-9775-3dfcce97072a\",\"73bb0cd4-e502-49b8-9c6f-b59445bf720b\",\"cb69481e-8ff7-4039-93ec-0a2729a154a8\",\"ee882879-721c-4913-9775-3dfcce97072a\",\"73bb0cd4-e502-49b8-9c6f-b59445bf720b\",\"cb69481e-8ff7-4039-93ec-0a2729a154a8\",\"ee882879-721c-4913-9775-3dfcce97072a\",\"73bb0cd4-e502-49b8-9c6f-b59445bf720b\",\"2fc0579f-8113-47ea-b116-bb5a8db9202a\",\"c1f9a0bc-1dd2-404a-b27f-8e29047a43fd\",\"c5ef55ff-ad9a-4b9f-b580-adebafe026d0\",\"85203421-48f9-4355-9bc8-8a53846e5083\",\"f8a011f3-8c0a-4d15-8006-17111f9edc7d\",\"b92c3f9a-c014-4056-887f-140a2501163b\",\"6d44ba9b-f6ec-2e49-b930-0c8fe920cb73\",\"149a2021-8ef6-4133-96b8-81f8d5b7f1f5\"],\"transport\":[\"usb\",\"internal\"]},\"crossOrigin\":{\"enabled\":$CROSS_ORIGIN_ENABLED,\"allowedOrigins\":[]},\"algorithms\":{\"curves\":[\"secp256r1\",\"secp384r1\",\"secp521r1\",\"curve25519\"],\"rsa\":[\"none\"],\"signatures\":[\"ES256\",\"ES384\",\"ES512\",\"EdDSA\",\"ES256K\"]},\"attestation\":{\"conveyance\":[\"direct\"],\"formats\":[\"packed\"]},\"registration\":{\"displayName\":\"required\",\"attachment\":[\"cross-platform\"],\"discoverableCredential\":[\"preferred\",\"discouraged\"],\"excludeCredentials\":\"enabled\"},\"authentication\":{\"allowCredentials\":\"enabled\"},\"authorization\":{\"maxdataLength\":256,\"preserve\":true},\"rp\":{\"id\":\"${RPID}\",\"name\":\"FIDOServer\"},\"extensions\":{},\"mds\":{\"authenticatorStatusReport\":[{\"status\":\"FIDO_CERTIFIED_L1\",\"priority\":\"1\",\"decision\":\"IGNORE\"},{\"status\":\"FIDO_CERTIFIED_L2\",\"priority\":\"1\",\"decision\":\"ACCEPT\"},{\"status\":\"UPDATE_AVAILABLE\",\"priority\":\"5\",\"decision\":\"IGNORE\"},{\"status\":\"REVOKED\",\"priority\":\"10\",\"decision\":\"DENY\"}]},\"jwt\":{\"algorithms\":[\"ES256\",\"ES384\",\"ES521\"],\"duration\":${JWT_DURATION},\"required\":[\"rpid\",\"iat\",\"exp\",\"cip\",\"uname\",\"agent\"]},\"signcerts\":{\"rootca\":{\"subjectdn\":\"$ROOT_CA_SUBJECT_DN\",\"serialnumber\":\"$ROOT_CA_SERIAL\",\"pemcert\":\"$ROOT_CA_PEM\",\"jwtcerts\":{\"default\":[${JWT_CERTS_LIST:1}]},\"samlcerts\":{\"default\":[${SAML_CERTS_LIST:1}],\"citrixidp\":{\"subjectdn\":\"CN=SKFS SAML Signer 1,$(echo $SAML_KEYGEN_DN | sed -e "s/{domain}/2/g")\",\"serialnumber\":\"$((16#$(openssl x509 -in samlsigning-2-1.pem -noout -serial | awk -F 'serial=' '{print $2}')))\",\"pemcert\":\"$(cat samlsigning-2-1.pem | tr -d $'\r' | tr -d '\n')\"}}}}}}" | /usr/bin/base64 -w 0)
        $STRONGKEY_HOME/$MARIATGT/bin/mysql --user=skfsdbuser --password=$MARIA_SKFSDBUSER_PASSWORD --database=skfs -e "insert into FIDO_POLICIES values (1,2,2,'${fidoPolicy}','Active','',NOW(),NULL,NULL);"
        
        # Domain 3
        $STRONGKEY_HOME/$MARIATGT/bin/mysql --user=skfsdbuser --password=$MARIA_SKFSDBUSER_PASSWORD --database=skfs -e "insert into DOMAINS values (3,'SKFS 3','Active','Active','',NULL,'',NULL,'CN=SKFS Signing Key,OU=DID 3,OU=SKFS EC Signing Certificate 1,O=StrongKey','https://$(hostname):8181/app.json',NULL);"
        ROOT_CA_SUBJECT_DN=$(openssl x509 -in ssoca-3.pem -noout -subject -nameopt rfc2253 | awk -F 'subject=' '{print $2}')
        ROOT_CA_SERIAL=$((16#$(openssl x509 -in ssoca-3.pem -noout -serial | awk -F 'serial=' '{print $2}')))
        ROOT_CA_PEM="$(cat ssoca-3.pem | tr -d $'\r' | tr -d '\n')"
        JWT_CERTS_LIST=
        if [ "${JWT_CREATE,,}" = "true" ]; then
                for (( CERT_NUM = 1; CERT_NUM <= JWT_CN_COUNT; CERT_NUM++ )); do
                        JWT_SUBJECT_DN=$(openssl x509 -in jwtsigning-3-$CERT_NUM.pem -noout -subject -nameopt rfc2253 | awk -F 'subject=' '{print $2}')
                        JWT_SERIAL=$((16#$(openssl x509 -in jwtsigning-3-$CERT_NUM.pem -noout -serial | awk -F 'serial=' '{print $2}')))
                        JWT_PEM="$(cat jwtsigning-3-$CERT_NUM.pem | tr -d $'\r' | tr -d '\n')"
                        JWT_CERTS_LIST="$JWT_CERTS_LIST,{\"subjectdn\":\"$JWT_SUBJECT_DN\",\"serialnumber\":\"$JWT_SERIAL\",\"pemcert\":\"$JWT_PEM\"}"
                done
        fi
        SAML_CERTS_LIST=
        if [ "${SAML_RESPONSE,,}" = "true" ]; then
                for (( CERT_NUM = 1; CERT_NUM <= SAML_CN_COUNT; CERT_NUM++ )); do
                        SAML_SUBJECT_DN=$(openssl x509 -in samlsigning-3-$CERT_NUM.pem -noout -subject -nameopt rfc2253 | awk -F 'subject=' '{print $2}')
                        SAML_SERIAL=$((16#$(openssl x509 -in samlsigning-3-$CERT_NUM.pem -noout -serial | awk -F 'serial=' '{print $2}')))
                        SAML_PEM="$(cat samlsigning-3-$CERT_NUM.pem | tr -d $'\r' | tr -d '\n')"
                        SAML_CERTS_LIST="$SAML_CERTS_LIST,{\"subjectdn\":\"$SAML_SUBJECT_DN\",\"serialnumber\":\"$SAML_SERIAL\",\"pemcert\":\"$SAML_PEM\"}"
                done
        fi
        fidoPolicy=$(echo "{\"FidoPolicy\":{\"name\":\"SecureSKFSPolicy-AllBiometricDevices\",\"copyright\":\"StrongAuth, Inc. (DBA StrongKey) All Rights Reserved\",\"version\":\"2.0\",\"startDate\":\"${startDate}\",\"endDate\":\"1760103870871\",\"system\":{\"did\":3,\"requireCounter\":\"mandatory\",\"integritySignatures\":true,\"userVerification\":[\"required\"],\"userPresenceTimeout\":30,\"allowedAaguids\":[\"all\"],\"transport\":[\"usb\",\"internal\"]},\"crossOrigin\":{\"enabled\":$CROSS_ORIGIN_ENABLED,\"allowedOrigins\":[]},\"algorithms\":{\"curves\":[\"secp256r1\",\"secp384r1\",\"secp521r1\",\"curve25519\"],\"rsa\":[\"none\"],\"signatures\":[\"ES256\",\"ES384\",\"ES512\",\"EdDSA\",\"ES256K\"]},\"attestation\":{\"conveyance\":[\"direct\"],\"formats\":[\"packed\",\"tpm\",\"android-key\"]},\"registration\":{\"displayName\":\"required\",\"attachment\":[\"platform\",\"cross-platform\"],\"discoverableCredential\":[\"required\"],\"excludeCredentials\":\"enabled\"},\"authentication\":{\"allowCredentials\":\"enabled\"},\"authorization\":{\"maxdataLength\":256,\"preserve\":true},\"rp\":{\"id\":\"${RPID}\",\"name\":\"FIDOServer\"},\"extensions\":{},\"mds\":{\"authenticatorStatusReport\":[{\"status\":\"FIDO_CERTIFIED_L1\",\"priority\":\"1\",\"decision\":\"IGNORE\"},{\"status\":\"FIDO_CERTIFIED_L2\",\"priority\":\"1\",\"decision\":\"ACCEPT\"},{\"status\":\"UPDATE_AVAILABLE\",\"priority\":\"5\",\"decision\":\"IGNORE\"},{\"status\":\"REVOKED\",\"priority\":\"10\",\"decision\":\"DENY\"}]},\"jwt\":{\"algorithms\":[\"ES256\",\"ES384\",\"ES521\"],\"duration\":${JWT_DURATION},\"required\":[\"rpid\",\"iat\",\"exp\",\"cip\",\"uname\",\"agent\"]},\"signcerts\":{\"rootca\":{\"subjectdn\":\"$ROOT_CA_SUBJECT_DN\",\"serialnumber\":\"$ROOT_CA_SERIAL\",\"pemcert\":\"$ROOT_CA_PEM\",\"jwtcerts\":{\"default\":[${JWT_CERTS_LIST:1}]},\"samlcerts\":{\"default\":[${SAML_CERTS_LIST:1}],\"citrixidp\":{\"subjectdn\":\"CN=SKFS SAML Signer 1,$(echo $SAML_KEYGEN_DN | sed -e "s/{domain}/3/g")\",\"serialnumber\":\"$((16#$(openssl x509 -in samlsigning-3-1.pem -noout -serial | awk -F 'serial=' '{print $2}')))\",\"pemcert\":\"$(cat samlsigning-3-1.pem | tr -d $'\r' | tr -d '\n')\"}}}}}}" | /usr/bin/base64 -w 0)
        $STRONGKEY_HOME/$MARIATGT/bin/mysql --user=skfsdbuser --password=$MARIA_SKFSDBUSER_PASSWORD --database=skfs -e "insert into FIDO_POLICIES values (1,3,3,'${fidoPolicy}','Active','',NOW(),NULL,NULL);"
        
        # Domain 4
        $STRONGKEY_HOME/$MARIATGT/bin/mysql --user=skfsdbuser --password=$MARIA_SKFSDBUSER_PASSWORD --database=skfs -e "insert into DOMAINS values (4,'SKFS 4','Active','Active','',NULL,'',NULL,'CN=SKFS Signing Key,OU=DID 4,OU=SKFS EC Signing Certificate 1,O=StrongKey','https://$(hostname):8181/app.json',NULL);"
        ROOT_CA_SUBJECT_DN=$(openssl x509 -in ssoca-4.pem -noout -subject -nameopt rfc2253 | awk -F 'subject=' '{print $2}')
        ROOT_CA_SERIAL=$((16#$(openssl x509 -in ssoca-4.pem -noout -serial | awk -F 'serial=' '{print $2}')))
        ROOT_CA_PEM="$(cat ssoca-4.pem | tr -d $'\r' | tr -d '\n')"
        JWT_CERTS_LIST=
        if [ "${JWT_CREATE,,}" = "true" ]; then
                for (( CERT_NUM = 1; CERT_NUM <= JWT_CN_COUNT; CERT_NUM++ )); do
                        JWT_SUBJECT_DN=$(openssl x509 -in jwtsigning-4-$CERT_NUM.pem -noout -subject -nameopt rfc2253 | awk -F 'subject=' '{print $2}')
                        JWT_SERIAL=$((16#$(openssl x509 -in jwtsigning-4-$CERT_NUM.pem -noout -serial | awk -F 'serial=' '{print $2}')))
                        JWT_PEM="$(cat jwtsigning-4-$CERT_NUM.pem | tr -d $'\r' | tr -d '\n')"
                        JWT_CERTS_LIST="$JWT_CERTS_LIST,{\"subjectdn\":\"$JWT_SUBJECT_DN\",\"serialnumber\":\"$JWT_SERIAL\",\"pemcert\":\"$JWT_PEM\"}"
                done
        fi
        SAML_CERTS_LIST=
        if [ "${SAML_RESPONSE,,}" = "true" ]; then
                for (( CERT_NUM = 1; CERT_NUM <= SAML_CN_COUNT; CERT_NUM++ )); do
                        SAML_SUBJECT_DN=$(openssl x509 -in samlsigning-4-$CERT_NUM.pem -noout -subject -nameopt rfc2253 | awk -F 'subject=' '{print $2}')
                        SAML_SERIAL=$((16#$(openssl x509 -in samlsigning-4-$CERT_NUM.pem -noout -serial | awk -F 'serial=' '{print $2}')))
                        SAML_PEM="$(cat samlsigning-4-$CERT_NUM.pem | tr -d $'\r' | tr -d '\n')"
                        SAML_CERTS_LIST="$SAML_CERTS_LIST,{\"subjectdn\":\"$SAML_SUBJECT_DN\",\"serialnumber\":\"$SAML_SERIAL\",\"pemcert\":\"$SAML_PEM\"}"
                done
        fi
        fidoPolicy=$(echo "{\"FidoPolicy\":{\"name\":\"RestrictedSKFSPolicy-Android-SafetyNet\",\"copyright\":\"StrongAuth, Inc. (DBA StrongKey) All Rights Reserved\",\"version\":\"2.0\",\"startDate\":\"${startDate}\",\"endDate\":\"1760103870871\",\"system\":{\"did\":4,\"requireCounter\":\"mandatory\",\"integritySignatures\":true,\"userVerification\":[\"required\"],\"userPresenceTimeout\":30,\"allowedAaguids\":[\"b93fd961-f2e6-462f-b122-82002247de78\"],\"transport\":[\"usb\",\"internal\"]},\"crossOrigin\":{\"enabled\":$CROSS_ORIGIN_ENABLED,\"allowedOrigins\":[]},\"algorithms\":{\"curves\":[\"secp256r1\",\"secp384r1\",\"secp521r1\",\"curve25519\"],\"rsa\":[\"none\"],\"signatures\":[\"ES256\",\"ES384\",\"ES512\",\"EdDSA\",\"ES256K\"]},\"attestation\":{\"conveyance\":[\"direct\"],\"formats\":[\"android-safetynet\"]},\"registration\":{\"displayName\":\"required\",\"attachment\":[\"platform\"],\"discoverableCredential\":[\"required\"],\"excludeCredentials\":\"enabled\"},\"authentication\":{\"allowCredentials\":\"enabled\"},\"authorization\":{\"maxdataLength\":256,\"preserve\":true},\"rp\":{\"id\":\"${RPID}\",\"name\":\"FIDOServer\"},\"extensions\":{},\"mds\":{\"authenticatorStatusReport\":[{\"status\":\"FIDO_CERTIFIED_L1\",\"priority\":\"1\",\"decision\":\"IGNORE\"},{\"status\":\"FIDO_CERTIFIED_L2\",\"priority\":\"1\",\"decision\":\"ACCEPT\"},{\"status\":\"UPDATE_AVAILABLE\",\"priority\":\"5\",\"decision\":\"IGNORE\"},{\"status\":\"REVOKED\",\"priority\":\"10\",\"decision\":\"DENY\"}]},\"jwt\":{\"algorithms\":[\"ES256\",\"ES384\",\"ES521\"],\"duration\":${JWT_DURATION},\"required\":[\"rpid\",\"iat\",\"exp\",\"cip\",\"uname\",\"agent\"]},\"signcerts\":{\"rootca\":{\"subjectdn\":\"$ROOT_CA_SUBJECT_DN\",\"serialnumber\":\"$ROOT_CA_SERIAL\",\"pemcert\":\"$ROOT_CA_PEM\",\"jwtcerts\":{\"default\":[${JWT_CERTS_LIST:1}]},\"samlcerts\":{\"default\":[${SAML_CERTS_LIST:1}],\"citrixidp\":{\"subjectdn\":\"CN=SKFS SAML Signer 1,$(echo $SAML_KEYGEN_DN | sed -e "s/{domain}/4/g")\",\"serialnumber\":\"$((16#$(openssl x509 -in samlsigning-4-1.pem -noout -serial | awk -F 'serial=' '{print $2}')))\",\"pemcert\":\"$(cat samlsigning-4-1.pem | tr -d $'\r' | tr -d '\n')\"}}}}}}" | /usr/bin/base64 -w 0)
        $STRONGKEY_HOME/$MARIATGT/bin/mysql --user=skfsdbuser --password=$MARIA_SKFSDBUSER_PASSWORD --database=skfs -e "insert into FIDO_POLICIES values (1,4,4,'${fidoPolicy}','Active','',NOW(),NULL,NULL);"
        
        # Domain 5
        $STRONGKEY_HOME/$MARIATGT/bin/mysql --user=skfsdbuser --password=$MARIA_SKFSDBUSER_PASSWORD --database=skfs -e "insert into DOMAINS values (5,'SKFS 5','Active','Active','',NULL,'',NULL,'CN=SKFS Signing Key,OU=DID 5,OU=SKFS EC Signing Certificate 1,O=StrongKey','https://$(hostname):8181/app.json',NULL);"
        ROOT_CA_SUBJECT_DN=$(openssl x509 -in ssoca-5.pem -noout -subject -nameopt rfc2253 | awk -F 'subject=' '{print $2}')
        ROOT_CA_SERIAL=$((16#$(openssl x509 -in ssoca-5.pem -noout -serial | awk -F 'serial=' '{print $2}')))
        ROOT_CA_PEM="$(cat ssoca-5.pem | tr -d $'\r' | tr -d '\n')"
        JWT_CERTS_LIST=
        if [ "${JWT_CREATE,,}" = "true" ]; then
                for (( CERT_NUM = 1; CERT_NUM <= JWT_CN_COUNT; CERT_NUM++ )); do
                        JWT_SUBJECT_DN=$(openssl x509 -in jwtsigning-5-$CERT_NUM.pem -noout -subject -nameopt rfc2253 | awk -F 'subject=' '{print $2}')
                        JWT_SERIAL=$((16#$(openssl x509 -in jwtsigning-5-$CERT_NUM.pem -noout -serial | awk -F 'serial=' '{print $2}')))
                        JWT_PEM="$(cat jwtsigning-5-$CERT_NUM.pem | tr -d $'\r' | tr -d '\n')"
                        JWT_CERTS_LIST="$JWT_CERTS_LIST,{\"subjectdn\":\"$JWT_SUBJECT_DN\",\"serialnumber\":\"$JWT_SERIAL\",\"pemcert\":\"$JWT_PEM\"}"
                done
        fi
        SAML_CERTS_LIST=
        if [ "${SAML_RESPONSE,,}" = "true" ]; then
                for (( CERT_NUM = 1; CERT_NUM <= SAML_CN_COUNT; CERT_NUM++ )); do
                        SAML_SUBJECT_DN=$(openssl x509 -in samlsigning-5-$CERT_NUM.pem -noout -subject -nameopt rfc2253 | awk -F 'subject=' '{print $2}')
                        SAML_SERIAL=$((16#$(openssl x509 -in samlsigning-5-$CERT_NUM.pem -noout -serial | awk -F 'serial=' '{print $2}')))
                        SAML_PEM="$(cat samlsigning-5-$CERT_NUM.pem | tr -d $'\r' | tr -d '\n')"
                        SAML_CERTS_LIST="$SAML_CERTS_LIST,{\"subjectdn\":\"$SAML_SUBJECT_DN\",\"serialnumber\":\"$SAML_SERIAL\",\"pemcert\":\"$SAML_PEM\"}"
                done
        fi
        fidoPolicy=$(echo "{\"FidoPolicy\":{\"name\":\"RestrictedSKFSPolicy-TPM\",\"copyright\":\"StrongAuth, Inc. (DBA StrongKey) All Rights Reserved\",\"version\":\"2.0\",\"startDate\":\"${startDate}\",\"endDate\":\"1760103870871\",\"system\":{\"did\":5,\"requireCounter\":\"mandatory\",\"integritySignatures\":true,\"userVerification\":[\"required\"],\"userPresenceTimeout\":30,\"allowedAaguids\":[\"08987058-cadc-4b81-b6e1-30de50dcbe96\"],\"transport\":[\"usb\",\"internal\"]},\"crossOrigin\":{\"enabled\":$CROSS_ORIGIN_ENABLED,\"allowedOrigins\":[]},\"algorithms\":{\"curves\":[\"secp256r1\",\"secp384r1\",\"secp521r1\",\"curve25519\"],\"rsa\":[\"RS256\",\"RS384\",\"RS512\",\"PS256\",\"PS384\",\"PS512\"],\"signatures\":[\"ES256\",\"ES384\",\"ES512\",\"EdDSA\",\"ES256K\"]},\"attestation\":{\"conveyance\":[\"direct\"],\"formats\":[\"tpm\"]},\"registration\":{\"displayName\":\"required\",\"attachment\":[\"platform\"],\"discoverableCredential\":[\"required\"],\"excludeCredentials\":\"enabled\"},\"authentication\":{\"allowCredentials\":\"enabled\"},\"authorization\":{\"maxdataLength\":256,\"preserve\":true},\"rp\":{\"id\":\"${RPID}\",\"name\":\"FIDOServer\"},\"extensions\":{},\"mds\":{\"authenticatorStatusReport\":[{\"status\":\"FIDO_CERTIFIED_L1\",\"priority\":\"1\",\"decision\":\"IGNORE\"},{\"status\":\"FIDO_CERTIFIED_L2\",\"priority\":\"1\",\"decision\":\"ACCEPT\"},{\"status\":\"UPDATE_AVAILABLE\",\"priority\":\"5\",\"decision\":\"IGNORE\"},{\"status\":\"REVOKED\",\"priority\":\"10\",\"decision\":\"DENY\"}]},\"jwt\":{\"algorithms\":[\"ES256\",\"ES384\",\"ES521\"],\"duration\":${JWT_DURATION},\"required\":[\"rpid\",\"iat\",\"exp\",\"cip\",\"uname\",\"agent\"]},\"signcerts\":{\"rootca\":{\"subjectdn\":\"$ROOT_CA_SUBJECT_DN\",\"serialnumber\":\"$ROOT_CA_SERIAL\",\"pemcert\":\"$ROOT_CA_PEM\",\"jwtcerts\":{\"default\":[${JWT_CERTS_LIST:1}]},\"samlcerts\":{\"default\":[${SAML_CERTS_LIST:1}],\"citrixidp\":{\"subjectdn\":\"CN=SKFS SAML Signer 1,$(echo $SAML_KEYGEN_DN | sed -e "s/{domain}/5/g")\",\"serialnumber\":\"$((16#$(openssl x509 -in samlsigning-5-1.pem -noout -serial | awk -F 'serial=' '{print $2}')))\",\"pemcert\":\"$(cat samlsigning-5-1.pem | tr -d $'\r' | tr -d '\n')\"}}}}}}" | /usr/bin/base64 -w 0)
        $STRONGKEY_HOME/$MARIATGT/bin/mysql --user=skfsdbuser --password=$MARIA_SKFSDBUSER_PASSWORD --database=skfs -e "insert into FIDO_POLICIES values (1,5,5,'${fidoPolicy}','Active','',NOW(),NULL,NULL);"
        
        # Domain 6
        $STRONGKEY_HOME/$MARIATGT/bin/mysql --user=skfsdbuser --password=$MARIA_SKFSDBUSER_PASSWORD --database=skfs -e "insert into DOMAINS values (6,'SKFS 6','Active','Active','',NULL,'',NULL,'CN=SKFS Signing Key,OU=DID 6,OU=SKFS EC Signing Certificate 1,O=StrongKey','https://$(hostname):8181/app.json',NULL);"
        ROOT_CA_SUBJECT_DN=$(openssl x509 -in ssoca-6.pem -noout -subject -nameopt rfc2253 | awk -F 'subject=' '{print $2}')
        ROOT_CA_SERIAL=$((16#$(openssl x509 -in ssoca-6.pem -noout -serial | awk -F 'serial=' '{print $2}')))
        ROOT_CA_PEM="$(cat ssoca-6.pem | tr -d $'\r' | tr -d '\n')"
        JWT_CERTS_LIST=
        if [ "${JWT_CREATE,,}" = "true" ]; then
                for (( CERT_NUM = 1; CERT_NUM <= JWT_CN_COUNT; CERT_NUM++ )); do
                        JWT_SUBJECT_DN=$(openssl x509 -in jwtsigning-6-$CERT_NUM.pem -noout -subject -nameopt rfc2253 | awk -F 'subject=' '{print $2}')
                        JWT_SERIAL=$((16#$(openssl x509 -in jwtsigning-6-$CERT_NUM.pem -noout -serial | awk -F 'serial=' '{print $2}')))
                        JWT_PEM="$(cat jwtsigning-6-$CERT_NUM.pem | tr -d $'\r' | tr -d '\n')"
                        JWT_CERTS_LIST="$JWT_CERTS_LIST,{\"subjectdn\":\"$JWT_SUBJECT_DN\",\"serialnumber\":\"$JWT_SERIAL\",\"pemcert\":\"$JWT_PEM\"}"
                done
        fi
        SAML_CERTS_LIST=
        if [ "${SAML_RESPONSE,,}" = "true" ]; then
                for (( CERT_NUM = 1; CERT_NUM <= SAML_CN_COUNT; CERT_NUM++ )); do
                        SAML_SUBJECT_DN=$(openssl x509 -in samlsigning-6-$CERT_NUM.pem -noout -subject -nameopt rfc2253 | awk -F 'subject=' '{print $2}')
                        SAML_SERIAL=$((16#$(openssl x509 -in samlsigning-6-$CERT_NUM.pem -noout -serial | awk -F 'serial=' '{print $2}')))
                        SAML_PEM="$(cat samlsigning-6-$CERT_NUM.pem | tr -d $'\r' | tr -d '\n')"
                        SAML_CERTS_LIST="$SAML_CERTS_LIST,{\"subjectdn\":\"$SAML_SUBJECT_DN\",\"serialnumber\":\"$SAML_SERIAL\",\"pemcert\":\"$SAML_PEM\"}"
                done
        fi
        fidoPolicy=$(echo "{\"FidoPolicy\":{\"name\":\"RestrictedSKFSPolicy-Android-Key\",\"copyright\":\"StrongAuth, Inc. (DBA StrongKey) All Rights Reserved\",\"version\":\"2.0\",\"startDate\":\"${startDate}\",\"endDate\":\"1760103870871\",\"system\":{\"did\":6,\"requireCounter\":\"mandatory\",\"integritySignatures\":true,\"userVerification\":[\"required\"],\"userPresenceTimeout\":30,\"allowedAaguids\":[\"b93fd961-f2e6-462f-b122-82002247de78\"],\"transport\":[\"usb\",\"internal\"]},\"crossOrigin\":{\"enabled\":$CROSS_ORIGIN_ENABLED,\"allowedOrigins\":[]},\"algorithms\":{\"curves\":[\"secp256r1\",\"secp384r1\",\"secp521r1\",\"curve25519\"],\"rsa\":[\"none\"],\"signatures\":[\"ES256\",\"ES384\",\"ES512\",\"EdDSA\",\"ES256K\"]},\"attestation\":{\"conveyance\":[\"direct\"],\"formats\":[\"android-key\"]},\"registration\":{\"displayName\":\"required\",\"attachment\":[\"platform\"],\"discoverableCredential\":[\"required\"],\"excludeCredentials\":\"enabled\"},\"authentication\":{\"allowCredentials\":\"enabled\"},\"authorization\":{\"maxdataLength\":256,\"preserve\":true},\"rp\":{\"id\":\"${RPID}\",\"name\":\"FIDOServer\"},\"extensions\":{\"uvm\":{\"allowedMethods\":[\"presence\",\"fingerprint\",\"passcode\",\"voiceprint\",\"faceprint\",\"eyeprint\",\"pattern\",\"handprint\"],\"allowedKeyProtections\":[\"hardware\",\"secureElement\"],\"allowedProtectionTypes\":[\"tee\",\"chip\"]}},\"mds\":{\"authenticatorStatusReport\":[{\"status\":\"FIDO_CERTIFIED_L1\",\"priority\":\"1\",\"decision\":\"IGNORE\"},{\"status\":\"FIDO_CERTIFIED_L2\",\"priority\":\"1\",\"decision\":\"ACCEPT\"},{\"status\":\"UPDATE_AVAILABLE\",\"priority\":\"5\",\"decision\":\"IGNORE\"},{\"status\":\"REVOKED\",\"priority\":\"10\",\"decision\":\"DENY\"}]},\"jwt\":{\"algorithms\":[\"ES256\",\"ES384\",\"ES521\"],\"duration\":${JWT_DURATION},\"required\":[\"rpid\",\"iat\",\"exp\",\"cip\",\"uname\",\"agent\"]},\"signcerts\":{\"rootca\":{\"subjectdn\":\"$ROOT_CA_SUBJECT_DN\",\"serialnumber\":\"$ROOT_CA_SERIAL\",\"pemcert\":\"$ROOT_CA_PEM\",\"jwtcerts\":{\"default\":[${JWT_CERTS_LIST:1}]},\"samlcerts\":{\"default\":[${SAML_CERTS_LIST:1}],\"citrixidp\":{\"subjectdn\":\"CN=SKFS SAML Signer 1,$(echo $SAML_KEYGEN_DN | sed -e "s/{domain}/6/g")\",\"serialnumber\":\"$((16#$(openssl x509 -in samlsigning-6-1.pem -noout -serial | awk -F 'serial=' '{print $2}')))\",\"pemcert\":\"$(cat samlsigning-6-1.pem | tr -d $'\r' | tr -d '\n')\"}}}}}}" | /usr/bin/base64 -w 0)
        $STRONGKEY_HOME/$MARIATGT/bin/mysql --user=skfsdbuser --password=$MARIA_SKFSDBUSER_PASSWORD --database=skfs -e "insert into FIDO_POLICIES values (1,6,6,'${fidoPolicy}','Active','',NOW(),NULL,NULL);"
        
        # Domain 7
        $STRONGKEY_HOME/$MARIATGT/bin/mysql --user=skfsdbuser --password=$MARIA_SKFSDBUSER_PASSWORD --database=skfs -e "insert into DOMAINS values (7,'SKFS 7','Active','Active','',NULL,'',NULL,'CN=SKFS Signing Key,OU=DID 7,OU=SKFS EC Signing Certificate 1,O=StrongKey','https://$(hostname):8181/app.json',NULL);"
        ROOT_CA_SUBJECT_DN=$(openssl x509 -in ssoca-7.pem -noout -subject -nameopt rfc2253 | awk -F 'subject=' '{print $2}')
        ROOT_CA_SERIAL=$((16#$(openssl x509 -in ssoca-7.pem -noout -serial | awk -F 'serial=' '{print $2}')))
        ROOT_CA_PEM="$(cat ssoca-7.pem | tr -d $'\r' | tr -d '\n')"
        JWT_CERTS_LIST=
        if [ "${JWT_CREATE,,}" = "true" ]; then
                for (( CERT_NUM = 1; CERT_NUM <= JWT_CN_COUNT; CERT_NUM++ )); do
                        JWT_SUBJECT_DN=$(openssl x509 -in jwtsigning-7-$CERT_NUM.pem -noout -subject -nameopt rfc2253 | awk -F 'subject=' '{print $2}')
                        JWT_SERIAL=$((16#$(openssl x509 -in jwtsigning-7-$CERT_NUM.pem -noout -serial | awk -F 'serial=' '{print $2}')))
                        JWT_PEM="$(cat jwtsigning-7-$CERT_NUM.pem | tr -d $'\r' | tr -d '\n')"
                        JWT_CERTS_LIST="$JWT_CERTS_LIST,{\"subjectdn\":\"$JWT_SUBJECT_DN\",\"serialnumber\":\"$JWT_SERIAL\",\"pemcert\":\"$JWT_PEM\"}"
                done
        fi
        SAML_CERTS_LIST=
        if [ "${SAML_RESPONSE,,}" = "true" ]; then
                for (( CERT_NUM = 1; CERT_NUM <= SAML_CN_COUNT; CERT_NUM++ )); do
                        SAML_SUBJECT_DN=$(openssl x509 -in samlsigning-7-$CERT_NUM.pem -noout -subject -nameopt rfc2253 | awk -F 'subject=' '{print $2}')
                        SAML_SERIAL=$((16#$(openssl x509 -in samlsigning-7-$CERT_NUM.pem -noout -serial | awk -F 'serial=' '{print $2}')))
                        SAML_PEM="$(cat samlsigning-7-$CERT_NUM.pem | tr -d $'\r' | tr -d '\n')"
                        SAML_CERTS_LIST="$SAML_CERTS_LIST,{\"subjectdn\":\"$SAML_SUBJECT_DN\",\"serialnumber\":\"$SAML_SERIAL\",\"pemcert\":\"$SAML_PEM\"}"
                done
        fi
        fidoPolicy=$(echo "{\"FidoPolicy\":{\"name\":\"RestrictedSKFSPolicy-Apple\",\"copyright\":\"StrongAuth, Inc. (DBA StrongKey) All Rights Reserved\",\"version\":\"2.0\",\"startDate\":\"${startDate}\",\"endDate\":\"1760103870871\",\"system\":{\"did\":7,\"requireCounter\":\"optional\",\"integritySignatures\":true,\"userVerification\":[\"required\"],\"userPresenceTimeout\":30,\"allowedAaguids\":[\"all\"],\"transport\":[\"usb\",\"internal\"]},\"crossOrigin\":{\"enabled\":$CROSS_ORIGIN_ENABLED,\"allowedOrigins\":[]},\"algorithms\":{\"curves\":[\"secp256r1\",\"secp384r1\",\"secp521r1\",\"curve25519\"],\"rsa\":[\"none\"],\"signatures\":[\"ES256\",\"ES384\",\"ES512\",\"EdDSA\",\"ES256K\"]},\"attestation\":{\"conveyance\":[\"direct\"],\"formats\":[\"apple\",\"none\"]},\"registration\":{\"displayName\":\"required\",\"attachment\":[\"platform\"],\"discoverableCredential\":[\"required\"],\"excludeCredentials\":\"enabled\"},\"authentication\":{\"allowCredentials\":\"enabled\"},\"authorization\":{\"maxdataLength\":256,\"preserve\":true},\"rp\":{\"id\":\"$(hostname)\",\"name\":\"FIDOServer\"},\"extensions\":{},\"mds\":{\"authenticatorStatusReport\":[{\"status\":\"FIDO_CERTIFIED_L1\",\"priority\":\"1\",\"decision\":\"IGNORE\"},{\"status\":\"FIDO_CERTIFIED_L2\",\"priority\":\"1\",\"decision\":\"ACCEPT\"},{\"status\":\"UPDATE_AVAILABLE\",\"priority\":\"5\",\"decision\":\"IGNORE\"},{\"status\":\"REVOKED\",\"priority\":\"10\",\"decision\":\"DENY\"}]},\"jwt\":{\"algorithms\":[\"ES256\",\"ES384\",\"ES521\"],\"duration\":${JWT_DURATION},\"required\":[\"rpid\",\"iat\",\"exp\",\"cip\",\"uname\",\"agent\"]},\"signcerts\":{\"rootca\":{\"subjectdn\":\"$ROOT_CA_SUBJECT_DN\",\"serialnumber\":\"$ROOT_CA_SERIAL\",\"pemcert\":\"$ROOT_CA_PEM\",\"jwtcerts\":{\"default\":[${JWT_CERTS_LIST:1}]},\"samlcerts\":{\"default\":[${SAML_CERTS_LIST:1}],\"citrixidp\":{\"subjectdn\":\"CN=SKFS SAML Signer 1,$(echo $SAML_KEYGEN_DN | sed -e "s/{domain}/7/g")\",\"serialnumber\":\"$((16#$(openssl x509 -in samlsigning-7-1.pem -noout -serial | awk -F 'serial=' '{print $2}')))\",\"pemcert\":\"$(cat samlsigning-7-1.pem | tr -d $'\r' | tr -d '\n')\"}}}}}}" | /usr/bin/base64 -w 0)
        $STRONGKEY_HOME/$MARIATGT/bin/mysql --user=skfsdbuser --password=$MARIA_SKFSDBUSER_PASSWORD --database=skfs -e "insert into FIDO_POLICIES values (1,7,7,'${fidoPolicy}','Active','',NOW(),NULL,NULL);"
        
        # Domain 8
        $STRONGKEY_HOME/$MARIATGT/bin/mysql --user=skfsdbuser --password=$MARIA_SKFSDBUSER_PASSWORD --database=skfs -e "insert into DOMAINS values (8,'SKFS 8','Active','Active','',NULL,'',NULL,'CN=SKFS Signing Key,OU=DID 8,OU=SKFS EC Signing Certificate 1,O=StrongKey','https://$(hostname):8181/app.json',NULL);"
        ROOT_CA_SUBJECT_DN=$(openssl x509 -in ssoca-8.pem -noout -subject -nameopt rfc2253 | awk -F 'subject=' '{print $2}')
        ROOT_CA_SERIAL=$((16#$(openssl x509 -in ssoca-8.pem -noout -serial | awk -F 'serial=' '{print $2}')))
        ROOT_CA_PEM="$(cat ssoca-8.pem | tr -d $'\r' | tr -d '\n')"
        JWT_CERTS_LIST=
        if [ "${JWT_CREATE,,}" = "true" ]; then
                for (( CERT_NUM = 1; CERT_NUM <= JWT_CN_COUNT; CERT_NUM++ )); do
                        JWT_SUBJECT_DN=$(openssl x509 -in jwtsigning-8-$CERT_NUM.pem -noout -subject -nameopt rfc2253 | awk -F 'subject=' '{print $2}')
                        JWT_SERIAL=$((16#$(openssl x509 -in jwtsigning-8-$CERT_NUM.pem -noout -serial | awk -F 'serial=' '{print $2}')))
                        JWT_PEM="$(cat jwtsigning-8-$CERT_NUM.pem | tr -d $'\r' | tr -d '\n')"
                        JWT_CERTS_LIST="$JWT_CERTS_LIST,{\"subjectdn\":\"$JWT_SUBJECT_DN\",\"serialnumber\":\"$JWT_SERIAL\",\"pemcert\":\"$JWT_PEM\"}"
                done
        fi
        SAML_CERTS_LIST=
        if [ "${SAML_RESPONSE,,}" = "true" ]; then
                for (( CERT_NUM = 1; CERT_NUM <= SAML_CN_COUNT; CERT_NUM++ )); do
                        SAML_SUBJECT_DN=$(openssl x509 -in samlsigning-8-$CERT_NUM.pem -noout -subject -nameopt rfc2253 | awk -F 'subject=' '{print $2}')
                        SAML_SERIAL=$((16#$(openssl x509 -in samlsigning-8-$CERT_NUM.pem -noout -serial | awk -F 'serial=' '{print $2}')))
                        SAML_PEM="$(cat samlsigning-8-$CERT_NUM.pem | tr -d $'\r' | tr -d '\n')"
                        SAML_CERTS_LIST="$SAML_CERTS_LIST,{\"subjectdn\":\"$SAML_SUBJECT_DN\",\"serialnumber\":\"$SAML_SERIAL\",\"pemcert\":\"$SAML_PEM\"}"
                done
        fi
        fidoPolicy=$(echo "{\"FidoPolicy\":{\"name\":\"RestrictedSKFSPolicy-FIPS\",\"copyright\":\"StrongAuth, Inc. (DBA StrongKey) All Rights Reserved\",\"version\":\"2.0\",\"startDate\":\"${startDate}\",\"endDate\":\"1760103870871\",\"system\":{\"did\":8,\"requireCounter\":\"mandatory\",\"integritySignatures\":true,\"userVerification\":[\"required\"],\"userPresenceTimeout\":30,\"allowedAaguids\":[\"c1f9a0bc-1dd2-404a-b27f-8e29047a43fd\"],\"transport\":[\"usb\",\"internal\"]},\"crossOrigin\":{\"enabled\":$CROSS_ORIGIN_ENABLED,\"allowedOrigins\":[]},\"algorithms\":{\"curves\":[\"secp256r1\",\"secp384r1\",\"secp521r1\",\"curve25519\"],\"rsa\":[\"none\"],\"signatures\":[\"ES256\",\"ES384\",\"ES512\",\"EdDSA\",\"ES256K\"]},\"attestation\":{\"conveyance\":[\"direct\"],\"formats\":[\"packed\"]},\"registration\":{\"displayName\":\"required\",\"attachment\":[\"cross-platform\"],\"discoverableCredential\":[\"required\",\"preferred\",\"discouraged\"],\"excludeCredentials\":\"enabled\"},\"authentication\":{\"allowCredentials\":\"enabled\"},\"authorization\":{\"maxdataLength\":256,\"preserve\":true},\"rp\":{\"id\":\"${RPID}\",\"name\":\"FIDOServer\"},\"extensions\":{},\"mds\":{\"authenticatorStatusReport\":[{\"status\":\"FIDO_CERTIFIED_L1\",\"priority\":\"1\",\"decision\":\"IGNORE\"},{\"status\":\"FIDO_CERTIFIED_L2\",\"priority\":\"1\",\"decision\":\"ACCEPT\"},{\"status\":\"UPDATE_AVAILABLE\",\"priority\":\"5\",\"decision\":\"IGNORE\"},{\"status\":\"REVOKED\",\"priority\":\"10\",\"decision\":\"DENY\"}]},\"jwt\":{\"algorithms\":[\"ES256\",\"ES384\",\"ES521\"],\"duration\":${JWT_DURATION},\"required\":[\"rpid\",\"iat\",\"exp\",\"cip\",\"uname\",\"agent\"]},\"signcerts\":{\"rootca\":{\"subjectdn\":\"$ROOT_CA_SUBJECT_DN\",\"serialnumber\":\"$ROOT_CA_SERIAL\",\"pemcert\":\"$ROOT_CA_PEM\",\"jwtcerts\":{\"default\":[${JWT_CERTS_LIST:1}]},\"samlcerts\":{\"default\":[${SAML_CERTS_LIST:1}],\"citrixidp\":{\"subjectdn\":\"CN=SKFS SAML Signer 1,$(echo $SAML_KEYGEN_DN | sed -e "s/{domain}/8/g")\",\"serialnumber\":\"$((16#$(openssl x509 -in samlsigning-8-1.pem -noout -serial | awk -F 'serial=' '{print $2}')))\",\"pemcert\":\"$(cat samlsigning-8-1.pem | tr -d $'\r' | tr -d '\n')\"}}}}}}" | /usr/bin/base64 -w 0)
        $STRONGKEY_HOME/$MARIATGT/bin/mysql --user=skfsdbuser --password=$MARIA_SKFSDBUSER_PASSWORD --database=skfs -e "insert into FIDO_POLICIES values (1,8,8,'${fidoPolicy}','Active','',NOW(),NULL,NULL);"
        
fi

# Add users to other policy domains
if [ ${POLICY_DOMAINS^^} = "ALL" ]; then
        for (( DID = 2; DID <= 8 ; DID++ )); do
                $SKFS_SOFTWARE/create-SKFS-Users.sh $DID $OPENLDAP_PASS $SERVICE_LDAP_SVCUSER_PASS $SKFS_SOFTWARE/$SKFS_LDIF
        done
fi

chown strongkey:strongkey $GLASSFISH_HOME/domains/domain1/docroot/app.json
echo -n "Deploying StrongKey FidoServer ... "
cp $SKFS_SOFTWARE/fidoserver.ear /tmp
$GLASSFISH_HOME/bin/asadmin deploy /tmp/fidoserver.ear
rm /tmp/fidoserver.ear


# Copy files to various locations
cp $SKFS_SOFTWARE/applerootca.crt $SKFS_HOME

echo "Done!"
