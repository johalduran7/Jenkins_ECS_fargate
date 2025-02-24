import boto3
import os

ec2 = boto3.client('ec2')
ssm = boto3.client('ssm')

def handler(event, context):
    # Read the /jenkins/volume_id parameter
    parameter_name = '/jenkins/volume_id'
    try:
        volume_id_param = ssm.get_parameter(Name=parameter_name)['Parameter']['Value']
    except ssm.exceptions.ParameterNotFound:
        print(f"Parameter {parameter_name} not found. Exiting.")
        return {
            'statusCode': 200,
            'body': f"Parameter {parameter_name} not found. No action taken."
        }

    # If the parameter value is "null", exit
    if volume_id_param == "null":
        print(f"Parameter {parameter_name} is 'null'. No backup required.")
        return {
            'statusCode': 200,
            'body': f"Parameter {parameter_name} is 'null'. No backup required."
        }

    # Confirm that the volume ID in the parameter is the "jenkins_volume"
    try:
        volume_response = ec2.describe_volumes(VolumeIds=[volume_id_param])
        volume_tags = volume_response['Volumes'][0].get('Tags', [])
        volume_name = next((tag['Value'] for tag in volume_tags if tag['Key'] == 'Name'), None)
        
        if volume_name != "jenkins_volume":
            print(f"Volume {volume_id_param} is not 'jenkins_volume'. Exiting.")
            return {
                'statusCode': 200,
                'body': f"Volume {volume_id_param} is not 'jenkins_volume'. No action taken."
            }
    except ec2.exceptions.ClientError as e:
        print(f"Error describing volume {volume_id_param}: {e}")
        return {
            'statusCode': 500,
            'body': f"Error describing volume {volume_id_param}: {e}"
        }

    # Get the previous snapshots for the volume tagged as 'jenkins_backup'
    snapshots_response = ec2.describe_snapshots(
        Filters=[
            {'Name': 'tag:Name', 'Values': ['jenkins_backup']}
        ]
    )
    
    snapshots = snapshots_response.get('Snapshots', [])
    
    # Debug: Print the number of snapshots found
    print(f"Found {len(snapshots)} snapshots for volume {volume_id_param} with tag 'jenkins_backup'.")
    
    if snapshots:
        snapshots_sorted = sorted(snapshots, key=lambda x: x['StartTime'], reverse=True)
        
        # Debug: Print the sorted snapshots
        print("Sorted snapshots:")
        for snap in snapshots_sorted:
            print(f"Snapshot ID: {snap['SnapshotId']}, StartTime: {snap['StartTime']}")
        
        if len(snapshots_sorted) > 1:
            previous_snapshot = snapshots_sorted[1]
            print(f"Deleting previous snapshot {previous_snapshot['SnapshotId']}")
            try:
                ec2.delete_snapshot(SnapshotId=previous_snapshot['SnapshotId'])
                print(f"Successfully deleted snapshot {previous_snapshot['SnapshotId']}")
            except Exception as e:
                print(f"Error deleting snapshot {previous_snapshot['SnapshotId']}: {e}")
        else:
            print("Not enough snapshots to delete the previous one.")
    else:
        print("No snapshots found for the volume.")

    # Get snapshot tag from environment variable or default to 'jenkins_backup'
    snapshot_tag = os.environ.get('SNAPSHOT_TAG', 'jenkins_backup')

    # Create a new snapshot
    snapshot = ec2.create_snapshot(
        VolumeId=volume_id_param,
        Description=f"Snapshot of {volume_id_param} (jenkins_volume)",
        TagSpecifications=[
            {
                'ResourceType': 'snapshot',
                'Tags': [
                    {'Key': 'Name', 'Value': snapshot_tag},
                    {'Key': 'VolumeId', 'Value': volume_id_param}  # Add Volume ID Tag

                ]
            }
        ]
    )
    
    snapshot_id = snapshot['SnapshotId']
    print(f"Created snapshot {snapshot_id} for volume {volume_id_param}")

    # Update SSM Parameter Store with the new snapshot ID
    latest_snapshot_param_name = '/jenkins/latest_snapshot_id'
    ssm.put_parameter(
        Name=latest_snapshot_param_name,
        Value=snapshot_id,
        Type='String',
        Overwrite=True
    )
    
    print(f"Updated SSM Parameter Store with snapshot ID: {snapshot_id}")

    # Set the /jenkins/volume_id parameter to "null" after backup
    ssm.put_parameter(
        Name=parameter_name,
        Value="null",
        Type='String',
        Overwrite=True
    )
    
    print(f"Updated {parameter_name} to 'null' after backup.")

    return {
        'statusCode': 200,
        'body': f"Snapshot {snapshot_id} created, SSM Parameter Store updated, and {parameter_name} set to 'null'."
    }