import boto3

ec2 = boto3.client('ec2')

def handler(event, context):
    print("Event received:", event)

    # Extract Snapshot ID
    snapshot_id = event['detail']['snapshot_id']
    
    # Get snapshot details to find the associated volume ID
    snapshot_response = ec2.describe_snapshots(SnapshotIds=[snapshot_id])
    snapshot_tags = snapshot_response['Snapshots'][0].get('Tags', [])

    # Extract Volume ID from tags
    volume_id = next((tag['Value'] for tag in snapshot_tags if tag['Key'] == 'VolumeId'), None)

    if not volume_id:
        print(f"No volume ID found for snapshot {snapshot_id}. Exiting.")
        return

    print(f"Deleting volume {volume_id} as snapshot {snapshot_id} is completed.")
    
    # Delete the volume
    ec2.delete_volume(VolumeId=volume_id)

    return {
        'statusCode': 200,
        'body': f"Deleted volume {volume_id} after snapshot {snapshot_id} was created."
    }
