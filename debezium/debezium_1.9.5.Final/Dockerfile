FROM debezium/connect:1.9.5.Final

USER root
RUN microdnf install -y perl openssl wget && microdnf clean all
COPY debezium/debezium_1.9.5.Final/preinstall.sh preinstall.sh
RUN ./preinstall.sh

ENV CONNECT_PLUGIN_PATH /usr/share/java,/usr/share/confluent-hub-components,/usr/share/plugins
