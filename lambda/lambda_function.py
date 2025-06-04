import json
def lambda_handler(event, context):
    '''This is lambda handler accepts 
    "event -> trigger, context -> lambda runtime context'''
    print('event', event)
    return {
        'statusCode': 200,
        'body': json.dumps('Hello from lambda')
    }