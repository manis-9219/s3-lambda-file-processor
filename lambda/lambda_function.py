import json
def lambda_handler(event, context):
    '''This is lambda handler accepts 
    "event -> trigger, context -> lambda runtime context'''
    print('key', event['Records'][0]['s3']['object']['key'])
    print('size in MB', event['Records'][0]['s3']['object']['size']/(1024*1024))
    return {
        'statusCode': 200,
        'body': json.dumps('Hello from lambda')
    }