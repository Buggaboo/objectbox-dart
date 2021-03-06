import 'dart:ffi';
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:ffi/ffi.dart' as f;

import '../../flatbuffers/flat_buffers.dart' as fb;

// ignore_for_file: public_member_api_docs

class BuilderWithCBuffer {
  final _allocator = _Allocator();
  final int _initialSize;
  final int _resetIfLargerThan;

  /*late final*/
  fb.Builder _fbb;

  fb.Builder get fbb => _fbb;

  Pointer<Uint8> get bufPtr => Pointer<Uint8>.fromAddress(
      _allocator.bufPtr.address + _allocator._capacity - _fbb.size);

  BuilderWithCBuffer({int initialSize = 256, int resetIfLargerThan = 64 * 1024})
      : _initialSize = initialSize,
        _resetIfLargerThan = resetIfLargerThan {
    _fbb = fb.Builder(initialSize: initialSize, allocator: _allocator);
  }

  void resetIfLarge() {
    if (_allocator._capacity > _resetIfLargerThan) {
      clear();
      _fbb = fb.Builder(initialSize: _initialSize, allocator: _allocator);
    }
  }

  void clear() {
    if (_allocator._allocs.isEmpty) return;
    if (_allocator._allocs.length == 1) {
      // This is the most common case so no need to create an intermediary list.
      _allocator.deallocate(_allocator._allocs.keys.first);
    } else {
      _allocator._allocs.keys
          .toList(growable: false)
          .forEach(_allocator.deallocate);
    }
  }
}

// FFI signature
typedef _dart_memset = void Function(Pointer<Void>, int, int);

_dart_memset _memset;

class _Allocator extends fb.Allocator {
  // we may have multiple allocations at once (e.g. during [reallocate()])
  final _allocs = <ByteData, Pointer<Uint8>>{};
  int _capacity = 0;

  Pointer<Uint8> get bufPtr {
    if (_allocs.length != 1) {
      throw Exception(
          'invalid number of current allocations: ${_allocs.length}');
    }

    return _allocs.values.first;
  }

  @override
  ByteData allocate(int size) {
    _capacity = size;
    final ptr = f.allocate<Uint8>(count: size);
    final data = ByteData.view(ptr.asTypedList(size).buffer);
    _allocs[data] = ptr;
    return data;
  }

  @override
  void deallocate(ByteData data) {
    f.free(_allocs[data]);
    _allocs.remove(data);
  }

  @override
  void clear(ByteData data, bool _) {
    if (_memset == null) {
      try {
        DynamicLibrary lib;
        if (Platform.isWindows) {
          // DynamicLibrary.process() is not available on Windows, let's load a
          // lib that defines 'memset()' it - should be mscvr100 or mscvrt DLL.
          // mscvr100.dll is in the frequently installed MSVC Redistributable.
          lib = DynamicLibrary.open('msvcr100.dll');
        } else {
          lib = DynamicLibrary.process();
        }
        _memset = lib.lookupFunction<
            Void Function(Pointer<Void>, Int32, IntPtr),
            _dart_memset>('memset');
      } catch (_) {
        // fall back if we can't load a native memset()
        _memset = (Pointer<Void> ptr, int byte, int size) {
          final bytes = ptr.cast<Uint8>();
          for (var i = 0; i < size; i++) {
            bytes[i] = byte;
          }
        };
      }
    }
    _memset(_allocs[data].cast<Void>(), 0, data.lengthInBytes);
  }
}
