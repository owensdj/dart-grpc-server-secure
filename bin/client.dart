import 'dart:io';
import 'dart:math';

import 'package:dbcrypt/dbcrypt.dart';
import 'package:dart_grpc_server/dart_grpc_server.dart';
import 'package:grpc/grpc.dart';

void main() {
  var client = Client();
  client.main();
}

class AuthInterceptor implements ClientInterceptor {
  @override
  ResponseStream<R> interceptStreaming<Q, R>(
      ClientMethod<Q, R> method,
      Stream<Q> requests,
      CallOptions options,
      ClientStreamingInvoker<Q, R> invoker) {
    var newOptions = options.mergedWith(
      CallOptions(metadata: <String, String>{
        'jwt': Client.jwt,
      }),
    );
    return invoker(
      method,
      requests,
      newOptions,
    );
  }

  @override
  ResponseFuture<R> interceptUnary<Q, R>(ClientMethod<Q, R> method, Q request,
      CallOptions options, ClientUnaryInvoker<Q, R> invoker) {
    var newOptions = options.mergedWith(
      CallOptions(metadata: <String, String>{
        'jwt': Client.jwt,
      }),
    );
    return invoker(
      method,
      request,
      newOptions,
    );
  }
}

class Client {
  ClientChannel? channel;
  GroceriesServiceClient? stub;
  var response;
  bool executionInProgress = true;
  bool authenticated = false;
  static String jwt = '';

  Future<void> main() async {
    final trustedRoot = File('ca-cert.pem').readAsBytesSync();
    final channelCredentials =
        ChannelCredentials.secure(certificates: trustedRoot);
    final channelOptions = ChannelOptions(credentials: channelCredentials);
    channel = ClientChannel(
      'davidcomp',
//      port: 50000,
      options: channelOptions,
    );

    stub = GroceriesServiceClient(
      channel!,
      options: CallOptions(
        timeout: Duration(seconds: 30),
      ),
      interceptors: <ClientInterceptor>[AuthInterceptor()],
    );

    while (executionInProgress) {
      try {
        print('---- Welcome to the dart store API ---');
        print('   ---- what do you want to do? ---');
        print('👉 1: View all products');
        print('👉 2: Add new product');
        print('👉 3: Edit product');
        print('👉 4: Get product');
        print('👉 5: Delete product \n');
        print('👉 6: View all categories');
        print('👉 7: Add new category');
        print('👉 8: Edit category');
        print('👉 9: Get category');
        print('👉 10: Delete category \n');
        print('👉 11: Get all products of given category');
        print('👉 12: Login');

        var option = int.parse(stdin.readLineSync()!);

        switch (option) {
          case 1:
            response = await stub!.getAllItems(Empty());
            print(' --- Store products --- ');
            response.items.forEach((item) {
              print(
                  '✅: ${item.name} (id: ${item.id} | categoryId: ${item.categoryId})');
            });
            break;
          case 2:
            print('Enter product name');
            var name = stdin.readLineSync()!;
            var item = await _findItemByName(name);
            if (item.id != 0) {
              print(
                  '🔴 product already exists: name ${item.name} | id: ${item.id} ');
            } else {
              print('Enter product\'s category name');
              var categoryName = stdin.readLineSync()!;
              var category = await _findCategoryByName(categoryName);
              if (category.id == 0) {
                print(
                    '🔴 category $categoryName does not exists, try creating it first');
              } else {
                item = Item()
                  ..name = name
                  ..id = _randomId()
                  ..categoryId = category.id;
                response = await stub!.createItem(item);
                print(
                    '✅ product created | name ${response.name} | id ${response.id} | category id ${response.categoryId}');
              }
            }

            break;

          case 3:
            print('Enter product name');
            var name = stdin.readLineSync()!;
            var item = await _findItemByName(name);
            if (item.id != 0) {
              print('Enter new product name');
              name = stdin.readLineSync()!;
              response = await stub!.editItem(
                  Item(id: item.id, name: name, categoryId: item.categoryId));
              if (response.name == name) {
                print(
                    '✅ product updated | name ${response.name} | id ${response.id}');
              } else {
                print('🔴 product update failed 🥲');
              }
            } else {
              print('🔴 product $name not found, try creating it!');
            }
            break;
          case 4:
            print('Enter product name');
            var name = stdin.readLineSync()!;
            var item = await _findItemByName(name);
            if (item.id != 0) {
              print(
                  '✅ product found | name ${item.name} | id ${item.id} | category id ${item.categoryId}');
            } else {
              print('🔴 product not found | no product matches the name $name');
            }
            break;
          case 5:
            print('Enter product name');
            var name = stdin.readLineSync()!;
            var item = await _findItemByName(name);
            if (item.id != 0) {
              await stub!.deleteItem(item);
              print('✅ item deleted');
            } else {
              print('🔴 product $name does not exist ');
            }

            break;
          case 6:
            response = await stub!.getAllCategories(Empty());
            print(' --- Store product categories --- ');
            response.categories.forEach((category) {
              print('👉: ${category.name} (id: ${category.id})');
            });

            break;
          case 7:
            print('Enter category name');
            var name = stdin.readLineSync()!;
            var category = await _findCategoryByName(name);
            if (category.id != 0) {
              print(
                  '🔴 category already exists: category ${category.name} (id: ${category.id})');
            } else {
              category = Category()
                ..id = Random(999).nextInt(9999)
                ..name = name;
              response = await stub!.createCategory(category);
              print(
                  '✅ category created: name ${category.name} (id: ${category.id})');
            }
            break;
          case 8:
            print('Enter category name');
            var name = stdin.readLineSync()!;
            var category = await _findCategoryByName(name);
            if (category.id != 0) {
              print('Enter new category name');
              name = stdin.readLineSync()!;
              response = await stub!
                  .editCategory(Category(id: category.id, name: name));
              if (response.name == name) {
                print(
                    '✅ category updated | name ${response.name} | id ${response.id}');
              } else {
                print('🔴 category update failed 🥲');
              }
            } else {
              print('🔴 category $name not found, try creating it!');
            }

            break;
          case 9:
            print('Enter category name');
            var name = stdin.readLineSync()!;
            var category = await _findCategoryByName(name);
            if (category.id != 0) {
              print(
                  '✅ category found | name ${category.name} | id ${category.id}');
            } else {
              print(
                  '🔴 category not found | no category matches the name $name');
            }

            break;
          case 10:
            print('Enter category name');
            var name = stdin.readLineSync()!;
            var category = await _findCategoryByName(name);
            if (category.id != 0) {
              await stub!.deleteCategory(category);
              print('✅ category deleted');
            } else {
              print('🔴 category $name not found ');
            }
            break;
          case 11:
            print('Enter category name');
            var name = stdin.readLineSync()!;
            var category = await _findCategoryByName(name);
            if (category.id != 0) {
              var _result = await stub!.getItemsByCategory(category);
              print('--- all products of the $name category --- ');

              _result.items.forEach((item) {
                print('👉 ${item.name}');
              });
            } else {
              print('🔴 category $name not found');
            }

            break;
          case 12:
            print('Enter your user name:');
            var userName = stdin.readLineSync()!;
            print('Enter your password:');
            var password = stdin.readLineSync()!;
            var hashedPassword =
                DBCrypt().hashpw(password, DBCrypt().gensalt());
            var userLogin = UserLogin()
              ..userName = userName
              ..hashedPassword = hashedPassword;
            var response = await stub!.authenticate(userLogin);
            if (response.authenticated) {
              jwt = response.jwtData;
              authenticated = true;
              print('Logged into the server.');
            } else {
              jwt = '';
              authenticated = false;
              print('User name or password incorrect.');
            }
            break;
          default:
            print('invalid option 🥲');
        }
      } catch (e) {
        print(e);
      }
      print('Do you wish to exit the store? (Y/n)');
      var result = stdin.readLineSync() ?? 'y';
      executionInProgress = result.toLowerCase() != 'y';
    }

    await channel!.shutdown();
  }

  Future<Category> _findCategoryByName(String name) async {
    var category = Category()..name = name;
    category = await stub!.getCategory(category);
    return category;
  }

  Future<Item> _findItemByName(String name) async {
    var item = Item()..name = name;
    item = await stub!.getItem(item);
    return item;
  }

  int _randomId() => Random(1000).nextInt(9999);
}
