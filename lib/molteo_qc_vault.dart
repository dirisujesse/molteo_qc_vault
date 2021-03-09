import 'package:dio/dio.dart';

class Combination {
  int first;
  int second;
  int third;

  Combination({this.first, this.second, this.third});

  Map<String, int> get json {
    return {
      'first': first,
      'second': second,
      'third': third,
    };
  }
}

final _http = Dio(
  BaseOptions(
    baseUrl: 'https://qcvault.herokuapp.com',
    connectTimeout: 1000 * 30,
    receiveTimeout: 1000 * 30,
  ),
)..interceptors.add(
    InterceptorsWrapper(onRequest: (RequestOptions opts) async {
      print({
        'url': '${opts?.baseUrl}${opts?.path}',
        'body': opts?.data,
        'params': opts?.queryParameters,
        'header': opts?.headers
      });
      return opts;
    }, onError: (DioError e) async {
      print({
        'statusCode': e?.response?.statusCode ?? 400,
        'statusMessage': e?.response?.statusMessage,
        'data': e?.response?.data ?? {'message': e?.error ?? e}
      });
      return e;
    }, onResponse: (Response res) {
      print({
        'data': res?.data,
        'statusCode': res?.statusCode,
        'statusMessage': res?.statusMessage,
      });
      return res;
    }),
  );

List<Future<Response>> _permutations() {
  final List list = List<int>.generate(10, (index) => index);
  var combos = <Future<Response>>[];

  for (final i in list) {
    for (final j in list) {
      for (final k in list) {
        combos.add(
          _http.post(
            '/unlock_safe',
            data: Combination(
              first: i,
              second: j,
              third: k,
            ).json,
          ),
        );
      }
    }
  }

  return combos;
}

String _extractCode(Response response) {
  return Map.from(response?.request?.data).values.join('');
}

void unlockVault() async {
  final permutations = _permutations();
  try {
    final responses = await Future.wait(permutations);
    final correctResponse = responses
        .firstWhere((it) => it?.data != 'Wrong code', orElse: () => null);
    if (correctResponse != null) {
      print(
        'The correct code is: ${_extractCode(correctResponse)}, The vault value is: ${correctResponse?.data}',
      );
    }
  } catch (e) {
    print(e);
  }
}
