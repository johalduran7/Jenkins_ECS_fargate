# lambda_function.py

import boto3
import os

ec2 = boto3.client('ec2')

def handler(event, context):
    instance_id = event['detail']['instance-id']
    
    # Describe the instance to get its tags
    response = ec2.describe_instances(InstanceIds=[instance_id])
    instance_tags = response['Reservations'][0]['Instances'][0].get('Tags', [])
    
    # Check if the instance has the Name tag and if it's "jenkins_master"
    instance_name = next((tag['Value'] for tag in instance_tags if tag['Key'] == 'Name'), None)
    
    if instance_name != "jenkins_master":
        print(f"Ignoring instance {instance_id} with Name tag: {instance_name}")
        return {
            'statusCode': 200,
            'body': f"Ignored instance {instance_id} (not jenkins_master)"
        }
    
    # Get the volume ID of the instance
    volume_id = response['Reservations'][0]['Instances'][0]['BlockDeviceMappings'][0]['Ebs']['VolumeId']
    
    # Create a snapshot of the volume
    snapshot = ec2.create_snapshot(
        VolumeId=volume_id,
        Description=f"Snapshot of {volume_id} before instance {instance_id} termination",
        TagSpecifications=[
            {
                'ResourceType': 'snapshot',
                'Tags': [
                    {
                        'Key': 'Name',
                        'Value': os.environ['SNAPSHOT_TAG']
                    }
                ]
            }
        ]
    )
    
    print(f"Created snapshot {snapshot['SnapshotId']} for volume {volume_id}")
    
    return {
        'statusCode': 200,
        'body': f"Snapshot {snapshot['SnapshotId']} created successfully"
    }