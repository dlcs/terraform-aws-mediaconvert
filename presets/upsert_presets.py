import json
from pathlib import Path
import boto3
from botocore.exceptions import ClientError

client = boto3.client('mediaconvert')
template_dir = Path('./templates')

def does_preset_exist(preset_name: str):
    try:
        client.get_preset(Name=preset_name)
        return True
    except ClientError:
        return False
    
if __name__ == '__main__':
    for preset in [p for p in template_dir.glob('*.json') if p.is_file()]:
        with open(preset) as file:
            template = json.load(file)
            preset_name = template.get('Name', '')            
            
            if does_preset_exist(preset_name):
                print(f'updating {preset_name}')
                client.update_preset(**template)
            else:
                print(f'creating {preset_name}')
                client.create_preset(**template)