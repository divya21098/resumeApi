import json
import boto3
from boto3.dynamodb.conditions import Key, Attr

# import requests
# s3_client = boto3.client('s3')

# BUCKET_NAME = 'serverless-resume-bucket'
# RESUME_FILE_KEY = 'resume.json'

dynamodb = boto3.resource('dynamodb', region_name='us-west-1')
table = dynamodb.Table('Movies-API')

logger = logging.getLogger()
logger.setLevel(logging.INFO)
def lambda_handler(event, context):
    logger.info("Received event: %s", json.dumps(event))
    
    try:
        if 'requestContext' not in event:
            raise KeyError('requestContext')

        # Handling HTTP API format
        if 'http' in event['requestContext']:
            path = event['rawPath']
            method = event['requestContext']['http']['method']
        # Handling REST API format
        else:
            path = event['path']
            method = event['httpMethod']
        
    except KeyError as e:
        logger.error("KeyError: %s", str(e))
        return {
            'statusCode': 400,
            'body': json.dumps(f'Bad Request: Missing key in event: {str(e)}')
        }
    
    if path == '/get_movies' and method == 'GET':
        return get_movies()
    elif path == '/getmoviesbyyear' and method == 'GET':
        query_params = event.get('queryStringParameters', {})
        year = query_params.get('year')
        if year:
            return get_movies_by_year(year)
        else:
            return {
                'statusCode': 400,
                'body': json.dumps('Bad Request: Missing query parameter "year"')
            }
    else:
        return {
            'statusCode': 404,
            'body': 'Not Found'
        }


def get_movies():
    try:
        response = table.scan()
        movies = response.get('Items', [])
        # Convert Decimal to int for JSON serialization
        for movie in movies:
            movie['year'] = int(movie['year'])
        return {
            'statusCode': 200,
            'body': json.dumps(movies)
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': f'Error Fetching Movies: {str(e)}'
        }


def get_movies_by_year(year):
    try:
        response = table.scan(FilterExpression=Attr('year').eq(int(year)))
        movies = response.get('Items', [])
        # Convert Decimal to int for JSON serialization
        for movie in movies:
            movie['year'] = int(movie['year'])
        return {
            'statusCode': 200,
            'body': json.dumps(movies)
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': f'Error getting movies for the year {year}: {str(e)}'
        }
# def get_movies():
#     try:
#         with open('resume.json') as f:
#             response = json.load(f)
        
#         return response
#     except FileNotFoundError:
#         print("Error: 'resume.json' file not found.")
#         return []
#     except json.JSONDecodeError:
#         print("Error: Malformed JSON in 'resume.json'.")
#         return []

# def get_movies_by_year(yr, movies):
#     movie_by_year=[]
#     for i in movies:
#         if i.get('Year')==str(yr):
#             movie_by_year.append(i)
#     return movie_by_year

# def get_movies_by_dir(dir, movies):
#     movie_by_dir=[]
#     for i in movies:
#         if i.get('Year').contains(dir):
#             movie_by_dir.append(i)
#     return movie_by_dir

# def main():
#     print("in main")
#     movies = get_movies()  # Load movies
#     if movies:  # Proceed only if movies are successfully loaded
#         movie_by_year = get_movies_by_year(2016, movies)
#         movies_by_dir =get_movies_by_dir("Joyce",movies)
#     print(movie_by_year)
# if __name__ == "__main__":
#     main()

# def lambda_handler(event, context):
#     try
#          response = s3_client.get_object(Bucket=BUCKET_NAME, Key=RESUME_FILE_KEY)
#          resume_data = json.loads(response['Body'].read().decode('utf-8'))
        
#         return {
#             'statusCode': 200,
#             'body': json.dumps(response),
#             'headers': {
#                 'Content-Type': 'application/json'
#             }
#         }
        
#     except Exception as e:
#         return {
#             'statusCode': 500,
#             'body': str(e)
#         }
