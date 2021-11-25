# Dart gRPC server

This project is an introductions to gRPC using the dart language, on the project you are going to build a groceries store API using dart, we will build the server and the corresponding client

Here are the openssl commands to generate the self-signed root CA certificate and server certificate.  Server needs server-cert.pem and server-key.pem files.  Client needs the self-signed root ca-cert.pem file.

1. Generate CA's private key and self-signed certificate
openssl req -x509 -newkey rsa:4096 -days 3650 -nodes -keyout ca-key.pem -out ca-cert.pem

2. Generate server's private key and certificate signing request (CSR)
openssl req -newkey rsa:4096 -nodes -keyout server-key.pem -out server-req.pem

3. Use CA's private key to sign server's CSR and get back the signed certificate
openssl x509 -req -in server-req.pem -days 3650 -CA ca-cert.pem -CAkey ca-key.pem -CAcreateserial -out server-cert.pem
