 # the following script points the Route 53 Alias record to the backup Elastic Load Balancer
#!/bin/bash 
# By: Aniruddh Prakash
# Date: 21/08/2020
#Script: route53upsertbackup.sh


lb2=$(aws elb describe-load-balancers --region eu-west-1| grep DNSName | cut -d '"' -f 4| tail -n 1)
cat > route53upsertbackup.json <<EOF
{
     "Comment": "Creating Alias record in Route 53 for the ELB under primary.cnimigration.com",
     "Changes": [{
                "Action": "UPSERT",
                "ResourceRecordSet": {
                            "Name": "wordpress.primary.cnimigration.com",
                            "Type": "A",
                            "AliasTarget":{
                                    "HostedZoneId": "Z32O12XQLNTSW2",
                                    "DNSName": "dualstack.$lb2",
                                    "EvaluateTargetHealth": false
                              }}
                          }]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id Z09925561SH298J5Q5C6K --change-batch file://route53upsertbackup.json

