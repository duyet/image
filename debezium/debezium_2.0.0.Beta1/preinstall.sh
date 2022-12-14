#!/bin/bash

if [ "$JAVA_HOME" ]; then
    javahome=${JAVA_HOME}
elif [[ "$OSTYPE" == "linux-gnu" ]]; then # Linux
    javahome=$(readlink -f $(which java) | sed "s:bin/java::")
elif [[ "$OSTYPE" == "darwin"* ]]; then # Mac OS X
    javahome="$(/usr/libexec/java_home)/jre"
fi

mydir=$javahome/lib/security/cacerts
mydir=/tmp/cacerts
mkdir $mydir

truststore=${mydir}/rds-truststore.jks
truststore=$javahome/lib/security/cacerts

storepassword=changeit

curl -sS "https://s3.amazonaws.com/rds-downloads/rds-combined-ca-bundle.pem" > ${mydir}/rds-combined-ca-bundle.pem
awk 'split_after == 1 {n++;split_after=0} /-----END CERTIFICATE-----/ {split_after=1}{print > "rds-ca-" n ".pem"}' < ${mydir}/rds-combined-ca-bundle.pem

for CERT in rds-ca-*; do
  alias=$(openssl x509 -noout -text -in $CERT | perl -ne 'next unless /Subject:/; s/.*(CN=|CN = )//; print')
  echo "Importing $alias"
  keytool -import -file ${CERT} -alias "${alias}" -storepass ${storepassword} -keystore ${truststore} -noprompt
  rm $CERT
done

rm ${mydir}/rds-combined-ca-bundle.pem

echo "Trust store content is: "

keytool -list -v -keystore "$truststore" -storepass ${storepassword} | grep Alias | cut -d " " -f3- | while read alias 
do
   expiry=`keytool -list -v -keystore "$truststore" -storepass ${storepassword} -alias "${alias}" | grep Valid | perl -ne 'if(/until: (.*?)\n/) { print "$1\n"; }'`
   echo " Certificate ${alias} expires in '$expiry'" 
done

wget -O plugin.zip https://repo1.maven.org/maven2/io/debezium/debezium-connector-mongodb/2.0.0.Beta1/debezium-connector-mongodb-2.0.0.Beta1-plugin.zip
unzip plugin.zip -d /usr/share/plugins
