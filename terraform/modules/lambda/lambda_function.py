import boto3
import os

ec2 = boto3.client('ec2')
ssm = boto3.client('ssm')

def handler(event, context):
    instance_id = event['detail']['instance-id']
    
    # Describe the instance to get its tags
    response = ec2.describe_instances(InstanceIds=[instance_id])
    
    if not response.get('Reservations'):
        raise ValueError(f"No reservations found for instance {instance_id}")

    instances = response['Reservations'][0].get('Instances', [])
    if not instances:
        raise ValueError(f"No instances found in reservation for {instance_id}")

    instance_tags = instances[0].get('Tags', [])
    
    # Check if the instance has the Name tag and if it's "jenkins_master"
    instance_name = next((tag['Value'] for tag in instance_tags if tag['Key'] == 'Name'), None)
    
    if instance_name != "jenkins_master":
        print(f"Ignoring instance {instance_id} with Name tag: {instance_name}")
        return {
            'statusCode': 200,
            'body': f"Ignored instance {instance_id} (not jenkins_master)"
        }
    
    # Get the volume ID of the instance
    block_devices = instances[0].get('BlockDeviceMappings', [])
    if not block_devices:
        raise ValueError(f"No block devices found for instance {instance_id}")

    volume_id = block_devices[0].get('Ebs', {}).get('VolumeId')
    if not volume_id:
        raise ValueError(f"No EBS volume found for instance {instance_id}")

    # Get the previous snapshot for the volume
    snapshots_response = ec2.describe_snapshots(
        Filters=[
            {'Name': 'volume-id', 'Values': [volume_id]},
            {'Name': 'tag:Name', 'Values': ['jenkins_backup']}  # Assuming 'jenkins_backup' is used as tag for snapshots
        ]
    )
    
    snapshots = snapshots_response.get('Snapshots', [])
    if snapshots:
        # Delete the previous snapshot
        latest_snapshot = sorted(snapshots, key=lambda x: x['StartTime'], reverse=True)[0]  # Get the latest snapshot
        print(f"Deleting snapshot {latest_snapshot['SnapshotId']}")
        ec2.delete_snapshot(SnapshotId=latest_snapshot['SnapshotId'])
    
    # Get snapshot tag from environment variable
    snapshot_tag = os.environ.get('SNAPSHOT_TAG', 'default_snapshot_name')

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
                        'Value': snapshot_tag
                    }
                ]
            }
        ]
    )
    
    snapshot_id = snapshot['SnapshotId']
    print(f"Created snapshot {snapshot_id} for volume {volume_id}")
    
    # Update SSM Parameter Store with the new snapshot ID
    parameter_name = '/jenkins/latest_snapshot_id'
    ssm.put_parameter(
        Name=parameter_name,
        Value=snapshot_id,
        Type='String',
        Overwrite=True
    )
    
    print(f"Updated SSM Parameter Store with snapshot ID: {snapshot_id}")
    
    return {
        'statusCode': 200,
        'body': f"Snapshot {snapshot_id} created and SSM Parameter Store updated successfully"
    }
