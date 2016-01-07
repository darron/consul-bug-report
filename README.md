Consul Bug Report
===========================

**IMPORTANT NOTE:** Consul 0.6.x has fixed this particular problem. I have been testing it at more than 4 times the previous limit - where it was dead and it's fine.

**Great work Hashicorp, @slackpad and @armon!**

First - make sure you've setup the [ENV variables you need for AWS](https://www.packer.io/docs/builders/amazon-ebs.html), then build the AMI:

```
packer build packer.json
```

Then you need to copy and update the variables file:

```
cp consul/variables.dist consul/variables.tf
vi variables.tf
```

Then update the `DD_API` key in `consul/scripts/datadog.sh` - when the bootstrap and server nodes boot - make sure to add 'role:consul-server' to them in the web UI so that you can aggregate the data. You can sign up for a [free account to test](https://www.datadoghq.com/) - click on "Get Started Free".

Boot the cluster with `cd consul && terraform apply`. Once the cluster is up and running, give it a few minutes to settle down. This is how it looks at rest:

[http://shared.froese.org/2015/f01gy-13-10.jpg](http://shared.froese.org/2015/f01gy-13-10.jpg)

NOTE: We saw problems at just over 100 nodes - we're spinning up 120 by default - at .02 / hour it's a very cheap test.

To get it into an unstable mode, first, ssh to a server or bootstrap node:

```
# Setup the KV values.
consulkv set services/bubs 1
consulkv set services/bunk 1
consulkv set services/cassandra 1
consulkv set services/consul 1
consulkv set services/context-server 1
consulkv set services/daniels 1
consulkv set services/delancie 1
consulkv set services/haproxy 1
consulkv set services/kafka 1
consulkv set services/lamar 1
consulkv set services/postgresql 1
consulkv set services/rawls 1
consulkv set services/redis 1
consulkv set services/spidly 1
consulkv set services/spiros 1
# Generates some CPU stress.
consul event -service datadog -name destress
consul event -service datadog -name stress
# Get Consul Template going.
consul exec -service datadog "cd /tmp && rm -f services.cfg"
consul exec -service datadog "cd /tmp && wget https://gist.githubusercontent.com/darron/bf8dd32540d1dc09dac3/raw/433910515fd7a7070cbfe5a932363ec9f43a3688/services.cfg"
consul exec -service datadog "cd /tmp && wget https://gist.githubusercontent.com/darron/22c88190b69b5f20095f/raw/66fba5b4fead6255589ba01fb8306671ddf428b0/services.ctmpl"
consul exec -service datadog "consul-template -config /tmp/services.cfg &"
consul exec -service datadog "cd /tmp && wget https://gist.githubusercontent.com/darron/a4e5a51325dc7d4feddf/raw/2673f9438c0a740125ad0071ea7efade8a477c49/consul-template.conf"
consul exec -service datadog "cd /tmp && chmod 644 consul-template.conf && sudo mv consul-template.conf /etc/init/"
consul exec -service datadog "cd /etc/init.d/ && sudo ln -s /lib/init/upstart-job consul-template"
consul exec -service datadog "sudo service consul-template start"
```

Pick 3 random client nodes and login - every minute stop or start Consul on each node. Rotate back and forth. This makes Consul Template run at least every minute.

Doing this - I was able to make the cluster very unstable and lose quorum over and over:

[http://shared.froese.org/2015/lw2mf-11-03.jpg](http://shared.froese.org/2015/lw2mf-11-03.jpg)

[http://shared.froese.org/2015/cobi3-14-13.jpg](http://shared.froese.org/2015/cobi3-14-13.jpg)

Once you've have enough debugging - you can calm it all down like this:

```
consul exec -service datadog sudo pkill consul-template
consul event -service datadog -name destress
```

Then a simple `terraform destroy` will remove your cluster.
