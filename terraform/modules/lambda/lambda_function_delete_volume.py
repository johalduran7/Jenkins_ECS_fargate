import json
import boto3

ec2_client = boto3.client("ec2")

def handler(event, context):
    print("Received event:", json.dumps(event, indent=2))
    
    # Extract instance ID
    instance_id = event.get("detail", {}).get("instance-id")
    if not instance_id:
        print("No instance ID found in the event.")
        return {"status": "No instance ID found"}
    
    # Get instance details
    try:
        response = ec2_client.describe_instances(InstanceIds=[instance_id])
        tags = response["Reservations"][0]["Instances"][0].get("Tags", [])
    except Exception as e:
        print(f"Error retrieving instance details: {e}")
        return {"status": "Error retrieving instance details"}
    
    # Find Volume_id tag
    volume_id = None
    for tag in tags:
        if tag["Key"] == "Volume_id":
            volume_id = tag["Value"]
            break
    
    if not volume_id:
        print(f"Instance {instance_id} does not have a Volume_id tag.")
        return {"status": "No Volume_id tag found"}
    
    # Delete the volume
    try:
        ec2_client.delete_volume(VolumeId=volume_id)
        print(f"Successfully deleted volume {volume_id} associated with instance {instance_id}.")
        return {"status": "Volume deleted", "volume_id": volume_id}
    except Exception as e:
        print(f"Error deleting volume {volume_id}: {e}")
        return {"status": "Error deleting volume", "error": str(e)}
