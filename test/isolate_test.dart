import 'dart:io'; // for exit();
import 'dart:async';
import 'dart:isolate';

import "package:test/test.dart";
import "entity.dart";
import 'test_env.dart';
import 'objectbox.g.dart';

// borrowed from @lmzach https://git.io/Jf2Kr

void printStuff(String fromWhom, TestEntity e) async {
  print('$fromWhom ${e.tString}');
}

/// Spawn isolate and its ReceiveSendPort
Future<SendPort> initIsolate() async {
  Completer completer = new Completer<SendPort>();
  ReceivePort isolateToMainStream = ReceivePort();

  isolateToMainStream.listen((data) {
    if (data is SendPort) {
      SendPort mainToIsolateStream = data;
      completer.complete(mainToIsolateStream);
    } else {
      TestEntity e = data as TestEntity;
      printStuff('[isolateToMainStream] ', e);
    }
  });

  Isolate myIsolateInstance = await Isolate.spawn(myIsolate, isolateToMainStream.sendPort);
  return completer.future;
}

/// Define isolate's behaviour
void myIsolate(SendPort isolateToMainStream) async {
  ReceivePort mainToIsolateStream = ReceivePort();
  isolateToMainStream.send(mainToIsolateStream.sendPort);

  mainToIsolateStream.listen((data) {
    TestEntity e = data as TestEntity;
    printStuff('[mainToIsolateStream] ', e);
  });

  TestEnv env = TestEnv("isolate");
  Box box = env.box;

  final id = box.put(TestEntity(tString: "Goodbye, cruel world!"));
  final entity = box.get(id);

  isolateToMainStream.send(entity);
}

void main() async {

  TestEnv env;
  Box box;

  env = TestEnv("isolate");
  box = env.box;

/// 00:01 +0 -1: Pass box to isolate [E]
///  Invalid argument(s): Native objects (from dart:ffi) such as Pointers and Structs cannot be passed between isolates.
//  test("Pass box to isolate", () async {
//    SendPort mainToIsolateStream = await initIsolate();
//    mainToIsolateStream.send(box);
//  });

  test("Pass object to isolate, and vice versa", () {
    /// intentionally empty
    /// test framework won't run without tests
    /// also, the test end before the isolates
    /// pass anything at all
  });

  final id = box.put(TestEntity(tString: "Hello world!"));
  final entity = box.get(id);

  SendPort mainToIsolateStream = await initIsolate();
  mainToIsolateStream.send(entity);

  env.close();
}