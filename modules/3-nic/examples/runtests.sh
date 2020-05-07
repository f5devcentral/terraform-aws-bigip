#terraform show -json | jq '.values.root_module.resources[] | select(.address | contains("random_password.bigippassword"))  | .values.result' > inspec/bigip-ready/files/password.json

export BIGIP_IPS=`terraform output --json | jq -cr '.bigip_mgmt_ips.value[]'`
export BIGIP_USER=admin
export BIGIP_PASSWORD=`terraform show -json | jq .values.root_module.resources[] | jq -r 'select(.address | contains("random_password")).values.result'`
export DO_VERSION=1.11.1
export AS3_VERSION=3.13.2
export TS_VERSION=1.10.0

for ip in $BIGIP_IPS; do 
    echo $row
    inspec exec bigip-atc --reporter cli --show-progress --input bigip_address=$ip bigip_port=443 user=$BIGIP_USER password=$BIGIP_PASSWORD do_version=$DO_VERSION as3_version=$AS3_VERSION ts_version=$TS_VERSION
done

