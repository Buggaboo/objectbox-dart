part of query;

class _PropertyQuery {
  Pointer<Void> _cProp;
  int _type;
  bool _distinct;

  _PropertyQuery(Pointer<Void> cQuery, int propertyId, int obxType) {
    this._type = obxType;
    _cProp = checkObxPtr(bindings.obx_query_prop(cQuery, propertyId), "property query");
  }

  void close() {
    checkObx(bindings.obx_query_prop_close(_cProp));
  }

  get distinct => _distinct;

  set distinct (bool d) {
    _distinct = d;
    checkObx(bindings.obx_query_prop_distinct(_cProp, d ? 1 : 0));
  }

  int count() {
    final ptr = Pointer<Uint64>.allocate();
    checkObx(bindings.obx_query_prop_count(_cProp, ptr));
    try {
      return ptr.load<int>();
    }finally {
      ptr.free();
    }
  }

  Pointer<TStruct> _curryWithDefault<TStruct extends Struct, N extends NativeType>
      (obx_query_prop_find_t<TStruct, N> findFn, Pointer<N> cDefault, String errorMessage) {
    try {
      return checkObxPtr(findFn(_cProp, cDefault), errorMessage);
    }finally {
      cDefault.free();
    }
  }
}

/// shared implementation, hence mixin
mixin _CommonNumeric on _PropertyQuery {

  double average() {
    final ptr = Pointer<Double>.allocate();
    checkObx(bindings.obx_query_prop_avg(_cProp, ptr));
    try {
      return ptr.load<double>();
    }finally {
      ptr.free();
    }
  }

}

class IntegerPropertyQuery extends _PropertyQuery with _CommonNumeric {

  IntegerPropertyQuery (Pointer<Void> query, int propertyId, int obxType): super(query, propertyId, obxType);

  int _op(obx_query_prop_op_t<int, Int64> fn) {
    final ptr = Pointer<Int64>.allocate();
    checkObx(fn(_cProp, ptr));
    try {
      return ptr.load<int>();
    }finally {
      ptr.free();
    }
  }

  int min() {
    return _op(bindings.obx_query_prop_min_int);
  }
  int max() {
    return _op(bindings.obx_query_prop_max_int);
  }
  int sum() {
    return _op(bindings.obx_query_prop_sum_int);
  }

  List<int> _unpack8(Pointer<OBX_int8_array> ptr) {
    try {
      return ptr.load().items();
    } finally {
      bindings.obx_int8_array_free(ptr.cast<Uint64>());
    }
  }

  List<int> _unpack16(Pointer<OBX_int16_array> ptr) {
    try {
      return ptr.load().items();
    } finally {
      bindings.obx_int16_array_free(ptr.cast<Uint64>());
    }
  }

  List<int> _unpack32(Pointer<OBX_int32_array> ptr) {
    try {
      return ptr.load().items();
    } finally {
      bindings.obx_int32_array_free(ptr.cast<Uint64>());
    }
  }

  List<int> _unpack64(Pointer<OBX_int64_array> ptr) {
    try {
      return ptr.load().items();
    }finally {
      bindings.obx_int64_array_free(ptr.cast<Uint64>());
    }
  }

  List<int> find({int defaultValue}) {
    switch(_type) {
      case OBXPropertyType.Bool:
      case OBXPropertyType.Byte:
      case OBXPropertyType.Char:  // Int8
        return _unpack8(_curryWithDefault<OBX_int8_array, Int8>
          (bindings.obx_query_prop_int8_find, Pointer<Int8>.allocate()..store(defaultValue), "find int8"));
      case OBXPropertyType.Short: // Int16
        return _unpack16(_curryWithDefault<OBX_int16_array, Int16>
          (bindings.obx_query_prop_int16_find, Pointer<Int16>.allocate()..store(defaultValue), "find int16"));
      case OBXPropertyType.Int:   // Int32
        return _unpack32(_curryWithDefault<OBX_int32_array, Int32>
          (bindings.obx_query_prop_int32_find, Pointer<Int32>.allocate()..store(defaultValue), "find int32"));
      case OBXPropertyType.Long:  // Int64
        return _unpack64(_curryWithDefault<OBX_int64_array, Int64>
          (bindings.obx_query_prop_int64_find, Pointer<Int64>.allocate()..store(defaultValue), "find int64"));
    }
  }
}

class DoublePropertyQuery extends _PropertyQuery with _CommonNumeric {

  DoublePropertyQuery (Pointer<Void> query, int propertyId, int obxType): super(query, propertyId, obxType);

  double _op(obx_query_prop_op_t<int, Double> fn) {
    final ptr = Pointer<Double>.allocate();
    checkObx(fn(_cProp, ptr));
    try {
      return ptr.load();
    }finally {
      ptr.free();
    }
  }

  double min() {
    return _op(bindings.obx_query_prop_min);
  }
  double max() {
    return _op(bindings.obx_query_prop_max);
  }
  double sum() {
    return _op(bindings.obx_query_prop_sum);
  }

  List<double> _unpack32(Pointer<OBX_float_array> ptr) {
    try {
      return ptr.load().items();
    }finally {
      bindings.obx_float_array_free(ptr.cast<Uint64>());
    }
  }

  List<double> _unpack64(Pointer<OBX_double_array> ptr) {
    try {
      return ptr.load().items();
    }finally {
      bindings.obx_double_array_free(ptr.cast<Uint64>());
    }
  }

  List<double> find({double defaultValue=0}) {
    switch(_type) {
      case OBXPropertyType.Float:
        return _unpack32(_curryWithDefault<OBX_float_array, Float>
          (bindings.obx_query_prop_float_find, Pointer<Float>.allocate()..store(defaultValue), "find float32"));
      case OBXPropertyType.Double:
        return _unpack64(_curryWithDefault<OBX_double_array, Double>
          (bindings.obx_query_prop_double_find, Pointer<Double>.allocate()..store(defaultValue), "find float64"));
    }
  }

}

class StringPropertyQuery extends _PropertyQuery {

  StringPropertyQuery (Pointer<Void> query, int propertyId, int obxType): super(query, propertyId, obxType);

  // distinct is already taken in the base type (can't overload with two params)
  // you could use that one instead
  void caseSensitive(bool caseSensitive) {
    checkObx(bindings.obx_query_prop_distinct_string(_cProp, _distinct ? 1 : 0
        , caseSensitive ? 1 : 0));
  }

  List<String> _unpack(Pointer<OBX_string_array> ptr) {
    try {
      return ptr.load().items();
    }finally {
      bindings.obx_string_array_free(ptr.cast<Uint64>());
    }
  }

  List<String> find({String defaultValue}) {
    Pointer<Int8> int8Ptr;
    if (defaultValue != null) {
      int8Ptr = Utf8.toUtf8(defaultValue).cast<Int8>();
    }else {
      int8Ptr = Pointer<Int8>.allocate()..store(0); // TODO confirm this is how you do nil
    }
    return _unpack(_curryWithDefault<OBX_string_array, Int8>
      (bindings.obx_query_prop_string_find, int8Ptr, "find utf8"));
  }
}

