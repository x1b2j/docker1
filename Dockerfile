# DockerFile for the "chef_server".

FROM centos
MAINTAINER gaurav rajut [@x1b2j] <gx1b2j@gmail.com>

RUN rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm && \
    yum -y install wget && \
    wget https://opscode-omnibus-packages.s3.amazonaws.com/el/6/x86_64/chef-11.8.0-1.el6.x86_64.rpm -O /tmp/chef-client.rpm && \
    wget https://opscode-omnibus-packages.s3.amazonaws.com/el/6/x86_64/chef-server-11.0.8-1.el6.x86_64.rpm -O /tmp/chef-server.rpm && \
    yum -y update && \
    yum -y localinstall /tmp/chef-server.rpm /tmp/chef-client.rpm && \
    if [ ! -d /etc/chef-server ]; then mkdir /etc/chef-server; fi && \
    touch /etc/chef-server/chef-server.rb && \
    sed -i 's/false/true/g' /etc/chef-server/chef-server.rb && \
    echo "erchef['s3_url_ttl'] = 3600" >> /etc/chef-server/chef-server.rb && \
    yum -y install hostname && \
    /usr/bin/hostname chef.x1b2j.com && \
    echo "127.0.0.1     chef.x1b2j.com" >> /etc/hosts && \
    chef-server-ctl reconfigure && \

    iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 443 -j ACCEPT && \
    iptables-save > /etc/sysconfig/iptables && \

    # Configuring Knife

    chmod -R a+r /etc/chef-server && \
    mkdir /root/.chef && \
    touch /root/.chef/knife.rb && \

    knife configure -u root --validation-client-name chef-validator --validation-key /etc/chef-server/chef-validator.pem \
    -s https://$CHEF_PRIVATE_IP --admin-client-name admin --admin-client-key /etc/chef-server/admin.pem -c /root/.chef/knife.rb -y -r '' && \

    knife user create -a -s https://localhost -c /root/.chef/knife.rb -u admin -p 'ap@aws' --disable-editing \
    -k /etc/chef-server/admin.pem root > /root/.chef/root.pem && \

    while [ $? != "0" ]; do sleep 4 && knife user create -a -s https://localhost -c /root/.chef/knife.rb -u admin -p 'ap@docker' --disable-editing \
    -k /etc/chef-server/admin.pem root > /root/.chef/root.pem; done && \

#    knife cookbook upload -o /tmp/cookbooks/ -a --config /root/.chef/knife.rb && \
#    knife role from file /tmp/cookbooks/roles/*.rb && \
    knife data bag create password && \
    knife data bag create rds && \

    wget http://stedolan.github.io/jq/download/linux64/jq -O /tmp/jq && \
    chmod a+x /tmp/jq && \
    mv /tmp/jq /usr/bin && \

EXPOSE 443

CMD /bin/bash
