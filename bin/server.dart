import 'dart:async';
import 'dart:io';

import 'package:dart_grpc_server/dart_grpc_server.dart';
import 'package:grpc/grpc.dart';
import 'package:jaguar_jwt/jaguar_jwt.dart';

Future<void> main(List<String> args) async {
  FutureOr<GrpcError?> authInterceptor(ServiceCall call, ServiceMethod method) {
    if (call.clientMetadata?[':path'] == null) {
      return GrpcError.unauthenticated();
    }
    if (call.clientMetadata![':path']!.contains('authenticate')) {
      return null; // allow all authenticate RPC calls
    }
    try {
      final jwt = call.clientMetadata!['jwt'];
      if (jwt == null) {
        return GrpcError.unauthenticated();
      }
      final claimSet = verifyJwtHS256Signature(
        jwt,
        GroceriesService.secretJwtKey,
      );
      if (claimSet.subject?.isEmpty ?? true) {
        return GrpcError.unauthenticated();
      }
    } on JwtException {
      return GrpcError.unauthenticated();
    }

    return null; // authenticated
  }

  final serverPrivateKey = File('server-key.pem').readAsBytesSync();
  final serverCertificate = File('server-cert.pem').readAsBytesSync();
  final server = Server(
    [GroceriesService()],
    <Interceptor>[
      authInterceptor,
    ],
    CodecRegistry(codecs: const [GzipCodec(), IdentityCodec()]),
  );
  await server.serve(
//    port: 50000,
    security: ServerTlsCredentials(
      certificate: serverCertificate,
      privateKey: serverPrivateKey,
    ),
  );
  print('✅ Server listening on port ${server.port}...');
}

class GroceriesService extends GroceriesServiceBase {
  static const secretJwtKey = 'kjd4r7Ntka@mqwdf2!db';

  @override
  Future<AuthResponse> authenticate(
      ServiceCall call, UserLogin userLogin) async {
    // Would verify the user name and hash pw in DB in production
    final claimSet = JwtClaim(subject: userLogin.userName);
    final jwt = issueJwtHS256(claimSet, secretJwtKey);
    return AuthResponse(
      authenticated: true,
      jwtData: jwt,
    );
  }

  @override
  Future<Category> createCategory(ServiceCall call, Category request) async =>
      categoriesServices.createCategory(request)!;

  @override
  Future<Item> createItem(ServiceCall call, Item request) async =>
      itemsServices.createItem(request)!;

  @override
  Future<Empty> deleteCategory(ServiceCall call, Category request) async =>
      categoriesServices.deleteCategory(request)!;

  @override
  Future<Empty> deleteItem(ServiceCall call, Item request) async =>
      itemsServices.deleteItem(request)!;

  @override
  Future<Category> editCategory(ServiceCall call, Category request) async =>
      categoriesServices.editCategory(request)!;

  @override
  Future<Item> editItem(ServiceCall call, Item request) async =>
      itemsServices.editItem(request)!;

  @override
  Future<Categories> getAllCategories(ServiceCall call, Empty request) async =>
      Categories()..categories.addAll(categoriesServices.getCategories()!);

  @override
  Future<Items> getAllItems(ServiceCall call, Empty request) async =>
      Items()..items.addAll(itemsServices.getItems()!);

  @override
  Future<Category> getCategory(ServiceCall call, Category request) async =>
      categoriesServices.getCategoryByName(request.name)!;

  @override
  Future<Item> getItem(ServiceCall call, Item request) async =>
      itemsServices.getItemByName(request.name)!;

  @override
  Future<AllItemsOfCategory> getItemsByCategory(
          ServiceCall call, Category request) async =>
      AllItemsOfCategory(
          items: itemsServices.getItemsByCategory(request.id)!,
          categoryId: request.id);
}
