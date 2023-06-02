#!/bin/bash

( for name in $(oc get egressips -o name); do

  name=${name##*/}

  status_entries=($(oc get egressip $name -o jsonpath='{range .status.items[*]}{.egressIP},{.node}{"\n"}{end}'))

  for ip in $(oc get egressip $name -o jsonpath='{range .spec.egressIPs[*]}{@}{"\n"}{end}'); do
    node=""; eni=""

    for status_entry in "${status_entries[@]}"; do
      if [[ ${status_entry%,*} == $ip ]]; then
        node=${status_entry##*,}

        instance_id=$(aws ec2 describe-instances \
          --filter "Name=network-interface.addresses.private-ip-address,Values=$ip" \
          --query "Reservations[*].Instances[*].[InstanceId]" \
          --output text)

        eni_id=$(aws ec2 describe-network-interfaces \
          --filter "Name=addresses.private-ip-address,Values=$ip" \
          --query "NetworkInterfaces[*].NetworkInterfaceId" \
          --output text)
        break
      fi
    done
    echo $name,$ip,$node,$instance_id,$eni_id

  done

done ) | column -t -s, -N "EgressIP,IP Address,Node,Instance Id,ENI"
