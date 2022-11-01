def lambda_handler(event, context):

    fragment = event['fragment']
    event_type = event['params']['FleetType']
    team_size = int(event['params']['InputSize'])

    print(fragment)

    if event_type == 'task':
        if fragment['Properties']['TargetOnDemandCapacity'] == 'custom::Target':
            fragment['Properties']['TargetOnDemandCapacity'] = team_size
        elif fragment['Properties']['TargetSpotCapacity'] == 'custom::Target':
            fragment['Properties']['TargetSpotCapacity'] = team_size

    print(fragment)

    return {
        'requestId': event['requestId'],
        'status': 'success',
        'statusCode': 200,
        'fragment': fragment
    }