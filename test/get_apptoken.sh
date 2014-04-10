# import base64
#  client.clientid = '0a0c9b87622def4da5801edd7e013b4d'
#  client.secret = 'd1572d8cd46913630dfc56f481db818b'
# or
#  client.clientid = 'e3a5cde0f20a94559691364eb5fb8bff'
#  client.secret =  '116dd4b3a92a17453df0a5ae83e5e640'
# base64.b64encode('0a0c9b87622def4da5801edd7e013b4d:d1572d8cd46913630dfc56f481db818b')
curl "http://localhost:9292/token" \
-H "Authorization: Basic MGEwYzliODc2MjJkZWY0ZGE1ODAxZWRkN2UwMTNiNGQ6ZDE1NzJkOGNkNDY5MTM2MzBkZmM1NmY0ODFkYjgxOGI=" \
--data "grant_type=password&username=user1@chikaku.com&password=mago" 
