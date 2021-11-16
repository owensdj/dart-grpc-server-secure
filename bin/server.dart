import 'dart:io';

import 'package:dart_grpc_server/dart_grpc_server.dart';
import 'package:jaguar_jwt/jaguar_jwt.dart';
import 'package:grpc/grpc.dart';

Future<void> main(List<String> args) async {
  GrpcError? authInterceptor(ServiceCall call, ServiceMethod method) {
    return null;
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

  @override
  Future<AuthResponse> authenticate(
      ServiceCall call, UserLogin userLogin) async {
    final claimSet = JwtClaim(subject: userLogin.userName);
    final jwt = issueJwtHS256(claimSet, secretJwtKey);
    return AuthResponse(
      authenticated: true,
      jwtData: jwt,
    );
  }
}
