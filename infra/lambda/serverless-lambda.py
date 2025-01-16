import json
import boto3
# import requests
# s3_client = boto3.client('s3')

BUCKET_NAME = 'serverless-resume-bucket'
RESUME_FILE_KEY = 'resume.json'

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
def get_movies():
    """
    Fetch and parse the JSON file from S3.
    """
    try:
        response = s3.get_object(Bucket=BUCKET_NAME, Key=FILE_KEY)
        content = response['Body'].read().decode('utf-8')
        movies = json.loads(content)
        return movies
    except s3.exceptions.NoSuchKey:
        return {"error": f"File '{FILE_KEY}' not found in bucket '{BUCKET_NAME}'"}
    except json.JSONDecodeError:
        return {"error": f"Malformed JSON in file '{FILE_KEY}'"}
    except Exception as e:
        return {"error": str(e)}

def get_movies_by_year(yr, movies):
    """
    Filter movies by the given year.
    """
    return [movie for movie in movies if movie.get('Year') == yr]

def lambda_handler(event, context):

    try:
        # Get the year from the event query parameters
        year = event.get('queryStringParameters', {}).get('Year')
        if not year:
            return {
                "statusCode": 400,
                "body": json.dumps({"error": "Year parameter is required"})
            }

        # Convert year to integer
        year = str(year)

        # Fetch movies
        movies = get_movies()

        # If there's an error in fetching movies, return it
        if isinstance(movies, dict) and "error" in movies:
            return {
                "statusCode": 500,
                "body": json.dumps(movies)
            }

        # Get movies by year
        movies_by_year = get_movies_by_year(year, movies)

        # Return results
        return {
            "statusCode": 200,
            "body": json.dumps({"movies": movies_by_year})
        }

    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }

# def lambda_handler(event, context):
#     try:
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
