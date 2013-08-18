
import static utils.Utils.*;

public class InnerClassTest {

    class TestSuperClass {
        private long privateField;
        protected int protectedField = 13;
        public float publicField;

        private void privateFunction() {
            publicField = protectedField + privateField;
        }
        protected int protectedFunction() {
            privateField = 42;
            return protectedField;
        }
        public boolean publicFunction() {
            protectedFunction();
            privateFunction();
            return true;
        }
    }

    class TestDerivedClass extends TestSuperClass {
        protected int protectedFunction() {
            protectedField = 44;
            return protectedField;
        }
        public boolean publicFunction() {
            super.publicFunction();
            return false;
        }
    }

    public void runTests() {
        TestSuperClass test1 = new TestSuperClass();
        assertEquals(0.0, test1.publicField);
        test1.publicField = 6.0f * 9.0f;
        assertEquals(54.0, test1.publicField);
        assertEquals(true, test1.publicFunction());
        assertEquals(55.0, test1.publicField);

        TestDerivedClass test2 = new TestDerivedClass();
        assertEquals(0.0, test2.publicField);
        test2.publicField = 6.0f * 8.0f;
        assertEquals(48.0, test2.publicField);
        assertEquals(false, test2.publicFunction());
        assertEquals(44.0, test2.publicField);
    }

    public static void main(String[] args) {
        InnerClassTest test = new InnerClassTest();
        test.runTests();
    }
}