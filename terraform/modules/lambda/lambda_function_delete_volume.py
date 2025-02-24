import boto3
import json

ec2 = boto3.client('ec2')

def handler(event, context):
    try:
        print("Event received:", json.dumps(event, indent=4))

        # Extract snapshot ID
        snapshot_arn = event['detail']['snapshot_id']
        snapshot_id = snapshot_arn.split('/')[-1]

        # Get the snapshot details
        snapshot_response = ec2.describe_snapshots(SnapshotIds=[snapshot_id])
        print("Snapshot details:", snapshot_response)

        # Extract volume ID
        volume_arn = event['detail']['source']
        volume_id = volume_arn.split('/')[-1]

        # Get volume attachment details
        volume_response = ec2.describe_volumes(VolumeIds=[volume_id])
        attachments = volume_response["Volumes"][0].get("Attachments", [])

        if attachments:
            instance_id = attachments[0]["InstanceId"]
            print(f"Volume {volume_id} is attached to instance {instance_id}. Detaching first.")

            # Detach volume
            ec2.detach_volume(VolumeId=volume_id, InstanceId=instance_id, Force=True)

            # Wait for volume to be detached
            for _ in range(10):  # Retry for up to 50 seconds
                volume_status = ec2.describe_volumes(VolumeIds=[volume_id])
                state = volume_status["Volumes"][0]["State"]
                print(f"Current volume state: {state}")

                if state == "available":
                    print(f"Volume {volume_id} is now detached.")
                    break

                time.sleep(5)
            else:
                print(f"Timeout waiting for volume {volume_id} to detach.")
                return {
                    'statusCode': 500,
                    'body': json.dumps(f"Failed to detach volume {volume_id}")
                }

        # Now delete the volume
        delete_response = ec2.delete_volume(VolumeId=volume_id)
        print(f"Deleted Volume {volume_id}: {delete_response}")

        return {
            'statusCode': 200,
            'body': json.dumps(f"Successfully deleted volume {volume_id}")
        }

    except Exception as e:
        print("[ERROR]", str(e))
        return {
            'statusCode': 500,
            'body': json.dumps(f"Error: {str(e)}")
        }