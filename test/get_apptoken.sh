# import base64
# base64.b64encode('e3a5cde0f20a94559691364eb5fb8bff:116dd4b3a92a17453df0a5ae83e5e640')
curl "http://localhost:9292/token" \
-H "Authorization: Basic ZTNhNWNkZTBmMjBhOTQ1NTk2OTEzNjRlYjVmYjhiZmY6MTE2ZGQ0YjNhOTJhMTc0NTNkZjBhNWFlODNlNWU2NDA=" \
--data "grant_type=password&username=test01@chikaku.com&password=dx7PnxqDZ5kr" 
