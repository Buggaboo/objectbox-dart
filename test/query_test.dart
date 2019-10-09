import "package:test/test.dart";
import "package:objectbox/objectbox.dart";
import "entity.dart";
import "util.dart";

void main() {
  Store store;
  Box box;

  group("query", () {
    setUp(() {
      store = Store([TestEntity_OBXDefs]);
      box = Box<TestEntity>(store);
    });

    test(".null and .notNull", () {
      box.putMany([
        TestEntity.initDoubleAndBoolean(0.1, true),
        TestEntity.initDoubleAndBoolean(0.3, false),
        TestEntity.initText("one"),
        TestEntity.initText("two"),
      ] as List<TestEntity>);

      final d = TestEntity_.d;
      final b = TestEntity_.b;
      final t = TestEntity_.text;

      final qbNull    = box.query(b.isNull()).build();
      final qbNotNull = box.query(b.notNull()).build();
      final qtNull    = box.query(t.isNull()).build();
      final qtNotNull = box.query(t.notNull()).build();
      final qdNull    = box.query(t.isNull()).build();
      final qdNotNull = box.query(t.notNull()).build();

      [ qbNull, qbNotNull, qtNull, qtNotNull, qdNull, qdNotNull ]
        .forEach((q) {
          expect(q.count(), 2);
          q.close();
        });
    });

    test(".count doubles and booleans", () {
      box.putMany([
        TestEntity.initDoubleAndBoolean(0.1, true),
        TestEntity.initDoubleAndBoolean(0.3, false),
        TestEntity.initDoubleAndBoolean(0.5, true),
        TestEntity.initDoubleAndBoolean(0.7, false),
        TestEntity.initDoubleAndBoolean(0.9, true)
      ] as List<TestEntity>);

      final d = TestEntity_.d;
      final b = TestEntity_.b;

      final anyQuery0 = ((d == 0.8) & (b == false)) | ((d == 0.7) & (b == false));

      final allQuery0 = (d == 0.1) & (b == true);

      final q0    = box.query(b.equals(false)).build();
      final qany0 = box.query(anyQuery0 as QueryCondition).build();
      final qall0 = box.query(allQuery0 as QueryCondition).build();

      expect(q0.count(), 2);
      expect(qany0.count(), 3);
      expect(qall0.count(), 1);

      [ q0, qany0, qall0 ].forEach((q) => q.close());
    });

    test(".count matches of `greater` and `less`", () {
      box.putMany([
        TestEntity.initIntegerAndText(1336, "mord"),
        TestEntity.initIntegerAndText(1337, "more"),
        TestEntity.initIntegerAndText(1338, "morf"),
        TestEntity.initDoubleAndBoolean(0.0, false),
        TestEntity.initDoubleAndBoolean(0.1, true),
        TestEntity.initDoubleAndBoolean(0.2, true),
        TestEntity.initDoubleAndBoolean(0.3, false),
      ]);

      final d = TestEntity_.d;
      final b = TestEntity_.b;
      final t = TestEntity_.text;
      final n = TestEntity_.number;

//      final q0 = box.query(d > 0.1).build();
//      final q1 = box.query(b == false).build();
//      final q2 = box.query(t > "more").build();
//      final q3 = box.query(t < "more").build();
//      final q4 = box.query(d < 0.3).build();
//      final q5 = box.query(n < 1337).build();
//      final q6 = box.query(n > 1337).build();

      final q0 = box.query(d.greaterThan(0.1)).build();
      final q1 = box.query(b.equals(false)).build();
      final q2 = box.query(t.greaterThan("more")).build();
      final q3 = box.query(t.lessThan("more")).build();
      final q4 = box.query(d.lessThan(0.3)).build();
      final q5 = box.query(n.lessThan(1337)).build();
      final q6 = box.query(n.greaterThan(1337)).build();

      expect(q0, 3);
      expect(q1, 2);
      expect(q2, 1);
      expect(q3, 1);
      expect(q4, 3);
      expect(q5, 1);
      expect(q6, 1);

      [ q0,q1,q2,q3,q4,q5,q6 ].forEach((q) => q.close());
    });

    test(".count matches of `in`, `contain`, `contains`", () {
      box.put(TestEntity.initIntegerAndText(1337, "meh"));
      box.put(TestEntity.initIntegerAndText(1,    "bleh"));
      box.put(TestEntity.initIntegerAndText(1337, "bleh"));
      box.put(TestEntity.initIntegerAndText(1337, "blh"));

      final text = TestEntity_.text;
      final number = TestEntity_.number;

      final qs0 = box.query(text.inside([ "meh" ])).build();
      final qs1 = box.query(text.inside([ "bleh" ])).build();
      final qs2 = box.query(text.inside([ "meh", "bleh" ])).build();
      final qs3 = box.query(text.contains("eh")).build();
      final qs4 = box.query(text.contain("bl")).build(); // wtf is the difference?

      final qn0 = box.query(number.inside([ 1 ])).build();
      final qn1 = box.query(number.inside([ 1337 ])).build();
      final qn2 = box.query(number.inside([ 1, 1337 ])).build();

      expect(qs0.count(), 1);
      expect(qs1.count(), 2);
      expect(qs2.count(), 3);
      expect(qs3.count(), 3);
      expect(qs3.count(), 4);
      expect(qn0.count(), 1);
      expect(qn1.count(), 2);
      expect(qn2.count(), 3);

      [ qs0,qs1,qs2,qs3,qs4,qn0,qn1,qn2 ].forEach((q) => q.close());
    });

    test(".findIds returns List<int>", () {
      int idOffset = 1337;
      box.put(TestEntity.initId(idOffset,   "meh"));
      box.put(TestEntity.initId(idOffset++, "bleh"));
      box.put(TestEntity.initId(idOffset++, "bleh"));
      box.put(TestEntity.initId(idOffset++, "helb"));
      box.put(TestEntity.initId(idOffset++, "helb"));
      box.put(TestEntity.initId(idOffset++, "bleh"));
      box.put(TestEntity.initId(idOffset++, "blh"));

      // broken due to unsupported types
      /*
      box.putMany([
        TestEntity.initId(idOffset++, "bleh"),
        TestEntity.initId(idOffset++, "helb"),
        TestEntity.initId(idOffset++, "blh")]);
     */

      final text = TestEntity_.text;

      final q0 = box.query(text.notNull()).build();
      final result0 = q0.findIds();

      final q1 = box.queryAll([text.contains("e"), text.contains("h")]).build();
      final result1 = q1.findIds();

      final q2 = box.query((text == "blh") as QueryCondition).build();
      final result2 = q2.findIds();

      final q3 = box.query((text == "can't find this") as QueryCondition).build();
      final result3 = q3.findIds();

      // (result0 + result1 + result2).forEach((i) => print("found id: ${i}"));

      expect(result0.length, 7); // TODO off by one bug?
      expect(result1.length, 6);
      expect(result2.length, 1);
      expect(result3, null);

      q0.close();
      q1.close();
      q2.close();
      q3.close();
    });

    test(".count items after grouping with and/or", () {
      box.put(TestEntity.initText("Hello"));
      box.put(TestEntity.initText("Goodbye"));
      box.put(TestEntity.initText("World"));

      box.put(TestEntity.initInteger(1337));
      box.put(TestEntity.initInteger(80085));

      box.put(TestEntity.initIntegerAndText(-1337, "meh"));
      box.put(TestEntity.initIntegerAndText(-1332 + -5, "bleh"));
      box.put(TestEntity.initIntegerAndText(1337, "Goodbye"));

      final text = TestEntity_.text;
      final number = TestEntity_.number;

      QueryCondition cond1 = ((text == "Hello") as QueryCondition) | ((number == 1337) as QueryCondition);
      QueryCondition cond2 = text.equals("Hello") | number.equals(1337);
      QueryCondition cond3 = text.equals("What?").and(text.equals("Hello")).or(text.equals("World"));
      QueryCondition cond4 = text.equals("Goodbye").and(number.equals(1337)).or(number.equals(1337)).or(text.equals("Cruel")).or(text.equals("World"));
      QueryCondition cond5 = text.equals("bleh") & number.equals(-1337);
      QueryCondition cond6 = ((text == "Hello") as QueryCondition) & ((number == 1337) as QueryCondition);

      final selfInference1 = (text == "Hello") & (number == 1337);
      final selfInference2 = (text == "Hello") | (number == 1337);
      // QueryCondition cond0 = (text == "Hello") | (number == 1337); // TODO research why broken without the cast

      /*
      // doesn't work
      final anyGroupCondition0 = <QueryCondition>[text == "meh", text == "bleh"];
      final allGroupCondition0 = <QueryCondition>[text == "Goodbye", number == 1337];
      */

      final anyGroupCondition0 = <QueryCondition>[text.equals("meh"), text.equals("bleh")];
      final allGroupCondition0 = <QueryCondition>[text.equals("Goodbye"), number.equals(1337)];


      final queryAny0 = box.queryAny(anyGroupCondition0).build();
      final queryAll0 = box.queryAll(allGroupCondition0).build();

      final q1 = box.query(cond1).build();
      final q2 = box.query(cond2).build();
      final q3 = box.query(cond3).build();
      final q4 = box.query(cond4).build();

      box.query(selfInference1 as QueryCondition);
      box.query(selfInference2 as QueryCondition);

      expect(q1.count(), 3);
      expect(q2.count(), 3);
      expect(q3.count(), 1);
      expect(q4.count(), 3);
      expect(queryAny0.count(), 2);
      expect(queryAll0.count(), 1);

      [ q1, q2, q3, q4, queryAny0, queryAll0 ].forEach((q) => q.close());
    });
  });

  tearDown(tearDownStorage(store, box));
}