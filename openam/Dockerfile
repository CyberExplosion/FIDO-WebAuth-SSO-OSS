# FOR APACHE HTTP Tutorial
FROM httpd:2.4.34

ENV PA_PASSWORD 12345678

RUN apt-get update || true

# RUN wget --show-progress --progress=bar:force:noscroll --quiet --output-document=/tmp/Apache_v24_Linux_64bit_4.1.1.zip https://github.com/OpenIdentityPlatform/OpenAM-Web-Agents/releases/download/4.1.1/Apache_v24_Linux_64bit_4.1.1.zip
# 
# RUN unzip /tmp/Apache_v24_Linux_64bit_4.1.1.zip -d /usr/

# RUN rm /tmp/Apache_v24_Linux_64bit_4.1.1.zip
COPY apache24_agent /usr/web_agents/apache24_agent

RUN echo $PA_PASSWORD > /tmp/pwd.txt

RUN cat /tmp/pwd.txt

RUN set -x && cd /usr/web_agents/apache24_agent/ && ls

RUN cat /etc/issue

RUN set -x && /usr/web_agents/apache24_agent/bin/agentadmin --s "/usr/local/apache2/conf/httpd.conf" "http://openam.example.com:8080/openam" "http://example.com:80" "/" "apache_agent" "/tmp/pwd.txt" --acceptLicence --changeOwner || true

RUN cat /usr/web_agents/apache24_agent/bin/../log/install_20231128055357.log || true